import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:vet_route/controllers/core/app_config.dart';

import 'package:vet_route/models/coleta_model.dart';
import 'package:vet_route/controllers/coleta_controller.dart';
import 'package:vet_route/screens/web/entregadores/components/modal_detalhes_coleta_motoboy.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ColetaCard extends StatefulWidget {
  final Coleta item;
  final bool isFinalizados;

  const ColetaCard({
    super.key,
    required this.item,
    required this.isFinalizados,
  });

  @override
  State createState() => _ColetaCardState();
}

class _ColetaCardState extends State<ColetaCard> {
  bool _isNavegando = false;
  bool _carregandoMapa = false;

  Position? _posicaoAtual;
  Completer<GoogleMapController> _mapController = Completer();
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  String _tempoViagem = "";
  String _distanciaRota = "";

  Future _iniciarNavegacao() async {
    setState(() => _carregandoMapa = true);

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _mostrarErro("Os serviços de localização estão desativados.");
      setState(() => _carregandoMapa = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _mostrarErro("Permissão de localização negada.");
        setState(() => _carregandoMapa = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _mostrarErro("Permissões de localização permanentemente negadas.");
      setState(() => _carregandoMapa = false);
      return;
    }

    // Captura a posição atual do entregador
    _posicaoAtual = await Geolocator.getCurrentPosition();

    const double destinoLat = -23.56168;
    const double destinoLng = -46.65598;

    // 1º: Ativamos a interface do mapa na tela PRIMEIRO
    setState(() {
      _isNavegando = true;
    });

    // 2º: Traçamos a rota e movemos a câmara
    await _tracarRota(
      PointLatLng(_posicaoAtual!.latitude, _posicaoAtual!.longitude),
      PointLatLng(destinoLat, destinoLng),
    );

    // 3º: Desligamos o loading
    setState(() {
      _carregandoMapa = false;
    });
  }

  Future _tracarRota(PointLatLng origem, PointLatLng destino) async {
    // 1. Chama a API Direta da Google
    final url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=\({origem.latitude},\){origem.longitude}&destination=\({destino.latitude},\){destino.longitude}&mode=driving&key=${AppConfig.googleMapsApiKey}";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final leg = route['legs'][0];

        // 2. Atualiza o Tempo e a Distância
        setState(() {
          _distanciaRota = leg['distance']['text'];
          _tempoViagem = leg['duration']['text'];
        });

        // 3. Decodifica a linha azul da rota
        final pointsString = route['overview_polyline']['points'];
        PolylinePoints polylinePoints = PolylinePoints();
        List resultPoints = polylinePoints.decodePolyline(pointsString);

        List<LatLng> polylineCoordinates = [];

        // Variáveis para calcular os limites da câmara (para focar na rota toda)
        double minLat = origem.latitude;
        double minLng = origem.longitude;
        double maxLat = origem.latitude;
        double maxLng = origem.longitude;

        for (var point in resultPoints) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));

          // Descobre os pontos mais extremos para a câmara
          if (point.latitude < minLat) minLat = point.latitude;
          if (point.latitude > maxLat) maxLat = point.latitude;
          if (point.longitude < minLng) minLng = point.longitude;
          if (point.longitude > maxLng) maxLng = point.longitude;
        }

        setState(() {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId("rota_coleta"),
              color: Colors.blueAccent,
              width: 5,
              points: polylineCoordinates,
            ),
          );

          _markers.add(
            Marker(
              markerId: const MarkerId("origem"),
              position: LatLng(origem.latitude, origem.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
            ),
          );

          _markers.add(
            Marker(
              markerId: const MarkerId("destino"),
              position: LatLng(destino.latitude, destino.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          );
        });

        // 4. Move e afasta a câmara para mostrar a rota completa!
        final controller = await _mapController.future;
        controller.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(minLat, minLng),
              northeast: LatLng(maxLat, maxLng),
            ),
            50.0, // Margem de 50 pixels para a linha não colar nas bordas
          ),
        );
      }
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    // A lógica de cores e dados originais foi mantida
    String horaFormatada = '--:--';
    bool isFuturo = false;

    if (widget.item.dataCriacao != null) {
      final data = widget.item.dataCriacao!;
      final agora = DateTime.now();
      final hoje = DateTime(agora.year, agora.month, agora.day);
      final dataItem = DateTime(data.year, data.month, data.day);

      isFuturo = dataItem.isAfter(hoje);

      if (data.hour == 0 && data.minute == 0) {
        horaFormatada = 'A definir';
      } else {
        horaFormatada =
            data.hour.toString().padLeft(2, '0') +
            ':' +
            data.minute.toString().padLeft(2, '0');
      }
    }

    final bool isInsumo = widget.item.isInsumo;
    final bool isUrgencia = widget.item.isEmergencia;

    Color corTema;
    Color corFundoTema;
    if (isInsumo) {
      corTema = Colors.teal;
      corFundoTema = Colors.teal.shade50;
    } else if (isUrgencia) {
      corTema = Colors.redAccent.shade700;
      corFundoTema = Colors.red.shade50;
    } else {
      corTema = Colors.indigo;
      corFundoTema = Colors.indigo.shade50;
    }

    final String statusNorm = widget.item.status.toLowerCase();
    final bool isRecusado =
        statusNorm.contains('recusad') || statusNorm.contains('cancel');

    final String localOrigem = widget.item.origemVisual;
    final String enderecoOrigem = widget.item.enderecoOrigemVisual;
    final String localDestino = widget.item.destinoVisual;
    final String enderecoDestino = widget.item.enderecoDestinoVisual;

    final String codigoOriginal = widget.item.codigo.isNotEmpty
        ? widget.item.codigo
        : (widget.item.codigoAcompanhamento ?? widget.item.id);
    final String codigoFormatado = codigoOriginal.length >= 6
        ? codigoOriginal.substring(0, 6).toUpperCase()
        : codigoOriginal.toUpperCase();

    String rodapeTexto =
        (isInsumo
            ? 'Pedido de Insumo'
            : (isUrgencia ? 'Coleta de Urgência' : 'Coleta de Exame')) +
        ' • ID: #' +
        codigoFormatado;

    Color corBadge = corTema;
    Color corFundoBadge = corFundoTema;
    String statusTexto = 'Nova Parada';

    if (isRecusado) {
      corBadge = const Color(0xFFE53935);
      corFundoBadge = const Color(0xFFFFEBEE);
      statusTexto = 'Recusada / Cancelada';
    } else if (widget.isFinalizados) {
      corBadge = const Color(0xFF43A047);
      corFundoBadge = const Color(0xFFE8F5E9);
      statusTexto = 'Concluída';
    } else if (isFuturo) {
      corBadge = Colors.deepPurple;
      corFundoBadge = Colors.deepPurple.shade50;
      statusTexto = 'Agendado';
    } else if (statusNorm.contains('rota') || statusNorm.contains('caminho')) {
      corBadge = Colors.orange.shade800;
      corFundoBadge = Colors.orange.shade50;
      statusTexto = 'Em Rota';
    }

    return Opacity(
      opacity: widget.isFinalizados ? 0.65 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isFinalizados
                ? Colors.grey.shade200
                : corTema.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: widget.isFinalizados
              ? []
              : [
                  BoxShadow(
                    color: corTema.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: _isNavegando
            ? _buildMapaNavegacao(corTema)
            : _buildDetalhesOriginais(
                corTema,
                corFundoTema,
                corBadge,
                corFundoBadge,
                statusTexto,
                horaFormatada,
                localOrigem,
                enderecoOrigem,
                localDestino,
                enderecoDestino,
                rodapeTexto,
                isInsumo,
                isUrgencia,
                isRecusado,
                isFuturo,
              ),
      ),
    );
  }

  // Interface do Mapa (Ativada ao clicar em Iniciar Rota)
  Widget _buildMapaNavegacao(Color corTema) {
    return Column(
      children: [
        SizedBox(
          height:
              300, // Aumentei um pouco a altura para ficar melhor de navegar
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
            ),
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _posicaoAtual!.latitude,
                      _posicaoAtual!.longitude,
                    ),
                    zoom: 14.5,
                  ),
                  polylines: _polylines,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomGesturesEnabled: true, // Garante que pode dar zoom
                  scrollGesturesEnabled:
                      true, // Garante que pode arrastar o mapa
                  onMapCreated: (GoogleMapController controller) {
                    if (!_mapController.isCompleted) {
                      _mapController.complete(controller);
                    }
                  },
                ),

                // Cartão flutuante de Tempo e Distância
                if (_tempoViagem.isNotEmpty)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 8),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.timer_outlined, color: corTema),
                              const SizedBox(width: 8),
                              Text(
                                _tempoViagem,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 1,
                            height: 20,
                            color: Colors.grey.shade300,
                          ),
                          Row(
                            children: [
                              Icon(Icons.route_outlined, color: corTema),
                              const SizedBox(width: 8),
                              Text(
                                _distanciaRota,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Lógica para finalizar coleta
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text("Finalizar Parada"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: corTema,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isNavegando = false;
                    _mapController =
                        Completer(); // Prepara um novo mapa para a próxima vez
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                ),
                child: const Icon(Icons.close, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Interface Original do Card separada numa função
  Widget _buildDetalhesOriginais(
    Color corTema,
    Color corFundoTema,
    Color corBadge,
    Color corFundoBadge,
    String statusTexto,
    String horaFormatada,
    String localOrigem,
    String enderecoOrigem,
    String localDestino,
    String enderecoDestino,
    String rodapeTexto,
    bool isInsumo,
    bool isUrgencia,
    bool isRecusado,
    bool isFuturo,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: corFundoBadge,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusTexto.toUpperCase(),
                  style: TextStyle(
                    color: corBadge,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    horaFormatada,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF2F2F7), thickness: 1.5),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Icon(Icons.radio_button_checked, color: corTema, size: 18),
                  Container(
                    width: 2,
                    height: 28,
                    color: Colors.grey.shade200,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  const Icon(
                    Icons.location_on,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Coletar em:",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      localOrigem,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      enderecoOrigem,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Entregar em",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      localDestino,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      enderecoDestino,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: corFundoTema,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          isInsumo
                              ? Icons.inventory_2_rounded
                              : (isUrgencia
                                    ? Icons.flash_on_rounded
                                    : Icons.vaccines_rounded),
                          size: 16,
                          color: corTema,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            rodapeTexto,
                            style: TextStyle(
                              color: corTema.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => ModalDetalhesColetaMotoboy(
                          item: widget.item,
                          isInsumo: isInsumo,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        "Ver Detalhes",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: corTema,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (!widget.isFinalizados) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () => _confirmarRecusa(context, widget.item),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.redAccent.shade200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Recusar",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: isFuturo
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.calendar_month_rounded,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Aguardando Data",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _carregandoMapa
                                  ? null
                                  : _iniciarNavegacao,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: corTema,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _carregandoMapa
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "Iniciar Rota",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                            ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _confirmarRecusa(BuildContext context, Coleta item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Recusar Parada",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          "Tem certeza que deseja recusar esta parada? Ela voltará para a fila de atribuição do laboratório.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancelar",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final controller = Provider.of<ColetaController>(
                context,
                listen: false,
              );
              await controller.recusarColeta(item.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Sim, Recusar"),
          ),
        ],
      ),
    );
  }
}
