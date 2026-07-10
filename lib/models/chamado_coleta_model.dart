class ChamadoColetaModel {
  final String id;
  final String clinicaId;
  final String clinicaNome;
  final String laboratorioId;
  final String laboratorioNome;
  final String status;
  final bool isEmergencia;
  final DateTime dataCriacao;
  final DateTime dataAgendamento; // 💡 Novo campo adicionado

  ChamadoColetaModel({
    required this.id,
    required this.clinicaId,
    required this.clinicaNome,
    required this.laboratorioId,
    required this.laboratorioNome,
    required this.status,
    required this.isEmergencia,
    required this.dataCriacao,
    required this.dataAgendamento,
  });

  Map<String, dynamic> toMap() {
    return {
      'clinicaId': clinicaId,
      'clinicaNome': clinicaNome,
      'laboratorioId': laboratorioId,
      'laboratorioNome': laboratorioNome,
      'status': status,
      'isEmergencia': isEmergencia,
      'dataCriacao': dataCriacao.toIso8601String(),
      'dataAgendamento': dataAgendamento.toIso8601String(),
    };
  }

  factory ChamadoColetaModel.fromMap(String id, Map<String, dynamic> map) {
    return ChamadoColetaModel(
      id: id,
      clinicaId: map['clinicaId'] ?? '',
      clinicaNome: map['clinicaNome'] ?? '',
      laboratorioId: map['laboratorioId'] ?? '',
      laboratorioNome: map['laboratorioNome'] ?? '',
      status: map['status'] ?? 'Aguardando Entregador',
      isEmergencia: map['isEmergencia'] ?? false,
      dataCriacao: map['dataCriacao'] != null
          ? DateTime.parse(map['dataCriacao'])
          : DateTime.now(),
      // Se for um chamado antigo sem agendamento, ele usa a data de criação para não quebrar a tela
      dataAgendamento: map['dataAgendamento'] != null
          ? DateTime.parse(map['dataAgendamento'])
          : (map['dataCriacao'] != null
                ? DateTime.parse(map['dataCriacao'])
                : DateTime.now()),
    );
  }
}
