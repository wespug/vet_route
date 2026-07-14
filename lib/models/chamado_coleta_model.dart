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
  // 💡 CAMPOS PARA SUPORTAR PEDIDO DE INSUMOS
  final String tipoChamado;
  final List<Map<String, dynamic>> insumosSolicitados;
  // 💡 NOVO CAMPO: Observação do material a ser coletado
  final String observacao;

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
    this.tipoChamado = 'Coleta', // Mantém o padrão antigo intacto
    this.insumosSolicitados = const [],
    this.observacao = '', // 💡 Proteção contra dados antigos nulos
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
      'observacao': observacao, // 💡 Adicionado para ir para o Firebase
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
      tipoChamado: map['tipoChamado'] ?? 'Coleta',
      insumosSolicitados: List<Map<String, dynamic>>.from(
        map['insumosSolicitados'] ?? [],
      ),
      dataCriacao: map['dataCriacao'] != null
          ? DateTime.parse(map['dataCriacao'])
          : DateTime.now(),
      dataAgendamento: map['dataAgendamento'] != null
          ? DateTime.parse(map['dataAgendamento'])
          : DateTime.now(),
      observacao: map['observacao'] ?? '', // 💡 Adicionado para ler do Firebase
    );
  }
}
