import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:vet_route/models/item_logistica_model.dart';

class ModalAcompanhamentoRota extends StatefulWidget {
  final ItemLogisticaModel item;
  final Color corTema;

  const ModalAcompanhamentoRota({
    super.key,
    required this.item,
    required this.corTema,
  });

  @override
  State<ModalAcompanhamentoRota> createState() =>
      _ModalAcompanhamentoRotaState();
}

class _ModalAcompanhamentoRotaState extends State<ModalAcompanhamentoRota> {
  GoogleMapController? mapController;

  // 💡 Coordenadas Base (Futuramente substitua pelas reais)
  final LatLng _origem = const LatLng(-23.550520, -46.633308);
  final LatLng _destino = const LatLng(-23.553950, -46.651260);
  final LatLng _motoboy = const LatLng(-23.552000, -46.640000);

  @override
  Widget build(BuildContext context) {
    final codExibicao = widget.item.codigo.length > 6
        ? widget.item.codigo.substring(0, 6).toUpperCase()
        : widget.item.codigo.toUpperCase();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header do Modal
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Acompanhamento",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Pedido #$codExibicao",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    CupertinoIcons.xmark_circle_fill,
                    size: 28,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Google Map
          SizedBox(
            height: 250,
            width: double.infinity,
            child: GoogleMap(
              onMapCreated: (controller) => mapController = controller,
              initialCameraPosition: CameraPosition(target: _motoboy, zoom: 14),
              zoomControlsEnabled: false,
              markers: {
                Marker(
                  markerId: const MarkerId('origem'),
                  position: _origem,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ),
                  infoWindow: const InfoWindow(title: 'Origem'),
                ),
                Marker(
                  markerId: const MarkerId('destino'),
                  position: _destino,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
                  infoWindow: const InfoWindow(title: 'Destino'),
                ),
                Marker(
                  markerId: const MarkerId('motoboy'),
                  position: _motoboy,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueOrange,
                  ),
                  infoWindow: const InfoWindow(title: 'Entregador em Rota'),
                ),
              },
              polylines: {
                Polyline(
                  polylineId: const PolylineId('rota_estimada'),
                  points: [_origem, _destino],
                  color: widget.corTema,
                  width: 4,
                  patterns: [PatternItem.dash(20), PatternItem.gap(10)],
                ),
              },
            ),
          ),

          // Log de Auditoria Replicado
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(
                    widget.item.isInsumo
                        ? 'pedidos_insumos'
                        : 'chamados_coleta',
                  )
                  .doc(widget.item.id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CupertinoActivityIndicator());
                }

                final data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data == null) {
                  return const Center(child: Text("Dados não encontrados."));
                }

                // 💡 Resolve a falha do log vazio buscando nas duas chaves possíveis
                final List<dynamic> historicoRaw =
                    data['historico'] ?? data['historicoLogs'] ?? [];

                final logs = List<Map<String, dynamic>>.from(
                  historicoRaw.map((e) => Map<String, dynamic>.from(e)),
                );

                // 💡 Ordenação cronológica garantida
                logs.sort((a, b) {
                  final dateA = a['data'] != null
                      ? (a['data'] as dynamic).toDate()
                      : DateTime.now();
                  final dateB = b['data'] != null
                      ? (b['data'] as dynamic).toDate()
                      : DateTime.now();
                  return dateA.compareTo(dateB);
                });

                final formatadorData = DateFormat('dd/MM/yyyy HH:mm');

                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Log de Auditoria",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: logs.isEmpty
                            ? const Text(
                                "Nenhum log registrado.",
                                style: TextStyle(color: Colors.grey),
                              )
                            : ListView.builder(
                                itemCount: logs.length,
                                itemBuilder: (context, index) {
                                  final log = logs[index];
                                  final dateLog = log['data'] != null
                                      ? (log['data'] as dynamic).toDate()
                                      : DateTime.now();

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.radio_button_checked,
                                          size: 16,
                                          color: widget.corTema,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    (log['status'] ?? '')
                                                        .toString()
                                                        .toUpperCase(),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  Text(
                                                    formatadorData.format(
                                                      dateLog,
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.grey.shade500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                "Por: ${log['usuario'] ?? 'Sistema'}",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              if (log['observacao'] != null &&
                                                  log['observacao']
                                                      .toString()
                                                      .isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 4.0,
                                                      ),
                                                  child: Text(
                                                    "Obs: ${log['observacao']}",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      color:
                                                          Colors.grey.shade700,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
