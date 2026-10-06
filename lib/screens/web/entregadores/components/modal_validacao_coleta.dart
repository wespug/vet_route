import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vet_route/models/coleta_model.dart';
import 'package:provider/provider.dart';
import 'package:vet_route/controllers/coleta_controller.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vet_route/controllers/core/app_config.dart';

class ModalValidacaoColeta extends StatefulWidget {
  final Coleta item;

  const ModalValidacaoColeta({super.key, required this.item});

  @override
  State createState() => _ModalValidacaoColetaState();
}

class _ModalValidacaoColetaState extends State<ModalValidacaoColeta> {
  int _passoAtual = 1;

  // Dados do Passo 1
  String? _qrCodeLido;
  bool _processandoQR = false;

  // Dados do Passo 2
  File? _fotoProduto;
  String _enderecoFormatado = "";
  Position? _localizacaoFoto;
  DateTime? _dataHoraFoto;
  bool _carregandoCamera = false;

  // =======================================================================
  // LÓGICA DO PASSO 1: LER QR CODE
  // =======================================================================

  // =======================================================================
  // LÓGICA DO PASSO 1: LER QR CODE COM SEGURANÇA
  // =======================================================================
  void _aoLerQrCode(BarcodeCapture capture) {
    if (_processandoQR) return;

    final List barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      setState(() {
        _processandoQR = true;
        _qrCodeLido = barcodes.first.rawValue;
      });

      try {
        final Map qrDados = json.decode(_qrCodeLido!);
        final String qrId = qrDados['id'] ?? '';
        final String qrAcao = qrDados['acao'] ?? '';
        final String qrCodigo = qrDados['codigo'] ?? '';

        final String codigoOriginal = widget.item.codigo.isNotEmpty
            ? widget.item.codigo
            : (widget.item.codigoAcompanhamento ?? widget.item.id);
        final String codigoMotoboy = codigoOriginal.length >= 6
            ? codigoOriginal.substring(0, 6).toUpperCase()
            : codigoOriginal.toUpperCase();

        // 💡 LOGS DE DEBUGGING (O RAIO-X)
        print("=== DEBUG DE VALIDAÇÃO ===");
        print("QR_ID: " + qrId);
        print("QR_CODIGO: " + qrCodigo);
        print("QR_ACAO: " + qrAcao);
        print("--- ESPERADO PELO APP ---");
        print("APP_ID: " + widget.item.id);
        print("APP_CODIGO: " + codigoMotoboy);
        print("==========================");

        if ((qrId == widget.item.id || qrCodigo == codigoMotoboy) &&
            qrAcao == "em_transporte") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("QR Code validado! Liberação autorizada."),
              backgroundColor: Colors.green,
            ),
          );

          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) setState(() => _passoAtual = 2);
          });
        } else {
          _abortarLeituraInvalida("Este QR Code não pertence a este pedido!");
        }
      } catch (e) {
        _abortarLeituraInvalida("QR Code inválido ou danificado.");
      }
    }
  }

  // Função auxiliar para recomeçar o scanner em caso de erro
  void _abortarLeituraInvalida(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.redAccent),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _processandoQR = false);
    });
  }

  // =======================================================================
  // LÓGICA DO PASSO 2: TIRAR FOTO COM DADOS DE GPS E TEMPO
  // =======================================================================
  Future _tirarFoto() async {
    setState(() => _carregandoCamera = true);

    try {
      // 1. Pega a localização exata naquele momento
      _localizacaoFoto = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _dataHoraFoto = DateTime.now();

      if (_localizacaoFoto != null) {
        _enderecoFormatado =
            "Lat: " +
            _localizacaoFoto!.latitude.toStringAsFixed(5) +
            " / Lng: " +
            _localizacaoFoto!.longitude.toStringAsFixed(5);
        _buscarEndereco(
          _localizacaoFoto!.latitude,
          _localizacaoFoto!.longitude,
        );
      }

      // 2. Abre a câmera nativa do dispositivo
      final ImagePicker picker = ImagePicker();
      final XFile? foto = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70, // Reduz o tamanho do arquivo para o Firebase
      );

      if (foto != null) {
        setState(() {
          _fotoProduto = File(foto.path);
        });
      }
    } catch (e) {
      print("Erro ao capturar foto ou localização: $e");
    } finally {
      setState(() => _carregandoCamera = false);
    }
  }

  // =======================================================================
  // FINALIZAR PROCESSO
  // =======================================================================

  // =======================================================================
  // FINALIZAR PROCESSO: SUBIR PARA AS NUVENS
  // =======================================================================
  Future _finalizarColeta() async {
    // 1. Mostrar que estamos trabalhando
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final controller = Provider.of<ColetaController>(context, listen: false);

      // AQUI ENTRA A SUA LOGÍSTICA REAL!
      // Você vai precisar de uma função no seu ColetaController para guardar estes dados,
      // algo parecido com isto (ajuste o nome da função consoante o que tiver lá):

      await controller.confirmarPosseComFoto(
        coletaId: widget.item.id,
        foto: _fotoProduto!, // Enviamos o arquivo físico
        enderecoGeo:
            _enderecoFormatado, // Enviamos o nome da rua que o Google traduziu
      );

      // Por agora, para não quebrar a compilação, usamos o método base que já existe:
      await controller.atualizarStatusColeta(widget.item.id, 'em_transporte');

      // Fecha o "Carregando"
      if (mounted) Navigator.pop(context);

      // Fecha o Modal inteiro e conclui o trabalho
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Coleta validada! Pacote em sua posse."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        Navigator.pop(context); // Fecha o "Carregando" em caso de erro
      print("Erro ao disparar para o Firebase: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao confirmar posse: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future _buscarEndereco(double lat, double lng) async {
    try {
      final url =
          "https://maps.googleapis.com/maps/api/geocode/json?latlng=" +
          lat.toString() +
          "," +
          lng.toString() +
          "&key=" +
          AppConfig.googleMapsApiKey;

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          // Extrai o endereço formatado do Google
          String completo = data['results'][0]['formatted_address'];
          if (mounted) {
            setState(() {
              // Corta o texto para mostrar apenas "Rua e Número" (antes do traço do bairro)
              _enderecoFormatado = completo.split('-')[0].trim();
            });
          }
        }
      }
    } catch (e) {
      print("Erro ao converter coordenadas: " + e.toString());
    }
  }

  // =======================================================================
  // INTERFACE
  // =======================================================================
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 650),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // CABEÇALHO
            Row(
              children: [
                Icon(
                  _passoAtual == 1 ? Icons.qr_code_scanner : Icons.camera_alt,
                  color: Colors.indigo,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _passoAtual == 1
                        ? "Passo 1: Ler QR Code"
                        : "Passo 2: Foto do Produto",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 32),

            // CONTEÚDO DINÂMICO
            Expanded(child: _passoAtual == 1 ? _buildPasso1() : _buildPasso2()),
          ],
        ),
      ),
    );
  }

  Widget _buildPasso1() {
    return Column(
      children: [
        const Text(
          "Aponte a câmera para o QR Code da Clínica ou do Lote de Insumos.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(onDetect: _aoLerQrCode),
                // Mira visual do QR Code
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.greenAccent, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                if (_processandoQR)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.greenAccent,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Botão de pular apenas para testes (remover em produção)
        TextButton(
          onPressed: () => setState(() => _passoAtual = 2),
          child: const Text("Pular (Modo Dev)"),
        ),
      ],
    );
  }

  Widget _buildPasso2() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_fotoProduto == null) ...[
          const Text(
            "Tire uma foto clara do material coletado. A sua localização e horário serão registrados automaticamente.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 32),
          _carregandoCamera
              ? const CircularProgressIndicator()
              : ElevatedButton.icon(
                  onPressed: _tirarFoto,
                  icon: const Icon(Icons.camera_alt, size: 24),
                  label: const Text("Abrir Câmera"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
        ] else ...[
          // EXIBIÇÃO DA FOTO COM MARCA D'ÁGUA VIRTUAL
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(_fotoProduto!, fit: BoxFit.cover),

                  // Carimbo inferior escurecido para legibilidade
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black87],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat(
                              'dd/MM/yyyy HH:mm:ss',
                            ).format(_dataHoraFoto!),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _enderecoFormatado,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _tirarFoto,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refazer"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _finalizarColeta,
                  icon: const Icon(Icons.check),
                  label: const Text("Confirmar Coleta"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
