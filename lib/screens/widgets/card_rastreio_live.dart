import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:vet_route/controllers/core/app_config.dart';

class CardRastreioLive extends StatefulWidget {
  final String entregadorId;
  final String enderecoOrigem;
  final String enderecoDestino;
  final double? latOrigem;
  final double? lngOrigem;
  final double? latDestino;
  final double? lngDestino;
  final String status;

  const CardRastreioLive({
    super.key,
    required this.entregadorId,
    required this.enderecoOrigem,
    required this.enderecoDestino,
    this.latOrigem,
    this.lngOrigem,
    this.latDestino,
    this.lngDestino,
    required this.status,
  });

  @override
  State<CardRastreioLive> createState() => _CardRastreioLiveState();
}

class _CardRastreioLiveState extends State<CardRastreioLive> {
  final Completer<GoogleMapController> _mapController = Completer();
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  LatLng? _posicaoMotoboy;
  LatLng? _posicaoOrigem;
  LatLng? _posicaoDestino;

  BitmapDescriptor? _iconeOrigem;
  BitmapDescriptor? _iconeDestino;
  BitmapDescriptor? _iconeMotoboy;

  String _tempoEstimado = "A aguardar satélite...";
  String _distanciaRestante = "";
  bool _carregando = true;
  bool _rotaDesenhada = false;

  StreamSubscription? _gpsSubscription;

  @override
  void initState() {
    super.initState();
    _inicializarMapaEIcones();
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    super.dispose();
  }

  // =========================================================================
  // 🎨 ÍCONES ELEGANTES E DISCRETOS
  // =========================================================================
  Future<BitmapDescriptor> _criarPinoPersonalizado(
    IconData iconData,
    Color corFundo,
  ) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // 💡 Reduzido de 110.0 para 64.0 para ficar com um tamanho premium e delicado
    const double size = 64.0;

    // Sombra mais discreta
    canvas.drawCircle(
      const Offset(size / 2, size / 2 + 3),
      size / 2.2,
      Paint()..color = Colors.black26,
    );

    // Fundo
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2.2,
      Paint()..color = corFundo,
    );

    // Borda fina (3.0 em vez de 6.0)
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2.2,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    // Ícone proporcional
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size / 1.9,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size / 2 - textPainter.width / 2,
        size / 2 - textPainter.height / 2,
      ),
    );

    final img = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt() + 6,
    );
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  Future<void> _inicializarMapaEIcones() async {
    _iconeOrigem = await _criarPinoPersonalizado(
      Icons.storefront_rounded,
      Colors.indigo.shade400,
    );
    _iconeDestino = await _criarPinoPersonalizado(
      Icons.science_rounded,
      Colors.teal.shade500,
    );
    _iconeMotoboy = await _criarPinoPersonalizado(
      Icons.two_wheeler_rounded,
      Colors.blue.shade600,
    );

    if (widget.latOrigem != null && widget.latOrigem != 0.0) {
      _posicaoOrigem = LatLng(widget.latOrigem!, widget.lngOrigem!);
    } else {
      _posicaoOrigem = await _obterCoordenadas(widget.enderecoOrigem, "Origem");
    }

    if (widget.latDestino != null && widget.latDestino != 0.0) {
      _posicaoDestino = LatLng(widget.latDestino!, widget.lngDestino!);
    } else {
      _posicaoDestino = await _obterCoordenadas(
        widget.enderecoDestino,
        "Destino",
      );
    }

    if (_posicaoOrigem == null && _posicaoDestino == null) {
      if (mounted)
        setState(() {
          _tempoEstimado = "Endereço inválido";
          _distanciaRestante = "";
        });
    }

    _desenharPinosFixos();

    if (_posicaoOrigem != null && _posicaoDestino != null) {
      await _tracarRotaBase(_posicaoOrigem!, _posicaoDestino!);
    }

    _escutarGpsMotoboy();
  }

  void _desenharPinosFixos() {
    if (!mounted) return;
    setState(() {
      if (_posicaoOrigem != null && _iconeOrigem != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('origem'),
            position: _posicaoOrigem!,
            icon: _iconeOrigem!,
            zIndex: 1,
            infoWindow: const InfoWindow(title: 'Origem da Coleta'),
          ),
        );
      }
      if (_posicaoDestino != null && _iconeDestino != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('destino'),
            position: _posicaoDestino!,
            icon: _iconeDestino!,
            zIndex: 1,
            infoWindow: const InfoWindow(title: 'Destino Local'),
          ),
        );
      }
    });
  }

  Future<LatLng?> _obterCoordenadas(String endereco, String rotuloLog) async {
    if (endereco.isEmpty ||
        endereco.toLowerCase().contains('não disponível') ||
        endereco.toLowerCase().contains('incompleto'))
      return null;
    final url =
        "https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(endereco)}&key=${AppConfig.googleMapsApiKey}";
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final loc = data['results'][0]['geometry']['location'];
          return LatLng(loc['lat'], loc['lng']);
        }
      }
    } catch (e) {
      debugPrint("Erro Geocode: $e");
    }
    return null;
  }

  Future<void> _tracarRotaBase(LatLng origem, LatLng destino) async {
    final urlGoogle =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${origem.latitude},${origem.longitude}&destination=${destino.latitude},${destino.longitude}&mode=driving&key=${AppConfig.googleMapsApiKey}";
    try {
      final res = await http.get(Uri.parse(urlGoogle));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          _desenharLinhaPendente(
            data['routes'][0]['overview_polyline']['points'],
          );
          return;
        }
      }
      throw Exception("CORS/Google");
    } catch (e) {
      await _tracarRotaBaseOSRM(origem, destino);
    }
  }

  Future<void> _tracarRotaBaseOSRM(LatLng origem, LatLng destino) async {
    final urlOSRM =
        "https://router.project-osrm.org/route/v1/driving/${origem.longitude},${origem.latitude};${destino.longitude},${destino.latitude}?overview=full&geometries=polyline";
    try {
      final res = await http.get(Uri.parse(urlOSRM));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          _desenharLinhaPendente(data['routes'][0]['geometry']);
          return;
        }
      }
      throw Exception("OSRM Falhou");
    } catch (e) {
      _desenharLinhaPendenteFallback(origem, destino);
    }
  }

  void _desenharLinhaPendente(String polylineEncoded) {
    List<PointLatLng> result = PolylinePoints().decodePolyline(polylineEncoded);
    List<LatLng> polylineCoords = result
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();
    if (mounted) {
      setState(() {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('rota_base_completa'),
            color: Colors.indigo.withOpacity(0.35),
            width: 4,
            patterns: [PatternItem.dot, PatternItem.gap(8)],
            points: polylineCoords,
            zIndex: 0,
          ),
        );
      });
    }
  }

  void _desenharLinhaPendenteFallback(LatLng origem, LatLng destino) {
    if (mounted) {
      setState(() {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('rota_base_completa'),
            color: Colors.indigo.withOpacity(0.35),
            width: 4,
            patterns: [PatternItem.dot, PatternItem.gap(8)],
            points: [origem, destino],
            zIndex: 0,
          ),
        );
      });
    }
  }

  void _escutarGpsMotoboy() {
    _gpsSubscription = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.entregadorId)
        .snapshots()
        .listen((doc) async {
          if (doc.exists && doc.data()!.containsKey('latitudeAtual')) {
            final data = doc.data()!;
            final novaPosicao = LatLng(
              data['latitudeAtual'],
              data['longitudeAtual'],
            );

            if (mounted) {
              setState(() {
                _posicaoMotoboy = novaPosicao;
                _carregando = false;
                _markers.removeWhere((m) => m.markerId.value == 'motoboy');
                _markers.add(
                  Marker(
                    markerId: const MarkerId('motoboy'),
                    position: novaPosicao,
                    icon:
                        _iconeMotoboy ??
                        BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueBlue,
                        ),
                    zIndex: 10,
                  ),
                );
              });
            }

            if (!_rotaDesenhada) {
              _rotaDesenhada = true;
              final bool isIndoColetar =
                  widget.status.toLowerCase().contains('indo') ||
                  widget.status.toLowerCase().contains('aguardando') ||
                  widget.status.toLowerCase().contains('coletar');
              final LatLng? alvo = isIndoColetar
                  ? _posicaoOrigem
                  : _posicaoDestino;

              if (alvo != null) {
                await _tracarRotaAtiva(novaPosicao, alvo);
                _ajustarCamera(novaPosicao, alvo);
              } else {
                if (_mapController.isCompleted) {
                  final controller = await _mapController.future;
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(novaPosicao, 16),
                  );
                }
                if (mounted && _tempoEstimado.contains("calcular")) {
                  setState(() {
                    _tempoEstimado = "Destino GPS indisponível";
                    _distanciaRestante = "";
                  });
                }
              }
            } else {
              final bool isIndoColetar =
                  widget.status.toLowerCase().contains('indo') ||
                  widget.status.toLowerCase().contains('aguardando') ||
                  widget.status.toLowerCase().contains('coletar');
              final LatLng? alvo = isIndoColetar
                  ? _posicaoOrigem
                  : _posicaoDestino;

              if (alvo != null) {
                await _tracarRotaAtiva(novaPosicao, alvo);
              }

              if (_mapController.isCompleted) {
                final controller = await _mapController.future;
                controller.animateCamera(CameraUpdate.newLatLng(novaPosicao));
              }
            }
          } else {
            if (mounted)
              setState(() {
                _carregando = false;
                _tempoEstimado = "Sinal GPS Ausente";
                _distanciaRestante = "";
              });
          }
        });
  }

  Future<void> _tracarRotaAtiva(LatLng origem, LatLng destino) async {
    final urlGoogle =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${origem.latitude},${origem.longitude}&destination=${destino.latitude},${destino.longitude}&mode=driving&key=${AppConfig.googleMapsApiKey}";
    try {
      final res = await http.get(Uri.parse(urlGoogle));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final leg = data['routes'][0]['legs'][0];
          final pointsString = data['routes'][0]['overview_polyline']['points'];
          _desenharLinhaAtiva(
            pointsString,
            leg['duration']['text'],
            leg['distance']['text'],
          );
          return;
        }
      }
      throw Exception("CORS Ativa");
    } catch (e) {
      await _tracarRotaAtivaOSRM(origem, destino);
    }
  }

  Future<void> _tracarRotaAtivaOSRM(LatLng origem, LatLng destino) async {
    final urlOSRM =
        "https://router.project-osrm.org/route/v1/driving/${origem.longitude},${origem.latitude};${destino.longitude},${destino.latitude}?overview=full&geometries=polyline";
    try {
      final res = await http.get(Uri.parse(urlOSRM));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          double distanciaMeters = route['distance'];
          double duracaoSegundos = route['duration'];

          int minutos = (duracaoSegundos / 60).ceil();
          if (minutos < 1) minutos = 1;

          double distKm = distanciaMeters / 1000;
          String distStr = distKm < 1.0
              ? "${(distKm * 1000).toInt()} m"
              : "${distKm.toStringAsFixed(1)} km";
          String tempStr = "~$minutos min";

          _desenharLinhaAtiva(route['geometry'], tempStr, distStr);
          return;
        }
      }
      throw Exception("OSRM Ativa Falhou");
    } catch (e) {
      _atualizarRotaAtivaFallback(origem, destino);
    }
  }

  void _desenharLinhaAtiva(
    String polylineEncoded,
    String tempoTxt,
    String distTxt,
  ) {
    List<PointLatLng> result = PolylinePoints().decodePolyline(polylineEncoded);
    List<LatLng> polylineCoords = result
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    if (mounted) {
      setState(() {
        _tempoEstimado = tempoTxt;
        _distanciaRestante = distTxt;
        _polylines.removeWhere(
          (p) => p.polylineId.value == 'rota_ativa_motoboy',
        );
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('rota_ativa_motoboy'),
            color: Colors.blue.shade600,
            width: 5,
            points: polylineCoords,
            zIndex: 5,
          ),
        );
      });
    }
  }

  void _atualizarRotaAtivaFallback(LatLng origem, LatLng destino) {
    double distanceKm = _calcularDistanciaEmKm(
      origem.latitude,
      origem.longitude,
      destino.latitude,
      destino.longitude,
    );
    int minutos = ((distanceKm / 35.0) * 60).ceil();
    if (minutos < 1) minutos = 1;

    if (mounted) {
      setState(() {
        _tempoEstimado = "~$minutos min";
        _distanciaRestante = distanceKm < 1.0
            ? "${(distanceKm * 1000).toInt()} m"
            : "${distanceKm.toStringAsFixed(1)} km";
        _polylines.removeWhere(
          (p) => p.polylineId.value == 'rota_ativa_motoboy',
        );
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('rota_ativa_motoboy'),
            color: Colors.blue.shade600,
            width: 5,
            points: [origem, destino],
            zIndex: 5,
          ),
        );
      });
    }
  }

  double _calcularDistanciaEmKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    var p = 0.017453292519943295;
    var c = cos;
    var a =
        0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  Future<void> _ajustarCamera(LatLng p1, LatLng p2) async {
    if (!_mapController.isCompleted) return;
    double minLat = p1.latitude <= p2.latitude ? p1.latitude : p2.latitude;
    double maxLat = p1.latitude > p2.latitude ? p1.latitude : p2.latitude;
    double minLng = p1.longitude <= p2.longitude ? p1.longitude : p2.longitude;
    double maxLng = p1.longitude > p2.longitude ? p1.longitude : p2.longitude;

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    try {
      final controller = await _mapController.future;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted)
          controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
      });
    } catch (e) {
      debugPrint("Ajuste de câmara abortado.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.radar_rounded,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Rastreio em Tempo Real",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                ],
              ),
              if (_rotaDesenhada)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    "Motoboy a caminho",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _carregando
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.indigo.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "A comunicar com o GPS...",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        GoogleMap(
                          key: UniqueKey(),
                          initialCameraPosition: CameraPosition(
                            target:
                                _posicaoMotoboy ??
                                const LatLng(-23.5505, -46.6333),
                            zoom: 16,
                          ),
                          markers: _markers,
                          polylines: _polylines,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          myLocationButtonEnabled: false,
                          onMapCreated: (GoogleMapController controller) {
                            if (!_mapController.isCompleted) {
                              _mapController.complete(controller);
                            }
                          },
                        ),
                        if (_rotaDesenhada && _distanciaRestante.isNotEmpty)
                          Positioned(
                            bottom: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.two_wheeler_rounded,
                                    size: 18,
                                    color: Colors.indigo.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "$_tempoEstimado • $_distanciaRestante",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.indigo.shade900,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
