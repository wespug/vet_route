import 'package:cloud_firestore/cloud_firestore.dart';

class ExameModel {
  final String? id;
  final String laboratorioId;
  final String nome;
  final String detalhes;
  final String porte;
  final String especie;

  ExameModel({
    this.id,
    required this.laboratorioId,
    required this.nome,
    required this.detalhes,
    required this.porte,
    required this.especie,
  });

  Map<String, dynamic> toMap() {
    return {
      'laboratorioId': laboratorioId,
      'nome': nome,
      'detalhes': detalhes,
      'porte': porte,
      'especie': especie,
    };
  }

  factory ExameModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExameModel(
      id: doc.id,
      laboratorioId: data['laboratorioId'] ?? '',
      nome: data['nome'] ?? '',
      detalhes: data['detalhes'] ?? '',
      porte: data['porte'] ?? '',
      especie: data['especie'] ?? '',
    );
  }
}
