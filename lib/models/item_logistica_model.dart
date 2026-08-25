import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// 💡 FUNÇÃO BLINDADA: Aceita Timestamp novo e String antiga sem quebrar a tabela!
DateTime _parseDataSegura(dynamic val) {
  if (val is Timestamp) return val.toDate();
  if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
  return DateTime.now();
}

class HistoricoStatusLog {
  final String status;
  final String usuario;
  final DateTime data;
  final String observacao;

  HistoricoStatusLog({
    required this.status,
    required this.usuario,
    required this.data,
    required this.observacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'usuario': usuario,
      'data': Timestamp.fromDate(data),
      'observacao': observacao,
    };
  }

  factory HistoricoStatusLog.fromMap(Map<String, dynamic> map) {
    return HistoricoStatusLog(
      status: map['status'] ?? '',
      usuario: map['usuario'] ?? 'Sistema',
      data: _parseDataSegura(map['data']),
      observacao: map['observacao'] ?? '',
    );
  }
}

class ItemLogisticaModel {
  final String id;
  final String codigo;
  final String laboratorioNome;
  final DateTime dataCriacao;
  final String status;
  final bool isInsumo;
  final String nomeTipoFormatado;

  final List<dynamic> itensInsumo;
  final List<HistoricoStatusLog> historicoLogs;
  final String usuarioCriador;

  ItemLogisticaModel({
    required this.id,
    required this.codigo,
    required this.laboratorioNome,
    required this.dataCriacao,
    required this.status,
    required this.isInsumo,
    required this.nomeTipoFormatado,
    this.itensInsumo = const [],
    this.historicoLogs = const [],
    this.usuarioCriador = '',
  });

  // 💡 LABEL AMIGÁVEL: Separação definitiva entre Recusado e Cancelado
  String get textoStatus {
    final s = status.toLowerCase().trim();
    if (s.contains('separacao') ||
        s.contains('separação') ||
        s.contains('aprovado')) {
      return 'Em Separação';
    }
    if (s.contains('aguardando')) {
      return 'Aguardando Coleta';
    }
    if (s.contains('rota') ||
        s.contains('transito') ||
        s.contains('trânsito')) {
      return 'Em Rota';
    }
    if (s.contains('recusad')) {
      return 'Recusado pelo Lab';
    }
    if (s.contains('cancelado')) {
      return 'Cancelado';
    }
    if (s.contains('entregue') || s.contains('conclu')) {
      return 'Concluído';
    }
    if (s.contains('pendente')) {
      return 'Pendente';
    }
    return status.isNotEmpty
        ? (status[0].toUpperCase() + status.substring(1))
        : 'Desconhecido';
  }

  // 💡 CORES DEFINITIVAS: Vermelho Escuro para Recusado e Padrão para Cancelado
  Color get corStatus {
    final s = status.toLowerCase().trim();
    if (s.contains('recusad'))
      return Colors.red.shade900; // Destaque extra para recusa
    if (s.contains('cancel')) return Colors.red.shade600;
    if (s.contains('entregue') || s.contains('conclu'))
      return Colors.green.shade700;
    if (s.contains('separacao') ||
        s.contains('separação') ||
        s.contains('aprovado'))
      return Colors.blue.shade700;
    if (s.contains('rota') || s.contains('trânsito') || s.contains('transito'))
      return Colors.indigo.shade600;
    if (s.contains('aguardando')) return Colors.orange.shade700;
    return Colors.amber.shade800;
  }

  String formatarData(DateTime data) {
    return "${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} às ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}";
  }

  List<HistoricoStatusLog> get historicoCompletoEOrdenado {
    List<HistoricoStatusLog> logs = List.from(historicoLogs);
    logs.sort((a, b) => a.data.compareTo(b.data));

    bool possuiMarcoZero = logs.any(
      (log) =>
          log.status.toLowerCase().contains('pendente') ||
          log.observacao.toLowerCase().contains('criação') ||
          log.observacao.toLowerCase().contains('criado'),
    );

    if (!possuiMarcoZero) {
      logs.insert(
        0,
        HistoricoStatusLog(
          status: 'Pendente',
          usuario: usuarioCriador.isNotEmpty
              ? usuarioCriador
              : 'Usuário / Clínica',
          data: dataCriacao,
          observacao: 'Pedido registrado na plataforma',
        ),
      );
    }
    return logs;
  }

  factory ItemLogisticaModel.fromChamadoColeta(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // 💡 PONTE DE DADOS: Lê tanto 'historicoLogs' (Clínica) quanto 'historico' (Lab)
    List<HistoricoStatusLog> logs = [];
    final rawLogs = data['historicoLogs'] ?? data['historico'];
    if (rawLogs != null) {
      logs = (rawLogs as List)
          .map((e) => HistoricoStatusLog.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }

    final safeCodigo =
        (data['codigo'] != null && data['codigo'].toString().trim().isNotEmpty)
        ? data['codigo'].toString()
        : (doc.id.length >= 6
              ? doc.id.substring(0, 6).toUpperCase()
              : doc.id.toUpperCase());

    return ItemLogisticaModel(
      id: doc.id,
      codigo: safeCodigo,
      laboratorioNome: data['laboratorioNome'] ?? 'Laboratório Geral',
      dataCriacao: _parseDataSegura(data['dataCriacao']),
      status: data['status'] ?? 'Pendente',
      isInsumo: false,
      nomeTipoFormatado: data['isUrgencia'] == true
          ? 'Coleta de Urgência'
          : 'Coleta Agendada',
      itensInsumo: [],
      historicoLogs: logs,
      usuarioCriador: data['usuarioCriador'] ?? '',
    );
  }

  factory ItemLogisticaModel.fromPedidoInsumo(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // 💡 PONTE DE DADOS: Lê tanto 'historicoLogs' (Clínica) quanto 'historico' (Lab)
    List<HistoricoStatusLog> logs = [];
    final rawLogs = data['historicoLogs'] ?? data['historico'];
    if (rawLogs != null) {
      logs = (rawLogs as List)
          .map((e) => HistoricoStatusLog.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }

    final safeCodigo =
        (data['codigo'] != null && data['codigo'].toString().trim().isNotEmpty)
        ? data['codigo'].toString()
        : (doc.id.length >= 6
              ? doc.id.substring(0, 6).toUpperCase()
              : doc.id.toUpperCase());

    return ItemLogisticaModel(
      id: doc.id,
      codigo: safeCodigo,
      laboratorioNome: data['laboratorioNome'] ?? 'Laboratório Geral',
      dataCriacao: _parseDataSegura(data['dataCriacao']),
      status: data['status'] ?? 'Pendente',
      isInsumo: true,
      nomeTipoFormatado: 'Pedido de Insumo',
      itensInsumo: data['itens'] ?? [],
      historicoLogs: logs,
      usuarioCriador: data['usuarioCriador'] ?? '',
    );
  }
}
