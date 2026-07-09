import 'package:cloud_firestore/cloud_firestore.dart';

class ParadaRota {
  final String clinicaId;
  final String nomeClinica;
  final String horarioPrevisto;

  ParadaRota({
    required this.clinicaId,
    required this.nomeClinica,
    required this.horarioPrevisto,
  });

  Map<String, dynamic> toMap() {
    return {
      'clinicaId': clinicaId,
      'nomeClinica': nomeClinica,
      'horarioPrevisto': horarioPrevisto,
    };
  }

  factory ParadaRota.fromMap(Map<String, dynamic> map) {
    return ParadaRota(
      clinicaId: map['clinicaId'] ?? '',
      nomeClinica: map['nomeClinica'] ?? '',
      horarioPrevisto: map['horarioPrevisto'] ?? '',
    );
  }
}

class RotaModel {
  final String? id;
  final String laboratorioId;
  final String entregadorId;
  final String nomeEntregador;
  final List<ParadaRota> paradas;
  final bool ativa;

  RotaModel({
    this.id,
    required this.laboratorioId,
    required this.entregadorId,
    required this.nomeEntregador,
    required this.paradas,
    this.ativa = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'laboratorioId': laboratorioId,
      'entregadorId': entregadorId,
      'nomeEntregador': nomeEntregador,
      'paradas': paradas.map((p) => p.toMap()).toList(),
      'ativa': ativa,
      'dataCriacao': FieldValue.serverTimestamp(),
    };
  }

  factory RotaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RotaModel(
      id: doc.id,
      laboratorioId: data['laboratorioId'] ?? '',
      entregadorId: data['entregadorId'] ?? '',
      nomeEntregador: data['nomeEntregador'] ?? '',
      paradas:
          (data['paradas'] as List<dynamic>?)
              ?.map((p) => ParadaRota.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      ativa: data['ativa'] ?? true,
    );
  }
}
