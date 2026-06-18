// lib/models/laboratorio_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'endereco_model.dart';

class Laboratorio {
  final String id;
  final String nome;
  final String telefone;
  final Endereco endereco;

  Laboratorio({
    required this.id,
    required this.nome,
    required this.telefone,
    required this.endereco,
  });

  /// Mapeia o DocumentSnapshot do Firestore diretamente para o objeto Laboratorio
  factory Laboratorio.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Extrai o mapa interno de endereço
    final enderecoMap = data['endereco'] as Map<String, dynamic>;

    return Laboratorio(
      id: doc.id,
      nome: data['nome'] ?? '',
      telefone: data['telefone'] ?? '',
      endereco: Endereco(
        nome: enderecoMap['nome'] ?? '',
        rua: enderecoMap['rua'] ?? '',
        cep: enderecoMap['cep'] ?? '',
        cidade: enderecoMap['cidade'] ?? '',
        estado: enderecoMap['estado'] ?? '',
        pais: enderecoMap['pais'] ?? '',
        // 💡 Blindagem: Se for null, usa 0.0 ou a coordenada padrão da Liberdade
        coordenada: LatLng(
          (enderecoMap['lat'] as num?)?.toDouble() ?? -23.5548755,
          (enderecoMap['long'] as num?)?.toDouble() ?? -46.6356176,
        ),
      ),
    );
  }
}
