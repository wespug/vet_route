import 'package:cloud_firestore/cloud_firestore.dart';

class InsumoModel {
  final String? id;
  final String laboratorioId;
  final String descricao;
  final String tipo;
  final String tamanho;
  final String volume;

  InsumoModel({
    this.id,
    required this.laboratorioId,
    required this.descricao,
    required this.tipo,
    required this.tamanho,
    required this.volume,
  });

  Map<String, dynamic> toMap() {
    return {
      'laboratorioId': laboratorioId,
      'descricao': descricao,
      'tipo': tipo,
      'tamanho': tamanho,
      'volume': volume,
    };
  }

  factory InsumoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InsumoModel(
      id: doc.id,
      laboratorioId: data['laboratorioId'] ?? '',
      descricao: data['descricao'] ?? '',
      tipo: data['tipo'] ?? '',
      tamanho: data['tamanho'] ?? '',
      volume: data['volume'] ?? '',
    );
  }
}
