import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:vet_route/controllers/core/app_config.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _mostrarMapa = false;

  Position? _posicaoAtual;
  Completer<GoogleMapController> _mapController = Completer();
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  String _tempoViagem = "";
  String _distanciaRota = "";

  Future<void> _iniciarNavegacao() async {
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
      _mostrarErro("Permissões permanentemente negadas.");
      setState(() => _carregandoMapa = false);
      return;
    }

    // 1. Captura a posição atual do entregador (Ponto A)
    _posicaoAtual = await Geolocator.getCurrentPosition();

    // 2. Verifica se o banco já tem as coordenadas salvas
    double? latColeta = widget.item.latitudeOrigem;
    double? lngColeta = widget.item.longitudeOrigem;

    if (latColeta != null && lngColeta != null) {
      // TEM NO BANCO: Usa direto e economiza a chamada de API!
      setState(() => _isNavegando = true);

      await _tracarRota(
        PointLatLng(_posicaoAtual!.latitude, _posicaoAtual!.longitude),
        PointLatLng(latColeta, lngColeta),
      );
    } else {
      // NÃO TEM NO BANCO: Faz Geocoding, salva e usa.
      final String enderecoTexto = widget.item.enderecoOrigemVisual;

      // 1. Adicione este log para ver o endereço puro:
      print("=== DEBUG GEOCODING ===");
      print("Endereço puro: $enderecoTexto");

      final String urlGeocode =
          "https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(enderecoTexto)}&key=${AppConfig.googleMapsApiKey}";

      try {
        final responseGeo = await http.get(Uri.parse(urlGeocode));
        if (responseGeo.statusCode == 200) {
          final dataGeo = json.decode(responseGeo.body);

          print("Resposta da Google: ${responseGeo.body}");

          if (dataGeo['status'] == 'OK' && dataGeo['results'].isNotEmpty) {
            final location = dataGeo['results'][0]['geometry']['location'];
            latColeta = (location['lat'] as num).toDouble();
            lngColeta = (location['lng'] as num).toDouble();

            // Chama o Controller para salvar no Firestore de vez!
            final controller = Provider.of<ColetaController>(
              context,
              listen: false,
            );
            await controller.atualizarCoordenadasOrigem(
              widget.item.id,
              latColeta!,
              lngColeta!,
            );

            setState(() => _isNavegando = true);

            await _tracarRota(
              PointLatLng(_posicaoAtual!.latitude, _posicaoAtual!.longitude),
              PointLatLng(latColeta!, lngColeta!),
            );
          } else {
            _mostrarErro("Não foi possível encontrar o endereço no mapa.");
          }
        }
      } catch (e) {
        _mostrarErro("Erro ao buscar endereço: $e");
      }
    }

    // Desliga o loading
    setState(() => _carregandoMapa = false);
  }

  Future<void> _tracarRota(PointLatLng origem, PointLatLng destino) async {
    print("=== DEBUG ROTA ===");

    // Concatenação blindada sem o uso do cifrão ($)
    final url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=" +
        origem.latitude.toString() +
        "," +
        origem.longitude.toString() +
        "&destination=" +
        destino.latitude.toString() +
        "," +
        destino.longitude.toString() +
        "&mode=driving&key=" +
        AppConfig.googleMapsApiKey;

    print(
      "URL Directions montada.",
    ); // Não imprimo a URL toda para não poluir, mas sabemos que está concatenada.

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Status da Resposta Google Directions: " + data['status']);

        if (data['status'] != 'OK') {
          print(
            "Mensagem de erro da Google: " +
                (data['error_message'] ?? "Sem detalhes"),
          );
          return;
        }

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          setState(() {
            _distanciaRota = leg['distance']['text'];
            _tempoViagem = leg['duration']['text'];
          });

          final pointsString = route['overview_polyline']['points'];
          PolylinePoints polylinePoints = PolylinePoints();
          List<PointLatLng> resultPoints = polylinePoints.decodePolyline(
            pointsString,
          );

          List<LatLng> polylineCoordinates = [];

          double minLat = origem.latitude;
          double minLng = origem.longitude;
          double maxLat = origem.latitude;
          double maxLng = origem.longitude;

          for (var point in resultPoints) {
            polylineCoordinates.add(LatLng(point.latitude, point.longitude));
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

          // Move a câmara
          if (_mapController.isCompleted) {
            final controller = await _mapController.future;
            controller.animateCamera(
              CameraUpdate.newLatLngBounds(
                LatLngBounds(
                  southwest: LatLng(minLat, minLng),
                  northeast: LatLng(maxLat, maxLng),
                ),
                50.0,
              ),
            );
          }
          print("=== ROTA DESENHADA COM SUCESSO ===");
        }
      }
    } catch (e) {
      print("Erro ao tentar buscar a rota: $e");
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  // ====================================================================
  // 1. FUNÇÃO DO MODO NAVEGAÇÃO (Prepara o terreno para o Waze/Maps)
  // ====================================================================
  Future _abrirModoNavegacao() async {
    // Pega as coordenadas da Clínica (Origem da coleta)
    final double? lat = widget.item.latitudeOrigem;
    final double? lng = widget.item.longitudeOrigem;

    if (lat == null || lng == null) {
      _mostrarErro(
        "Coordenadas não calculadas. Clique em 'Iniciar Rota' primeiro.",
      );
      return;
    }

    // Links Universais (Funcionam no iPhone e no Android, abrindo o app nativo se instalado)
    final Uri urlGoogleMaps = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=" +
          lat.toString() +
          "," +
          lng.toString() +
          "&travelmode=driving",
    );
    final Uri urlWaze = Uri.parse(
      "https://waze.com/ul?ll=" +
          lat.toString() +
          "," +
          lng.toString() +
          "&navigate=yes",
    );

    // Mostra as opções para o motoboy escolher
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "Como deseja navegar?",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              ListTile(
                leading: Image.network(
                  "https://cdn-icons-png.flaticon.com/512/2875/2875331.png",
                  width: 32,
                ), // Ícone do G Maps
                title: const Text(
                  "Google Maps",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await launchUrl(
                    urlGoogleMaps,
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Image.network(
                  "https://cdn-icons-png.flaticon.com/512/732/732288.png",
                  width: 32,
                ), // Ícone do Waze
                title: const Text(
                  "Waze",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await launchUrl(
                    urlWaze,
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ====================================================================
  // 2. O NOVO BUILD (Mais limpo, delegando a construção das partes)
  // ====================================================================
  @override
  Widget build(BuildContext context) {
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

    Color corTema = isInsumo
        ? Colors.teal
        : (isUrgencia ? Colors.redAccent.shade700 : Colors.indigo);
    Color corFundoTema = isInsumo
        ? Colors.teal.shade50
        : (isUrgencia ? Colors.red.shade50 : Colors.indigo.shade50);

    final String statusNorm = widget.item.status.toLowerCase();
    final bool isRecusado =
        statusNorm.contains('recusad') || statusNorm.contains('cancel');

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
        // Aqui removemos aquele if completo do _isNavegando e usamos o layout unificado
        child: _buildLayoutUnificado(
          corTema,
          corFundoTema,
          corBadge,
          corFundoBadge,
          statusTexto,
          horaFormatada,
          rodapeTexto,
          isInsumo,
          isUrgencia,
          isRecusado,
          isFuturo,
        ),
      ),
    );
  }

  // ====================================================================
  // 3. LAYOUT UNIFICADO (Cabeçalho, Miolo Dinâmico e Rodapé)
  // ====================================================================
  Widget _buildLayoutUnificado(
    Color corTema,
    Color corFundoTema,
    Color corBadge,
    Color corFundoBadge,
    String statusTexto,
    String horaFormatada,
    String rodapeTexto,
    bool isInsumo,
    bool isUrgencia,
    bool isRecusado,
    bool isFuturo,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CABEÇALHO (Status e Hora)
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

        // MIOLO DINÂMICO: AQUI ACONTECE A TROCA ENTRE TEXTO E MAPA!
        Padding(
          padding: const EdgeInsets.all(16),
          child: _mostrarMapa
              ? _buildVisorMapa(corTema)
              : _buildVisorTextos(corTema),
        ),

        // RODAPÉ (Insumo/Detalhes e Botões de Ação)
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
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => ModalDetalhesColetaMotoboy(
                        item: widget.item,
                        isInsumo: isInsumo,
                      ),
                    ),
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
                          : _buildBotaoAcaoPrincipal(
                              corTema,
                            ), // Botão inteligente
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

  // ====================================================================
  // 4. WIDGETS AUXILIARES E BOTÕES INTELIGENTES
  // ====================================================================
  Widget _buildVisorMapa(Color corTema) {
    return Column(
      children: [
        SizedBox(
          height: 220, // Altura perfeita para não quebrar a lista
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                GoogleMap(
                  // Travas estáticas
                  scrollGesturesEnabled: false,
                  zoomGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: false,
                  initialCameraPosition: CameraPosition(
                    target: _posicaoAtual != null
                        ? LatLng(
                            _posicaoAtual!.latitude,
                            _posicaoAtual!.longitude,
                          )
                        : const LatLng(
                            -23.56168,
                            -46.65598,
                          ), // Proteção contra crash
                    zoom: 14.5,
                  ),
                  polylines: _polylines,
                  markers: _markers,
                  myLocationEnabled: true,
                  onMapCreated: (GoogleMapController controller) {
                    if (!_mapController.isCompleted) {
                      _mapController.complete(controller);
                    }
                  },
                ),
                if (_tempoViagem.isNotEmpty)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),

                      child: Text(
                        _tempoViagem + " • " + _distanciaRota,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: corTema,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                if (_carregandoMapa)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _mostrarMapa = false),
              icon: const Icon(Icons.list, color: Colors.grey),
              label: const Text(
                "Ver Endereços",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _abrirModoNavegacao,
              icon: const Icon(Icons.navigation, size: 18),
              label: const Text("Navegar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: corTema,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVisorTextos(Color corTema) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                    widget.item.origemVisual,
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
                    widget.item.enderecoOrigemVisual,
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
                    widget.item.destinoVisual,
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
                    widget.item.enderecoDestinoVisual,
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
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() => _mostrarMapa = true);
              if (!_isNavegando) _iniciarNavegacao();
            },
            icon: Icon(Icons.map, color: corTema),
            label: const Text("Ver Rota no Mapa"),
          ),
        ),
      ],
    );
  }

  // O botão altera a sua função dependendo de já estarmos em rota ou não
  Widget _buildBotaoAcaoPrincipal(Color corTema) {
    if (_isNavegando) {
      return ElevatedButton.icon(
        onPressed: () {
          // A SUA LÓGICA DE FINALIZAR PARADA ENTRA AQUI!
          print("Finalizando parada no banco...");
        },
        icon: const Icon(Icons.check_circle_outline, size: 18),
        label: const Text(
          "Finalizar Parada",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    return ElevatedButton(
      onPressed: _carregandoMapa
          ? null
          : () {
              setState(() => _mostrarMapa = true);
              _iniciarNavegacao();
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: corTema,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
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
              final controller = Provider.of(context, listen: false);
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
