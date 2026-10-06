import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:vet_route/models/pedido_insumo_model.dart'; // Ajuste o caminho se necessário

class ModalQrCodeEntrega extends StatelessWidget {
  final PedidoInsumoModel pedido;
  final String? nomeEntregador;

  const ModalQrCodeEntrega({
    super.key,
    required this.pedido,
    this.nomeEntregador,
  });

  // ===========================================================================
  // GERADOR DE PDF PROFISSIONAL (ORDEM DE COLETA)
  // ===========================================================================
  Future _imprimirQrCode(
    String dadosQrCode,
    String data,
    String hora,
    String codigoFormatado,
  ) async {
    final pdf = pw.Document();
    final entregadorLabel = nomeEntregador ?? 'Não atribuído';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // CABEÇALHO DO PDF
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

                // INFORMAÇÕES PRINCIPAIS EM DESTAQUE
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "DESTINO / CLÍNICA:",
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          pedido.clinicaNome,
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

                // LISTA DE ITENS NO PDF
                pw.Text(
                  "ITENS A SEREM COLETADOS:",
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                ...pedido.itens.map((item) {
                  final qtd =
                      item['quantidade'] ??
                      item['quantidadeSolicitada'] ??
                      item['qtd'] ??
                      0;
                  final nome =
                      item['descricao'] ??
                      item['nomeInsumo'] ??
                      item['nome'] ??
                      'Insumo';
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Text(
                      "• \(qtd un. -\)nome",
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),

                pw.Spacer(),

                // QR CODE NO RODAPÉ DO PDF
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
                        "Gerado em: \(data às\)hora",
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

  // ===========================================================================
  // INTERFACE VISUAL (TELA)
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final agora = DateTime.now();
    final dataFormatada = DateFormat('dd/MM/yyyy').format(agora);
    final horaFormatada = DateFormat('HH:mm').format(agora);

    final String codigoFormatado = pedido.codigo.length >= 6
        ? pedido.codigo.substring(0, 6).toUpperCase()
        : pedido.codigo.toUpperCase();

    // 💡 Agora enviamos também a variável 'codigo' no JSON
    final dadosQrCode =
        '{"id": "' +
        pedido.id +
        '", "codigo": "' +
        codigoFormatado +
        '", "acao": "em_transporte", "data": "' +
        dataFormatada +
        '"}';

    final entregadorLabel = nomeEntregador ?? 'Não atribuído';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Container(
        width: 500, // Um pouco mais largo para acomodar os dados
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // CABEÇALHO
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

            // CAIXA DE DESTAQUE COM OS DADOS LOGÍSTICOS
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
                            pedido.clinicaNome,
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

            // LISTA ROLÁVEL DE ITENS
            Container(
              height:
                  100, // Altura fixa para não quebrar a tela se houver muitos itens
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: pedido.itens.length,
                separatorBuilder: (context, index) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final item = pedido.itens[index];
                  final qtd =
                      item['quantidade'] ??
                      item['quantidadeSolicitada'] ??
                      item['qtd'] ??
                      0;
                  final nome =
                      item['descricao'] ??
                      item['nomeInsumo'] ??
                      item['nome'] ??
                      'Insumo';

                  return Row(
                    children: [
                      Text(
                        "${qtd}x",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          nome,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // O GERADOR DE QR CODE
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
                size: 260.0,
              ),
            ),

            const SizedBox(height: 24),

            // BOTÕES DE AÇÃO
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _imprimirQrCode(
                      dadosQrCode,
                      dataFormatada,
                      horaFormatada,
                      codigoFormatado,
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
    );
  }
}
