import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:vet_route/models/pedido_insumo_model.dart';
import 'dart:convert';

class ModalQrCodeEntrega extends StatefulWidget {
  final PedidoInsumoModel pedido;
  final String? nomeEntregador;

  const ModalQrCodeEntrega({
    super.key,
    required this.pedido,
    this.nomeEntregador,
  });

  @override
  State createState() => _ModalQrCodeEntregaState();
}

class _ModalQrCodeEntregaState extends State<ModalQrCodeEntrega> {
  StreamSubscription<DocumentSnapshot>? _ouvinteDeStatus;
  bool _jaFechou = false; // 💡 A TRAVA DE SEGURANÇA CONTRA A TELA BRANCA

  @override
  void initState() {
    super.initState();
    _escutarPosseDoMotoboy();
  }

  // A MAGIA: Ouve o Firebase em tempo real
  void _escutarPosseDoMotoboy() {
    _ouvinteDeStatus = FirebaseFirestore.instance
        .collection('pedidos_insumos')
        .doc(widget.pedido.id)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
          if (snapshot.exists) {
            final dados = snapshot.data() as Map;
            final String statusAtual = dados['status'] ?? '';

            // 💡 Se o status mudou E a tela ainda não foi fechada...
            if (statusAtual.toLowerCase() == 'em_transporte' && !_jaFechou) {
              _jaFechou =
                  true; // Tranca a porta! Impede o segundo Navigator.pop()

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Leitura Validada! O pacote de ${widget.pedido.clinicaNome} já está na posse do motoboy.",
                    ),
                    backgroundColor: Colors.green.shade600,
                    duration: const Duration(seconds: 4),
                  ),
                );
                // Fecha a janela na cara do laboratório com segurança
                Navigator.of(context).pop();
              }
            }
          }
        });
  }

  @override
  void dispose() {
    _ouvinteDeStatus?.cancel(); // Limpa o escutador ao fechar
    super.dispose();
  }

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
                          widget.pedido.clinicaNome,
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

                // 💡 NOVO: Tabela elegante para os itens no PDF
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(8),
                    ),
                  ),
                  child: pw.Column(
                    children: widget.pedido.itens.map((item) {
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
                      // 💡 CORRIGIDO: Injetando as variáveis de data e hora reais
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

  // ===========================================================================
  // INTERFACE VISUAL (TELA)
  // ===========================================================================
  // ===========================================================================
  // INTERFACE VISUAL (TELA)
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final agora = DateTime.now();
    final dataFormatada = DateFormat('dd/MM/yyyy').format(agora);
    final horaFormatada = DateFormat('HH:mm').format(agora);

    final String codigoFormatado = widget.pedido.codigo.length >= 6
        ? widget.pedido.codigo.substring(0, 6).toUpperCase()
        : widget.pedido.codigo.toUpperCase();

    // 💡 Agora enviamos também a variável 'codigo' no JSON
    final Map mapaQr = {
      'id': widget.pedido.id,
      'codigo': codigoFormatado,
      'acao': 'em_transporte',
      'data': dataFormatada,
    };

    final String dadosQrCode = jsonEncode(mapaQr);

    final entregadorLabel = widget.nomeEntregador ?? 'Não atribuído';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 750,
        ), // Evita que cresça infinitamente
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            // 💡 A SOLUÇÃO MÁGICA: Permite fazer scroll se faltar espaço!
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
                                widget.pedido.clinicaNome,
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

                // 💡 NOVA LISTA DE ITENS NA TELA
                Container(
                  height: 130, // Um pouco mais de espaço
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50, // Fundo subtil
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: widget.pedido.itens.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 16, color: Colors.black12),
                    itemBuilder: (context, index) {
                      final item = widget.pedido.itens[index];
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
                    size: 240.0, // Reduzi um bocadinho para caber melhor
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
        ),
      ),
    );
  }
}
