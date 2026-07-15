import 'package:cloud_firestore/cloud_firestore.dart';

class PedidoInsumoModel {
  final String id;
  final String clinicaId;
  final String clinicaNome;
  final String laboratorioId;
  final List<dynamic> itens; // Ex: [{'nome': 'Tubo Seco', 'quantidade': 50}]
  final String status; // Pendente, Aprovado, Enviado, Concluido, Cancelado
  final DateTime dataSolicitacao;
  final DateTime? dataAtualizacao;

  PedidoInsumoModel({
    required this.id,
    required this.clinicaId,
    required this.clinicaNome,
    required this.laboratorioId,
    required this.itens,
    required this.status,
    required this.dataSolicitacao,
    this.dataAtualizacao,
  });

  factory PedidoInsumoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PedidoInsumoModel(
      id: doc.id,
      clinicaId: data['clinicaId'] ?? '',
      clinicaNome: data['clinicaNome'] ?? 'Clínica Desconhecida',
      laboratorioId: data['laboratorioId'] ?? '',
      itens: data['itens'] ?? [],
      status: data['status'] ?? 'Pendente',
      dataSolicitacao:
          (data['dataSolicitacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dataAtualizacao: (data['dataAtualizacao'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clinicaId': clinicaId,
      'clinicaNome': clinicaNome,
      'laboratorioId': laboratorioId,
      'itens': itens,
      'status': status,
      'dataSolicitacao': dataSolicitacao,
      'dataAtualizacao': dataAtualizacao ?? FieldValue.serverTimestamp(),
    };
  }
}
