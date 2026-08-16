class ChamadoColetaModel {
  final String id;
  final String clinicaId;
  final String clinicaNome;
  final String laboratorioId;
  final String laboratorioNome;
  final String status;
  final bool isEmergencia;
  final DateTime dataCriacao;
  final DateTime dataAgendamento;
  final String tipoChamado;
  final List<Map<String, dynamic>> insumosSolicitados;
  final String observacao;

  // 💡 NOVOS CAMPOS: Suporte a atribuição e rastreio de Motoboy/Entregador
  final String? entregadorId;
  final String? entregadorNome;
  final String? enderecoOrigem;
  final String? enderecoDestino;

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
    this.tipoChamado = 'Coleta',
    this.insumosSolicitados = const [],
    this.observacao = '',
    this.entregadorId,
    this.entregadorNome,
    this.enderecoOrigem,
    this.enderecoDestino,
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
      'tipoChamado': tipoChamado,
      'insumosSolicitados': insumosSolicitados,
      'observacao': observacao,
      'entregadorId': entregadorId,
      'entregadorNome': entregadorNome,
      'enderecoOrigem': enderecoOrigem,
      'enderecoDestino': enderecoDestino,
    };
  }

  factory ChamadoColetaModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseData(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ChamadoColetaModel(
      id: id,
      clinicaId: map['clinicaId'] ?? '',
      clinicaNome: map['clinicaNome'] ?? '',
      laboratorioId: map['laboratorioId'] ?? '',
      laboratorioNome: map['laboratorioNome'] ?? '',
      status: map['status'] ?? 'Aguardando Entregador',
      isEmergencia: map['isEmergencia'] ?? false,
      tipoChamado: map['tipoChamado'] ?? 'Coleta',
      insumosSolicitados: List<Map<String, dynamic>>.from(
        map['insumosSolicitados'] ?? [],
      ),
      dataCriacao: parseData(map['dataCriacao']),
      dataAgendamento: parseData(map['dataAgendamento']),
      observacao: map['observacao'] ?? '',
      entregadorId: map['entregadorId'],
      entregadorNome: map['entregadorNome'],
      enderecoOrigem: map['enderecoOrigem'],
      enderecoDestino: map['enderecoDestino'],
    );
  }
}
