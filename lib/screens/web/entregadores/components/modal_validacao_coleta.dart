import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vet_route/controllers/entregador_controller.dart';
import 'package:vet_route/models/coleta_model.dart';
import 'package:provider/provider.dart';
import 'package:vet_route/controllers/coleta_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vet_route/controllers/core/app_config.dart';

class ModalValidacaoColeta extends StatefulWidget {
  final Coleta item;

  const ModalValidacaoColeta({super.key, required this.item});

  @override
  State<ModalValidacaoColeta> createState() => _ModalValidacaoColetaState();
}

class _ModalValidacaoColetaState extends State<ModalValidacaoColeta> {
  int _passoAtual = 1;
  bool _sucessoFinal = false;

  final MobileScannerController _scannerController = MobileScannerController();
  bool _processandoQR = false;

  File? _fotoProduto;
  String _enderecoFormatado = "Buscando localização...";
  Position? _localizacaoFoto;
  DateTime? _dataHoraFoto;
  bool _carregandoCamera = false;

  // =======================================================================
  // PASSO 1: LER QR CODE E ABRIR CÂMERA AUTOMATICAMENTE
  // =======================================================================
  Future<void> _aoLerQrCode(BarcodeCapture capture) async {
    if (_processandoQR) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      setState(() => _processandoQR = true);

      try {
        final String qrCodeLido = barcodes.first.rawValue!;
        final Map<String, dynamic> qrDados = json.decode(qrCodeLido);
        final String qrId = qrDados['id'] ?? '';
        final String qrAcao = qrDados['acao'] ?? '';
        final String qrCodigo = qrDados['codigo'] ?? '';

        final String codigoOriginal = widget.item.codigo.isNotEmpty
            ? widget.item.codigo
            : (widget.item.codigoAcompanhamento ?? widget.item.id);
        final String codigoMotoboy = codigoOriginal.length >= 6
            ? codigoOriginal.substring(0, 6).toUpperCase()
            : codigoOriginal.toUpperCase();

        if ((qrId == widget.item.id || qrCodigo == codigoMotoboy) &&
            qrAcao == "em_transporte") {
          await _scannerController.stop(); // Desliga a lente do QR Code

          if (mounted) {
            setState(() {
              _passoAtual = 2; // Avança a tela
              _processandoQR = false;
            });
          }

          // Abre a câmera nativa de fotos automaticamente
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _tirarFoto();
          });
        } else {
          _abortarLeituraInvalida("Este QR Code não pertence a este pedido!");
        }
      } catch (e) {
        _abortarLeituraInvalida("QR Code inválido ou danificado.");
      }
    }
  }

  void _abortarLeituraInvalida(String mensagem) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem), backgroundColor: Colors.redAccent),
      );
    }
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _processandoQR = false);
    });
  }

  // =======================================================================
  // PASSO 2: TIRAR FOTO E BUSCAR GPS
  // =======================================================================
  Future<void> _tirarFoto() async {
    setState(() => _carregandoCamera = true);

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? foto = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (foto != null) {
        setState(() => _fotoProduto = File(foto.path));

        // Pega os dados extras
        _localizacaoFoto = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _dataHoraFoto = DateTime.now();

        if (_localizacaoFoto != null) {
          _enderecoFormatado =
              "Lat: ${_localizacaoFoto!.latitude.toStringAsFixed(5)} / Lng: ${_localizacaoFoto!.longitude.toStringAsFixed(5)}";
          _buscarEndereco(
            _localizacaoFoto!.latitude,
            _localizacaoFoto!.longitude,
          );
        }
      }
    } catch (e) {
      debugPrint("Erro ao capturar foto: $e");
    } finally {
      if (mounted) setState(() => _carregandoCamera = false);
    }
  }

  Future<void> _buscarEndereco(double lat, double lng) async {
    try {
      final url =
          "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=${AppConfig.googleMapsApiKey}";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          String completo = data['results'][0]['formatted_address'];
          if (mounted)
            setState(() => _enderecoFormatado = completo.split('-')[0].trim());
        }
      }
    } catch (e) {}
  }

  // =======================================================================
  // FINALIZAR A OPERAÇÃO
  // =======================================================================
  Future<void> _finalizarColeta() async {
    if (_fotoProduto == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      ColetaController coletaCtrl = Provider.of<ColetaController>(
        context,
        listen: false,
      );

      await coletaCtrl.confirmarPosseComFoto(
        coletaId: widget.item.id,
        foto: _fotoProduto!,
        enderecoGeo: _enderecoFormatado,
      );

      await coletaCtrl.atualizarStatusColeta(widget.item.id, 'em_transporte');

      try {
        EntregadorController entregadorCtrl = Provider.of<EntregadorController>(
          context,
          listen: false,
        );
        String? entregadorId = FirebaseAuth.instance.currentUser?.uid;
        if (entregadorId != null && entregadorId.isNotEmpty)
          entregadorCtrl.iniciarRastreioInteligente(entregadorId);
      } catch (e) {}

      if (mounted) {
        Navigator.pop(context); // Fecha o loading
        setState(
          () => _sucessoFinal = true,
        ); // Exibe o botão de fechar para o operador
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: _sucessoFinal ? 400 : 650),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  _sucessoFinal
                      ? Icons.check_circle
                      : (_passoAtual == 1
                            ? Icons.qr_code_scanner
                            : Icons.camera_alt),
                  color: _sucessoFinal ? Colors.green : Colors.indigo,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _sucessoFinal
                        ? "Sucesso!"
                        : (_passoAtual == 1
                              ? "1. Ler QR Code"
                              : "2. Foto da Coleta"),
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
            const Divider(height: 24),
            Expanded(
              child: _sucessoFinal
                  ? _buildTelaSucesso()
                  : (_passoAtual == 1 ? _buildPasso1() : _buildPasso2()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasso1() {
    return Column(
      children: [
        const Text(
          "Aponte a câmera para o QR Code.",
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _aoLerQrCode,
                ),
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
      ],
    );
  }

  Widget _buildPasso2() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_fotoProduto == null) ...[
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text("Abrindo câmera...", style: TextStyle(fontSize: 15)),
        ] else ...[
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(_fotoProduto!, fit: BoxFit.cover),
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
                            _dataHoraFoto != null
                                ? DateFormat(
                                    'dd/MM/yyyy HH:mm:ss',
                                  ).format(_dataHoraFoto!)
                                : "",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _enderecoFormatado,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
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
              OutlinedButton.icon(
                onPressed: _tirarFoto,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("Refazer"),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _finalizarColeta,
                  icon: const Icon(Icons.cloud_upload, size: 20),
                  label: const Text(
                    "Confirmar",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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

  Widget _buildTelaSucesso() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 80),
        const SizedBox(height: 16),
        const Text(
          "Tudo Certo!\nColeta validada e radar ativado.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "FECHAR E VOLTAR",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
