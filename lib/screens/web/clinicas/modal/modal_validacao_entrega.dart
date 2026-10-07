import 'dart:io';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vet_route/controllers/entregador_controller.dart';
import 'package:vet_route/models/coleta_model.dart';

class ModalValidacaoEntrega extends StatefulWidget {
  final Coleta
  pedido; // Substitua pelos campos reais do seu Model se necessário

  const ModalValidacaoEntrega({super.key, required this.pedido});

  @override
  State<ModalValidacaoEntrega> createState() => _ModalValidacaoEntregaState();
}

class _ModalValidacaoEntregaState extends State<ModalValidacaoEntrega> {
  File? _fotoEntregue;
  bool _processando = false;

  // 📸 ABRE A CÂMARA E CAPTURA A PROVA
  Future _tirarFoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60, // Comprime para gastar pouca internet
    );

    if (pickedFile != null) {
      setState(() {
        _fotoEntregue = File(pickedFile.path);
      });
    }
  }

  // 🚀 CONCLUI A ROTA
  Future _finalizarEntrega() async {
    if (_fotoEntregue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Tire uma foto do pacote no destino para comprovar a entrega.",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _processando = true);

    try {
      // 1. Pega o GPS exato da porta do destino
      Position posicao = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 2. Regista o carimbo de tempo
      final agora = DateTime.now();
      final dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(agora);

      // 3. TRADUZ AS COORDENADAS PARA NOME DE RUA
      String enderecoFormatado = "Endereço não capturado";
      try {
        List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
          posicao.latitude,
          posicao.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          enderecoFormatado =
              place.street ??
              place.thoroughfare ??
              place.name ??
              "Endereço desconhecido";
        }
      } catch (e) {
        debugPrint("Erro ao converter coordenadas para rua: $e");
        enderecoFormatado =
            "GPS: " +
            posicao.latitude.toStringAsFixed(5) +
            ", " +
            posicao.longitude.toStringAsFixed(5);
      }

      // 4. DELEGA PARA O CONTROLLER
      await Provider.of<EntregadorController>(
        context,
        listen: false,
      ).confirmarEntregaComFoto(
        pedidoId: widget.pedido.id,
        foto: _fotoEntregue!,
        enderecoGeo: enderecoFormatado,
        lat: posicao.latitude,
        lng: posicao.longitude,
        dataFormatada: dataFormatada,
      );

      // 5. Fecha e avisa do sucesso
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Entrega finalizada com sucesso! ✅"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Erro ao finalizar entrega: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro na conexão: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          // Adicionado para evitar overflow em telas pequenas
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 50,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              const Text(
                "Confirmar Entrega",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Registe a prova de que o pacote foi entregue no destino.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),

              // --- NOVO BLOCO: RESUMO DA COLETA E DESTINO ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors
                      .blue
                      .shade50, // Fundo levemente azul para destaque amigável
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "#${widget.pedido.codigoFormatado ?? 'Não informado'}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const Divider(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.circle_outlined,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            // Substitua .origem pela variável correta do seu modelo
                            "Origem: ${widget.pedido.origemVisual ?? 'Endereço da clínica'}",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            // Substitua .destino pela variável correta do seu modelo
                            "Destino: ${widget.pedido.destinoVisual ?? 'Endereço do laboratório'}",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // CAIXA DA FOTO
              GestureDetector(
                onTap: _processando ? null : _tirarFoto,
                child: Container(
                  height:
                      160, // Levemente reduzido para caber melhor com a nova área
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _fotoEntregue != null
                          ? Colors.green
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: _fotoEntregue != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_fotoEntregue!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Tocar para Fotografar",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // BOTÕES
              _processando
                  ? const CircularProgressIndicator(color: Colors.green)
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              "Cancelar",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _finalizarEntrega,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
    );
  }
}
