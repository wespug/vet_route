import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vet_route/models/item_logistica_model.dart';
import 'modal_acompanhamento_rota.dart';

class ItemCardColetaMobile extends StatefulWidget {
  final ItemLogisticaModel item;

  const ItemCardColetaMobile({super.key, required this.item});

  @override
  State<ItemCardColetaMobile> createState() => _ItemCardColetaMobileState();
}

class _ItemCardColetaMobileState extends State<ItemCardColetaMobile> {
  bool _processandoCamera = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final dataFormatada = DateFormat('dd/MM/yyyy').format(item.dataCriacao);
    final horaFormatada = DateFormat('HH:mm').format(item.dataCriacao);
    final dataHoraExibicao = "$dataFormatada às $horaFormatada";

    final isEmergencia = item.nomeTipoFormatado.toLowerCase().contains('urg');

    Color corTema;
    String tituloPrincipal;
    IconData iconeTipo;

    if (item.isInsumo) {
      corTema = Colors.teal;
      tituloPrincipal = "Pedido de Insumo";
      iconeTipo = CupertinoIcons.cube_box_fill;
    } else if (isEmergencia) {
      corTema = Colors.redAccent.shade700;
      tituloPrincipal = "Coleta de Urgência";
      iconeTipo = CupertinoIcons.bolt_fill;
    } else {
      corTema = Colors.indigo;
      tituloPrincipal = "Coleta Agendada";
      iconeTipo = CupertinoIcons.calendar_circle_fill;
    }

    final statusNorm = item.status.toLowerCase();
    final isAguardando =
        statusNorm.contains('aguardando') || statusNorm.contains('pendente');
    final isIndoColetar =
        statusNorm.contains('indo_coletar') ||
        statusNorm.contains('indo coletar');
    final isEmRota =
        statusNorm.contains('rota') || statusNorm.contains('caminho');
    final isEncerrado = [
      'entregue',
      'concluído',
      'concluido',
      'recusado',
      'cancelado',
    ].contains(statusNorm);

    Color corStatus;
    if (isAguardando || isIndoColetar) {
      corStatus = Colors.orange.shade700;
    } else if (isEmRota) {
      corStatus = Colors.blue.shade600;
    } else if (isEncerrado) {
      corStatus = Colors.grey.shade600;
      corTema = Colors.grey.shade600;
    } else {
      corStatus = corTema;
    }

    final codExibicao = item.codigo.length > 6
        ? item.codigo.substring(0, 6).toUpperCase()
        : item.codigo.toUpperCase();

    String statusExibicao = item.status.replaceAll('_', ' ').toLowerCase();
    statusExibicao = statusExibicao
        .split(' ')
        .map(
          (str) => str.isNotEmpty
              ? '${str[0].toUpperCase()}${str.substring(1)}'
              : '',
        )
        .join(' ');

    final String nomeLaboratorio = item.laboratorioNome.isNotEmpty
        ? item.laboratorioNome
        : 'Laboratório';
    final String origem = item.isInsumo ? nomeLaboratorio : 'Sua Clínica';
    final String destino = item.isInsumo ? 'Sua Clínica' : nomeLaboratorio;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconeTipo, color: corTema, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tituloPrincipal,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: corTema,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTag(statusExibicao, corStatus),
              Text(
                "#$codExibicao",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: Colors.grey.shade200),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const SizedBox(height: 4),
                  Icon(Icons.circle, size: 10, color: Colors.grey.shade400),
                  Container(
                    height: 24,
                    width: 2,
                    color: Colors.grey.shade200,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  Icon(Icons.location_on_rounded, size: 14, color: corTema),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      origem,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      destino,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.calendar,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  dataHoraExibicao,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection(
                  item.isInsumo ? 'pedidos_insumos' : 'chamados_coleta',
                )
                .doc(item.id)
                .snapshots(),
            builder: (context, snapshot) {
              bool temEntregador = false;
              String? nomeEntregador;
              bool isTerceiro = false;
              String placa = '';

              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                nomeEntregador = data['nomeEntregador']?.toString();
                isTerceiro = data['isTransporteExterno'] ?? false;
                placa =
                    data['placa']?.toString() ??
                    data['placaExterna']?.toString() ??
                    '';

                temEntregador =
                    nomeEntregador != null &&
                    nomeEntregador.isNotEmpty &&
                    !nomeEntregador.toLowerCase().contains('aguardando');
              }

              final bool exibirBotaoEntregar =
                  !item.isInsumo &&
                  (isAguardando || isIndoColetar) &&
                  temEntregador;
              final bool exibirBotaoReceber = item.isInsumo && isEmRota;
              final bool exibirBotaoAcompanhar = isEmRota;

              if (!temEntregador &&
                  !exibirBotaoEntregar &&
                  !exibirBotaoReceber &&
                  !exibirBotaoAcompanhar) {
                return const SizedBox.shrink();
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 16),
                    child: Divider(height: 1, color: Colors.grey.shade200),
                  ),
                  if (temEntregador)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isTerceiro
                            ? Colors.purple.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isTerceiro
                              ? Colors.purple.shade200
                              : Colors.orange.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isTerceiro
                                  ? Colors.purple.shade100
                                  : Colors.orange.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isTerceiro
                                  ? Icons.local_shipping_rounded
                                  : Icons.sports_motorsports_rounded,
                              size: 20,
                              color: isTerceiro
                                  ? Colors.purple.shade700
                                  : Colors.orange.shade800,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isTerceiro
                                      ? "SERVIÇO TERCEIRIZADO"
                                      : "MOTOBOY VET ROUTE",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: isTerceiro
                                        ? Colors.purple.shade700
                                        : Colors.orange.shade900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  nomeEntregador ?? '',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (placa.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                placa.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (exibirBotaoEntregar ||
                      exibirBotaoReceber ||
                      exibirBotaoAcompanhar)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        children: [
                          if (exibirBotaoEntregar)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _processandoCamera
                                    ? null
                                    : () {
                                        if (isEmergencia || isIndoColetar) {
                                          _fotografarEAtualizarColeta(
                                            context,
                                            item,
                                          );
                                        } else {
                                          _mostrarPopupQrCode(context, item);
                                        }
                                      },
                                icon:
                                    _processandoCamera &&
                                        (isEmergencia || isIndoColetar)
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        (isEmergencia || isIndoColetar)
                                            ? CupertinoIcons.camera_viewfinder
                                            : CupertinoIcons.qrcode_viewfinder,
                                        size: 18,
                                      ),
                                label: const Text(
                                  "Entregar Material",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isEmergencia
                                      ? Colors.redAccent.shade700
                                      : Colors.indigo,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            )
                          else if (exibirBotaoReceber)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _mostrarPopupCameraRecebimento(
                                  context,
                                  item,
                                ),
                                icon: const Icon(
                                  CupertinoIcons.camera_viewfinder,
                                  size: 18,
                                ),
                                label: const Text(
                                  "Receber Insumos",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          if (exibirBotaoAcompanhar)
                            Padding(
                              padding: EdgeInsets.only(
                                top: (exibirBotaoEntregar || exibirBotaoReceber)
                                    ? 12
                                    : 0,
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _abrirModalAcompanhamento(
                                    context,
                                    item,
                                    corTema,
                                  ),
                                  icon: const Icon(
                                    CupertinoIcons.map_pin_ellipse,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    "Acompanhar Rota e Status",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withOpacity(0.2)),
      ),
      child: Text(
        texto.toUpperCase(),
        style: TextStyle(
          color: cor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // 💡 CÂMERA BLINDADA: Tenta a câmera, se falhar ou se o simulador bugar, abre a galeria. Atualiza log.
  Future<void> _fotografarEAtualizarColeta(
    BuildContext context,
    ItemLogisticaModel item,
  ) async {
    setState(() => _processandoCamera = true);

    try {
      final ImagePicker picker = ImagePicker();
      XFile? foto;

      try {
        foto = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 70,
        );
      } catch (e) {
        // Fallback 1: Erro explícito ao abrir a câmera (Comum no Android Studio)
        foto = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 70,
        );
      }

      // Fallback 2: Câmera fechou sem erro mas retornou null (Comum no iOS Simulator)
      if (foto == null) {
        foto = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 70,
        );
      }

      if (foto != null) {
        await FirebaseFirestore.instance
            .collection('chamados_coleta')
            .doc(item.id)
            .update({
              'status': 'em_rota',
              'dataAtualizacao': FieldValue.serverTimestamp(),
              'historico': FieldValue.arrayUnion([
                {
                  'status': 'EM_ROTA',
                  'data': DateTime.now().toIso8601String(),
                  'usuario': 'Clínica',
                  'observacao': 'Despacho validado via registro fotográfico.',
                },
              ]),
            });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Material despachado! Status alterado para Em Rota.",
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao acessar a mídia: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processandoCamera = false);
      }
    }
  }

  void _mostrarPopupQrCode(BuildContext context, ItemLogisticaModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(CupertinoIcons.qrcode, color: Colors.indigo, size: 28),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Leitura de Entrega",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              icon: const Icon(
                CupertinoIcons.xmark,
                size: 20,
                color: Colors.grey,
              ),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chamados_coleta')
                .doc(item.id)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: CupertinoActivityIndicator());
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final observacao = data['observacao']?.toString() ?? '';

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Apresente este QR Code ao motoboy",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.qr_code_2,
                            size: 160,
                            color: Colors.black87,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "ID: #${item.codigo.toUpperCase()}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.indigo,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Material a ser Entregue:",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        observacao.isNotEmpty
                            ? observacao
                            : "Nenhuma descrição detalhada informada.",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () =>
                            _atualizarStatusEmRota(context, ctx, item),
                        icon: const Icon(
                          CupertinoIcons.qrcode_viewfinder,
                          size: 20,
                        ),
                        label: const Text(
                          "Simular Leitura (Bipar)",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _mostrarPopupCameraRecebimento(
    BuildContext context,
    ItemLogisticaModel item,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(CupertinoIcons.camera, color: Colors.teal, size: 28),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Leitura de Recebimento",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              icon: const Icon(
                CupertinoIcons.xmark,
                size: 20,
                color: Colors.grey,
              ),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Aponte a câmera para o QR Code no celular do entregador para confirmar o recebimento.",
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.teal.withOpacity(0.5),
                    width: 3,
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.camera_viewfinder,
                        color: Colors.white54,
                        size: 48,
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Câmera Simulada...",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('pedidos_insumos')
                          .doc(item.id)
                          .update({
                            'status': 'ENTREGUE',
                            'dataAtualizacao': FieldValue.serverTimestamp(),
                            'historico': FieldValue.arrayUnion([
                              {
                                'status': 'ENTREGUE',
                                'data': DateTime.now().toIso8601String(),
                                'usuario': 'Clínica',
                                'observacao':
                                    'Material entregue e recebido na clínica.',
                              },
                            ]),
                          });

                      if (context.mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Insumos Recebidos com Sucesso!"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Erro: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(
                    CupertinoIcons.checkmark_seal_fill,
                    size: 20,
                  ),
                  label: const Text(
                    "Simular Conclusão (Receber)",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _atualizarStatusEmRota(
    BuildContext context,
    BuildContext dialogContext,
    ItemLogisticaModel item,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('chamados_coleta')
          .doc(item.id)
          .update({
            'status': 'em_rota',
            'dataAtualizacao': FieldValue.serverTimestamp(),
            'historico': FieldValue.arrayUnion([
              {
                'status': 'EM_ROTA',
                'data': DateTime.now().toIso8601String(),
                'usuario': 'Clínica',
                'observacao': 'Despacho validado via QR Code / Sistema.',
              },
            ]),
          });

      if (context.mounted) {
        Navigator.of(dialogContext).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Material despachado! Status alterado para Em Rota."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _abrirModalAcompanhamento(
    BuildContext context,
    ItemLogisticaModel item,
    Color corTema,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          ModalAcompanhamentoRota(item: item, corTema: corTema),
    );
  }
}
