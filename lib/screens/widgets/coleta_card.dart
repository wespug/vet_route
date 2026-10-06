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
import 'package:vet_route/screens/web/entregadores/components/modal_validacao_coleta.dart';

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
  bool _rotaCalculada = false;
  bool _carregandoMapa = false;
  bool _mostrarMapa = false;
  LatLngBounds? _limitesRota;
  double _minLat = 90.0;
  double _maxLat = -90.0;
  double _minLng = 180.0;
  double _maxLng = -180.0;

  Position? _posicaoAtual;
  Completer<GoogleMapController> _mapController = Completer();
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  String _tempoViagem = "";
  String _distanciaRota = "";

  // ====================================================================
  // FUNÇÃO 1: INICIA A ROTA DUPLA
  // ====================================================================
  Future _iniciarNavegacao() async {
    setState(() => _carregandoMapa = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _mostrarErro("Os serviços de localização estão desativados.");
      setState(() => _carregandoMapa = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _mostrarErro("Permissão de localização negada.");
        setState(() => _carregandoMapa = false);
        return;
      }
    }

    // Pega a posição do motoboy
    _posicaoAtual = await Geolocator.getCurrentPosition();
    setState(() => _rotaCalculada = true);

    // Reseta o zoom e as linhas do mapa
    _minLat = 90.0;
    _maxLat = -90.0;
    _minLng = 180.0;
    _maxLng = -180.0;
    _polylines.clear();
    _markers.clear();

    // 1. Pega as coordenadas da Clínica
    PointLatLng? coordClinica = await _obterCoordenadas(
      widget.item.enderecoOrigemVisual,
      widget.item.latitudeOrigem,
      widget.item.longitudeOrigem,
      isOrigem: true,
    );

    // 2. Pega as coordenadas do Laboratório
    PointLatLng? coordLab = await _obterCoordenadas(
      widget.item.enderecoDestinoVisual,
      widget.item.latitudeDestino, // Se o model não tiver isso, passe 'null'
      widget.item.longitudeDestino, // Se o model não tiver isso, passe 'null'
      isOrigem: false,
    );

    if (coordClinica != null) {
      // ROTA 1: MOTOBOY -> CLÍNICA (AZUL CLARO)
      await _tracarRota(
        origem: PointLatLng(_posicaoAtual!.latitude, _posicaoAtual!.longitude),
        destino: coordClinica,
        rotaId: "rota_motoboy_clinica",
        corRota: Colors.blueAccent,
        idMarkerDestino: "marker_clinica",
        hueMarker: BitmapDescriptor.hueBlue,
        isPrimeiraRota: true, // Salva o tempo e distância na tela
      );

      if (coordLab != null) {
        // ROTA 2: CLÍNICA -> LABORATÓRIO (ROXA)
        await _tracarRota(
          origem: coordClinica,
          destino: coordLab,
          rotaId: "rota_clinica_lab",
          corRota: Colors.deepPurpleAccent,
          idMarkerDestino: "marker_lab",
          hueMarker:
              BitmapDescriptor.hueRed, // Pino vermelho no laboratório final
          isPrimeiraRota: false,
        );
      }

      // 3. Aplica o Zoom Total englobando Motoboy, Clínica e Lab
      _limitesRota = LatLngBounds(
        southwest: LatLng(_minLat, _minLng),
        northeast: LatLng(_maxLat, _maxLng),
      );

      if (_mapController.isCompleted) {
        final controller = await _mapController.future;
        controller.animateCamera(
          CameraUpdate.newLatLngBounds(_limitesRota!, 30.0),
        );
      }
    }

    setState(() => _carregandoMapa = false);
  }

  // ====================================================================
  // FUNÇÃO 2: HELPER DE GEOCODING (Converte Endereço em Coordenada)
  // ====================================================================
  Future _obterCoordenadas(
    String endereco,
    double? latSalva,
    double? lngSalva, {
    required bool isOrigem,
  }) async {
    // Se já estiver salvo no banco, devolve direto!
    if (latSalva != null && lngSalva != null) {
      return PointLatLng(latSalva, lngSalva);
    }

    // Se não, pede à Google (com concatenação segura sem $)
    final String urlGeocode =
        "https://maps.googleapis.com/maps/api/geocode/json?address=" +
        Uri.encodeComponent(endereco) +
        "&key=" +
        AppConfig.googleMapsApiKey;

    try {
      final response = await http.get(Uri.parse(urlGeocode));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final loc = data['results'][0]['geometry']['location'];
          double lat = (loc['lat'] as num).toDouble();
          double lng = (loc['lng'] as num).toDouble();

          // Se for a origem, salva no banco para usar de cache na próxima vez
          if (isOrigem) {
            try {
              final controller = Provider.of<ColetaController>(
                context,
                listen: false,
              );
              await controller.atualizarCoordenadasOrigem(
                widget.item.id,
                lat,
                lng,
              );
            } catch (e) {
              print("Erro ao salvar origem no cache: $e");
            }
          }
          return PointLatLng(lat, lng);
        }
      }
    } catch (e) {
      print("Erro no Geocoding: $e");
    }
    return null;
  }

  // ====================================================================
  // FUNÇÃO 3: O DESENHISTA DE LINHAS DINÂMICAS
  // ====================================================================
  Future _tracarRota({
    required PointLatLng origem,
    required PointLatLng destino,
    required String rotaId,
    required Color corRota,
    required String idMarkerDestino,
    required double hueMarker,
    required bool isPrimeiraRota,
  }) async {
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

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          // Guarda o tempo e distância apenas do trajeto imediato (Motoboy -> Clínica)
          if (isPrimeiraRota) {
            setState(() {
              _distanciaRota = leg['distance']['text'];
              _tempoViagem = leg['duration']['text'];
            });
          }

          final pointsString = route['overview_polyline']['points'];
          PolylinePoints polylinePoints = PolylinePoints();
          List resultPoints = polylinePoints.decodePolyline(pointsString);
          List polylineCoordinates = [];

          // Adiciona os pontos da linha e atualiza o Zoom Global
          for (var point in resultPoints) {
            polylineCoordinates.add(LatLng(point.latitude, point.longitude));
            if (point.latitude < _minLat) _minLat = point.latitude;
            if (point.latitude > _maxLat) _maxLat = point.latitude;
            if (point.longitude < _minLng) _minLng = point.longitude;
            if (point.longitude > _maxLng) _maxLng = point.longitude;
          }

          setState(() {
            _polylines.add(
              Polyline(
                polylineId: PolylineId(rotaId),
                color: corRota,
                width: 5,
                points: List.from(polylineCoordinates),
              ),
            );

            // Coloca o pino apenas no destino de cada perna
            // (O motoboy já tem a bolinha azul nativa)
            _markers.add(
              Marker(
                markerId: MarkerId(idMarkerDestino),
                position: LatLng(destino.latitude, destino.longitude),
                icon: BitmapDescriptor.defaultMarkerWithHue(hueMarker),
              ),
            );
          });
        }
      }
    } catch (e) {
      print("Erro ao tentar buscar a rota \(rotaId:\)e");
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
    // 1. Atualiza o status em segundo plano com segurança total
    try {
      final String statusNorm = widget.item.status.toLowerCase();
      final bool isEmRota =
          statusNorm.contains('rota') ||
          statusNorm.contains('caminho') ||
          statusNorm.contains('coletar');

      if (!isEmRota) {
        final controller = Provider.of<ColetaController>(
          context,
          listen: false,
        );
        controller.atualizarStatusColeta(widget.item.id, 'coletar_produto');
      }
    } catch (e) {
      print("Aviso: Erro ignorado ao atualizar status pelo botão Navegar: $e");
    }

    // 2. MÁGICA: Usa a nossa função inteligente para garantir a coordenada
    // (Mesmo que o Firebase ainda não tenha devolvido a atualização para a tela)
    PointLatLng? coordClinica = await _obterCoordenadas(
      widget.item.enderecoOrigemVisual,
      widget.item.latitudeOrigem,
      widget.item.longitudeOrigem,
      isOrigem: true,
    );

    if (coordClinica == null) {
      _mostrarErro("Não foi possível obter as coordenadas para navegação.");
      return;
    }

    final double lat = coordClinica.latitude;
    final double lng = coordClinica.longitude;

    // 3. Monta os Links Universais de Navegação (Concatenados com segurança)
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

    // 4. Trava de segurança para abrir o Modal
    if (!mounted) return;

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
                ),
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
                ),
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

  // ====================================================================
  // 2. O NOVO BUILD (Mais limpo, delegando a construção das partes)
  // ====================================================================
  @override
  Widget build(BuildContext context) {
    String dataHoraFormatada = '--/-- --:--';
    bool isFuturo = false;

    if (widget.item.dataCriacao != null) {
      final data = widget.item.dataCriacao!;
      final agora = DateTime.now();
      final hoje = DateTime(agora.year, agora.month, agora.day);
      final dataItem = DateTime(data.year, data.month, data.day);

      isFuturo = dataItem.isAfter(hoje);

      final diaMes =
          data.day.toString().padLeft(2, '0') +
          '/' +
          data.month.toString().padLeft(2, '0');

      if (data.hour == 0 && data.minute == 0) {
        dataHoraFormatada = diaMes + ' - A definir';
      } else {
        dataHoraFormatada =
            diaMes +
            ' às ' +
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

    // 💡 ID FORMATADO: Agora extraído cedo para enviarmos ao Cabeçalho
    final String codigoOriginal = widget.item.codigo.isNotEmpty
        ? widget.item.codigo
        : (widget.item.codigoAcompanhamento ?? widget.item.id);
    final String codigoFormatado = codigoOriginal.length >= 6
        ? codigoOriginal.substring(0, 6).toUpperCase()
        : codigoOriginal.toUpperCase();

    // 💡 RODAPÉ LIMPO: O ID já não está espremido aqui em baixo
    String rodapeTexto = isInsumo
        ? 'Pedido de Insumo'
        : (isUrgencia ? 'Coleta de Urgência' : 'Coleta de Exame');

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
    } else if (statusNorm == 'em_transporte') {
      corBadge = Colors.green.shade800;
      corFundoBadge = Colors.green.shade50;
      statusTexto = 'Em Transporte';
    } else if (statusNorm.contains('rota') || statusNorm.contains('caminho')) {
      corBadge = Colors.orange.shade800;
      corFundoBadge = Colors.orange.shade50;
      statusTexto = 'Em Rota';
    } else if (statusNorm.contains('rota') ||
        statusNorm.contains('caminho') ||
        statusNorm.contains('coletar')) {
      corBadge = Colors.orange.shade800;
      corFundoBadge = Colors.orange.shade50;
      statusTexto = 'Coletar Produto';
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
        child: _buildLayoutUnificado(
          corTema,
          corFundoTema,
          corBadge,
          corFundoBadge,
          statusTexto,
          dataHoraFormatada,
          rodapeTexto,
          codigoFormatado,
          isInsumo,
          isUrgencia,
          isRecusado,
          isFuturo,
        ),
      ),
    );
  }

  // ====================================================================
  // 3. LAYOUT UNIFICADO (Cabeçalho Redesenhado)
  // ====================================================================
  Widget _buildLayoutUnificado(
    Color corTema,
    Color corFundoTema,
    Color corBadge,
    Color corFundoBadge,
    String statusTexto,
    String dataHoraFormatada,
    String rodapeTexto,
    String codigoFormatado,
    bool isInsumo,
    bool isUrgencia,
    bool isRecusado,
    bool isFuturo,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CABEÇALHO PODEROSO: ID Gigante + Data + Status
        Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ID EM DESTAQUE GIGANTE
                  Expanded(
                    child: Text(
                      "#$codigoFormatado",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  // DATA E HORA
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dataHoraFormatada,
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
              const SizedBox(height: 10),
              // BADGE DE STATUS NA SEGUNDA LINHA
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
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF2F2F7), thickness: 1.5),

        // MIOLO DINÂMICO: MAPA OU TEXTO (Continua a funcionar perfeitamente)
        Padding(
          padding: const EdgeInsets.all(16),
          child: _mostrarMapa
              ? _buildVisorMapa(corTema)
              : _buildVisorTextos(corTema),
        ),

        // RODAPÉ COM DETALHES E BOTÕES
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

                widget.item.status == 'em_transporte'
                    ? SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "ENTREGAR PRODUTO",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            print("Abrir fluxo de entrega final");
                          },
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: OutlinedButton(
                              onPressed: () =>
                                  _confirmarRecusa(context, widget.item),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.redAccent.shade200,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                : _buildBotaoAcaoPrincipal(corTema),
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
                  // Força o iOS a recriar o mapa limpo
                  key: UniqueKey(),

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
                        : const LatLng(-23.56168, -46.65598),
                    zoom: 14.5,
                  ),
                  polylines: Set.from(_polylines),
                  markers: Set.from(_markers),
                  myLocationEnabled: true,

                  onMapCreated: (GoogleMapController controller) {
                    // 1. MÁGICA 1: Destrói o controlador velho e usa o novo!
                    if (_mapController.isCompleted) {
                      _mapController = Completer();
                    }
                    _mapController.complete(controller);

                    // 2. MÁGICA 2: Puxa o zoom de volta para a rota inteira!
                    if (_limitesRota != null) {
                      Future.delayed(const Duration(milliseconds: 400), () {
                        controller.animateCamera(
                          CameraUpdate.newLatLngBounds(_limitesRota!, 20.0),
                        );
                      });
                    }
                  },
                ),

                if (_tempoViagem.isNotEmpty)
                  Positioned(
                    bottom: 12, // Move para a base do mapa
                    left: 12, // Move para a esquerda
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
              if (!_rotaCalculada) _iniciarNavegacao();
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
    final String statusNorm = widget.item.status.toLowerCase();
    final bool isEmRota =
        statusNorm.contains('rota') ||
        statusNorm.contains('caminho') ||
        statusNorm.contains('coletar');

    if (isEmRota) {
      return ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => ModalValidacaoColeta(item: widget.item),
          );
        },
        icon: const Icon(Icons.qr_code_scanner, size: 18),
        label: const Text(
          "Coletar Produto",
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
          : () async {
              setState(() => _mostrarMapa = true);

              // 1. AVISAR O FIREBASE IMEDIATAMENTE (COM A TIPAGEM CORRETA)
              try {
                final controller = Provider.of<ColetaController>(
                  context,
                  listen: false,
                );
                // Removemos o await para não travar a tela enquanto o banco processa
                controller.atualizarStatusColeta(
                  widget.item.id,
                  'coletar_produto',
                );
              } catch (e) {
                print("Erro ao atualizar status: $e");
              }

              // 2. DESENHAR A ROTA NO MAPA COM CALMA
              if (!_rotaCalculada) {
                await _iniciarNavegacao();
              }
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
