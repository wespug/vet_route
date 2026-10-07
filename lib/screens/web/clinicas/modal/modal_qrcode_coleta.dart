import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:vet_route/models/item_logistica_model.dart';

class ModalQrCodeColeta extends StatefulWidget {
  final ItemLogisticaModel item;
  final String? nomeEntregador;
  final String
  observacao; // 💡 Injetado para lidar com exames que não têm lista de itens

  const ModalQrCodeColeta({
    super.key,
    required this.item,
    this.nomeEntregador,
    this.observacao = '',
  });

  @override
  State createState() => _ModalQrCodeColetaState();
}

class _ModalQrCodeColetaState extends State<ModalQrCodeColeta> {
  StreamSubscription<DocumentSnapshot>? _ouvinteDeStatus;
  bool _jaFechou = false;

  @override
  void initState() {
    super.initState();
    _escutarPosseDoMotoboy();
  }

  // 💡 Ouve a coleção certa consoante seja Insumo ou Exame
  void _escutarPosseDoMotoboy() {
    final colecao = widget.item.isInsumo
        ? 'pedidos_insumos'
        : 'chamados_coleta';

    _ouvinteDeStatus = FirebaseFirestore.instance
        .collection(colecao)
        .doc(widget.item.id)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
          if (snapshot.exists) {
            final dados = snapshot.data() as Map;
            final String statusAtual = dados['status'] ?? '';

            if (statusAtual.toLowerCase() == 'em_transporte' && !_jaFechou) {
              _jaFechou = true;
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Leitura Validada! O pacote de ${widget.item.laboratorioNome} já está com o motoboy.",
                    ),
                    backgroundColor: Colors.green.shade600,
                    duration: const Duration(seconds: 4),
                  ),
                );
                Navigator.of(context).pop();
              }
            }
          }
        });
  }

  @override
  void dispose() {
    _ouvinteDeStatus?.cancel();
    super.dispose();
  }

  Future _imprimirQrCode(
    String dadosQrCode,
    String data,
    String hora,
    String codigoFormatado,
    List<Map<String, dynamic>> itensProcessados,
  ) async {
    final pdf = pw.Document();
    final entregadorLabel = widget.nomeEntregador ?? 'Não atribuído';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    "AUTORIZAÇÃO DE COLETA / SAÍDA",
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "DESTINO / LABORATÓRIO:",
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          widget.item.laboratorioNome,
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          "ENTREGADOR:",
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          entregadorLabel,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.black, width: 2),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            "PEDIDO",
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                          pw.Text(
                            "#$codigoFormatado",
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.Divider(),
                pw.SizedBox(height: 10),

                pw.Text(
                  "ITENS A SEREM COLETADOS:",
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),

                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(8),
                    ),
                  ),
                  child: pw.Column(
                    children: itensProcessados.map((i) {
                      final qtd =
                          i['quantidade'] ??
                          i['quantidadeSolicitada'] ??
                          i['qtd'] ??
                          1;
                      final nome =
                          i['descricao'] ??
                          i['nomeInsumo'] ??
                          i['nome'] ??
                          'Item';

                      return pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              "$qtd un.",
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            pw.SizedBox(width: 12),
                            pw.Expanded(
                              child: pw.Text(
                                " -  $nome",
                                style: const pw.TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                pw.Spacer(),

                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        "QR CODE DE VALIDAÇÃO DE POSSE",
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: dadosQrCode,
                        width: 150,
                        height: 150,
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        "Gerado em: $data às $hora",
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
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
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Coleta_$codigoFormatado',
    );
  }

  @override
  Widget build(BuildContext context) {
    final agora = DateTime.now();
    final dataFormatada = DateFormat('dd/MM/yyyy').format(agora);
    final horaFormatada = DateFormat('HH:mm').format(agora);

    final String codigoFormatado = widget.item.codigo.length >= 6
        ? widget.item.codigo.substring(0, 6).toUpperCase()
        : widget.item.codigo.toUpperCase();

    final Map mapaQr = {
      'id': widget.item.id,
      'codigo': codigoFormatado,
      'acao': 'em_transporte',
      'data': dataFormatada,
    };

    final String dadosQrCode = jsonEncode(mapaQr);
    final entregadorLabel = widget.nomeEntregador ?? 'Não atribuído';

    // 💡 Resolve o problema de "Exames vs Insumos" na listagem
    final List<Map<String, dynamic>> itensProcessados = widget.item.isInsumo
        ? List<Map<String, dynamic>>.from(widget.item.itensInsumo)
        : [
            {
              'quantidade': 1,
              'descricao': widget.observacao.isNotEmpty
                  ? widget.observacao
                  : 'Materiais para Análise Clínica',
            },
          ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 750),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.inventory_2_rounded,
                  size: 42,
                  color: Colors.indigo,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Liberar Pacote",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.indigo.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "DESTINO",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo.shade300,
                                ),
                              ),
                              Text(
                                widget.item.laboratorioNome,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.indigo,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "#$codigoFormatado",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Icon(
                            Icons.sports_motorsports,
                            size: 18,
                            color: Colors.orange.shade800,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Entregador: ",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            entregadorLabel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: itensProcessados.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 16, color: Colors.black12),
                    itemBuilder: (context, index) {
                      final i = itensProcessados[index];
                      final qtd =
                          i['quantidade'] ??
                          i['quantidadeSolicitada'] ??
                          i['qtd'] ??
                          1;
                      final nome =
                          i['descricao'] ??
                          i['nomeInsumo'] ??
                          i['nome'] ??
                          'Item';

                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "${qtd}x",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              nome,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: QrImageView(
                    data: dadosQrCode,
                    version: QrVersions.auto,
                    size: 240.0,
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _imprimirQrCode(
                          dadosQrCode,
                          dataFormatada,
                          horaFormatada,
                          codigoFormatado,
                          itensProcessados,
                        ),
                        icon: const Icon(Icons.print, size: 18),
                        label: const Text("Imprimir"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.indigo,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Concluir",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
