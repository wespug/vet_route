import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PedidoInsumoModel {
  final String id;
  final String clinicaId;
  final String clinicaNome;
  final String laboratorioId;
  final String laboratorioNome; // 🔹 Preservado com segurança
  final List<Map<String, dynamic>> itens;
  final String status;
  final DateTime dataSolicitacao;
  final DateTime? dataAtualizacao;

  // 🔹 Campos adicionados para cobrir todas as informações do Modal e Histórico
  final String usuarioSolicitante;
  final String justificativaLab;
  final String usuarioLabObs;
  final DateTime? dataLabObs;

  PedidoInsumoModel({
    required this.id,
    required this.clinicaId,
    required this.clinicaNome,
    required this.laboratorioId,
    this.laboratorioNome = '', // Com fallback seguro
    required this.itens,
    required this.status,
    required this.dataSolicitacao,
    this.dataAtualizacao,
    required this.usuarioSolicitante,
    required this.justificativaLab,
    required this.usuarioLabObs,
    this.dataLabObs,
  });

  factory PedidoInsumoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime? parseData(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return null;
    }

    return PedidoInsumoModel(
      id: doc.id,
      clinicaId: data['clinicaId'] ?? '',
      clinicaNome: data['clinicaNome'] ?? 'Clínica Desconhecida',
      laboratorioId: data['laboratorioId'] ?? '',
      laboratorioNome:
          data['laboratorioNome'] ?? data['laboratorioId'] ?? 'Laboratório',
      itens: List<Map<String, dynamic>>.from(data['itens'] ?? []),
      status: (data['status'] ?? 'Pendente').toString(),
      dataSolicitacao:
          parseData(data['dataSolicitacao'] ?? data['dataPedido']) ??
          DateTime.now(),
      dataAtualizacao: parseData(data['dataAtualizacao']),

      // Mapeamento dos novos campos com fallbacks de legatariedade do Firestore
      usuarioSolicitante:
          data['usuarioSolicitante'] ??
          data['solicitanteNome'] ??
          data['usuarioLogado'] ??
          'Não informado',
      justificativaLab:
          data['justificativaLab'] ?? data['observacaoLaboratorio'] ?? '',
      usuarioLabObs:
          data['usuarioObservacaoLab'] ??
          data['usuarioRespostaLab'] ??
          data['laboratorioUsuario'] ??
          '',
      dataLabObs: parseData(
        data['dataObservacaoLab'] ?? data['dataRespostaLab'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clinicaId': clinicaId,
      'clinicaNome': clinicaNome,
      'laboratorioId': laboratorioId,
      'laboratorioNome': laboratorioNome,
      'itens': itens,
      'status': status,
      'dataSolicitacao': dataSolicitacao,
      'dataAtualizacao': dataAtualizacao ?? FieldValue.serverTimestamp(),
      'usuarioSolicitante': usuarioSolicitante,
      'justificativaLab': justificativaLab,
      'usuarioObservacaoLab': usuarioLabObs,
      'dataObservacaoLab': dataLabObs,
    };
  }

  // ===========================================================================
  // 🎯 GETTERS DE REGRA DE NEGÓCIO E APRESENTAÇÃO (PADRÃO MVC)
  // ===========================================================================

  /// Identificador para diferenciar exames de insumos
  bool get isInsumo => true;

  /// Código de identificação amigável para exibição
  String get codigo => id;

  /// Origem visual para o entregador (No insumo, o ponto de partida é o Laboratório)
  String get nomeOrigemVisual =>
      laboratorioNome.isNotEmpty ? laboratorioNome : 'Laboratório';

  /// Destino visual para o entregador (No insumo, o ponto de chegada é a Clínica)
  String get nomeDestinoVisual =>
      clinicaNome.isNotEmpty ? clinicaNome : 'Clínica não informada';

  /// Define se o pedido ainda pode ser cancelado pelo usuário
  bool get podeCancelar {
    final st = status.toLowerCase();
    return st == 'pendente' || st == 'aguardando_analise';
  }

  /// Define se o pedido foi negado ou cancelado
  bool get isRecusadoOuCancelado {
    final st = status.toLowerCase();
    return st == 'recusado' || st == 'cancelado';
  }

  /// Cor associada ao badge/status do pedido
  Color get corStatus {
    switch (status.toLowerCase()) {
      case 'pendente':
      case 'aguardando_analise':
        return Colors.orange.shade700;
      case 'em_separacao':
      case 'em separação':
        return Colors.blue.shade700;
      case 'aguardando_coleta':
      case 'aguardando coleta':
        return Colors.purple.shade700;
      case 'entregue':
      case 'concluído':
      case 'concluido':
        return Colors.green.shade700;
      case 'recusado':
      case 'cancelado':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  /// Texto amigável para exibição na interface
  String get textoStatus {
    switch (status.toLowerCase()) {
      case 'pendente':
      case 'aguardando_analise':
        return 'Pendente / Em Análise pelo Lab';
      case 'em_separacao':
      case 'em separação':
        return 'Em Separação no Laboratório';
      case 'aguardando_coleta':
      case 'aguardando coleta':
        return 'Pronto / Aguardando Motoboy';
      case 'entregue':
      case 'concluído':
      case 'concluido':
        return 'Pedido Entregue';
      case 'recusado':
        return 'Pedido Recusado pelo Laboratório';
      case 'cancelado':
        return 'Pedido Cancelado';
      default:
        return status;
    }
  }

  /// Ícone indicativo do status
  IconData get iconeStatus {
    switch (status.toLowerCase()) {
      case 'pendente':
      case 'aguardando_analise':
        return Icons.hourglass_top_rounded;
      case 'em_separacao':
      case 'em separação':
        return Icons.inventory_2_outlined;
      case 'aguardando_coleta':
      case 'aguardando coleta':
        return Icons.sports_motorsports_outlined;
      case 'entregue':
      case 'concluído':
      case 'concluido':
        return Icons.check_circle_outline;
      case 'recusado':
      case 'cancelado':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  /// Formata qualquer DateTime para o padrão visual 'dd/MM/yyyy HH:mm'
  String formatarData(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }
}
