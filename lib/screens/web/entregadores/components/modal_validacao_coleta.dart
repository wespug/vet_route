import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vet_route/models/coleta_model.dart';

class ModalValidacaoColeta extends StatefulWidget {
  final Coleta item;

  const ModalValidacaoColeta({super.key, required this.item});

  @override
  State createState() => _ModalValidacaoColetaState();
}

class _ModalValidacaoColetaState extends State {
  int _passoAtual = 1;

  // Dados do Passo 1
  String? _qrCodeLido;
  bool _processandoQR = false;

  // Dados do Passo 2
  File? _fotoProduto;
  Position? _localizacaoFoto;
  DateTime? _dataHoraFoto;
  bool _carregandoCamera = false;

  // =======================================================================
  // LÓGICA DO PASSO 1: LER QR CODE
  // =======================================================================
  void _aoLerQrCode(BarcodeCapture capture) {
    if (_processandoQR) return; // Evita múltiplas leituras simultâneas

    final List barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      setState(() {
        _processandoQR = true;
        _qrCodeLido = barcodes.first.rawValue;
      });

      // Aqui você pode adicionar uma validação (ex: verificar se o QR bate com a clínica)
      print("QR Code Lido: $_qrCodeLido");

      // Avança para o Passo 2 com um pequeno delay visual
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _passoAtual = 2);
        }
      });
    }
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
  void _finalizarColeta() {
    // Aqui você enviará a _fotoProduto, _qrCodeLido, _localizacaoFoto para o Firebase Storage / Firestore
    print("Enviando dados para o Firebase...");
    print("QR: $_qrCodeLido");
    print(
      "Lat: \({_localizacaoFoto?.latitude}, Lng:\){_localizacaoFoto?.longitude}",
    );

    Navigator.pop(context); // Fecha o modal
    // Chame aqui o seu ColetaController para atualizar o status para "em_transporte" ou similar.
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
                            "Lat: \({_localizacaoFoto?.latitude}\nLng:\){_localizacaoFoto?.longitude}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
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
