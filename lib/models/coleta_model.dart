import 'package:cloud_firestore/cloud_firestore.dart';
import 'clinica_model.dart';
import 'laboratorio_model.dart';
import 'entregador_model.dart';
import 'endereco_model.dart';

class Coleta {
  final String id;
  final Clinica clinicaOrigem;
  final Laboratorio laboratorioDestino;
  final Entregador? entregador;
  final String? entregadorIdFlat;
  final String? entregadorNomeFlat;
  final String status;
  final bool isUrgente;
  final bool isInsumo;
  final String? codigoAcompanhamento;
  final DateTime? dataSolicitacao;
  final String? enderecoFlat;
  final List<dynamic> itens;
  final List<dynamic> historico;

  Coleta({
    required this.id,
    required this.clinicaOrigem,
    required this.laboratorioDestino,
    this.entregador,
    this.entregadorIdFlat,
    this.entregadorNomeFlat,
    this.status = 'Aguardando',
    this.isUrgente = false,
    this.isInsumo = false,
    this.codigoAcompanhamento,
    this.dataSolicitacao,
    this.enderecoFlat,
    this.itens = const [],
    this.historico = const [],
  });

  bool get isEmergencia => isUrgente;
  String get nomeClinica =>
      clinicaOrigem.nome.isNotEmpty ? clinicaOrigem.nome : 'Clínica Parceira';
  String get codigo => codigoAcompanhamento ?? id;

  String get idDoEntregador => entregador?.id ?? entregadorIdFlat ?? '';
  String get nomeDoEntregador =>
      entregador?.nome ?? entregadorNomeFlat ?? 'Aguardando Entregador';

  String get enderecoCompleto {
    if (enderecoFlat != null && enderecoFlat!.isNotEmpty) {
      return enderecoFlat!;
    }
    if (clinicaOrigem.endereco.logradouro.isNotEmpty) {
      return '${clinicaOrigem.endereco.logradouro}, ${clinicaOrigem.endereco.numero} - ${clinicaOrigem.endereco.bairro}';
    }
    return 'Endereço não cadastrado';
  }

  DateTime? get dataCriacao => dataSolicitacao;

  String get origemVisual => isInsumo ? laboratorioDestino.nome : nomeClinica;
  String get destinoVisual => isInsumo ? nomeClinica : laboratorioDestino.nome;

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'isUrgente': isUrgente,
      'isInsumo': isInsumo,
      'codigoAcompanhamento': codigoAcompanhamento,
      'clinicaOrigem': clinicaOrigem.toMap(),
      'laboratorioDestino': laboratorioDestino.toMap(),
      'entregador': entregador?.toMap(),
      'entregadorId': idDoEntregador,
      'nomeEntregador': nomeDoEntregador,
      'dataSolicitacao': dataSolicitacao != null
          ? Timestamp.fromDate(dataSolicitacao!)
          : FieldValue.serverTimestamp(),
      'dataAtualizacao': FieldValue.serverTimestamp(),
      'enderecoCompleto': enderecoFlat,
      'itens': itens,
      'historico': historico,
    };
  }

  factory Coleta.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final Map<String, dynamic> clinicaData =
        data['clinicaOrigem'] as Map<String, dynamic>? ?? {};
    final String clinicaId = clinicaData['id'] ?? data['clinicaId'] ?? '';
    final String clinicaNome =
        clinicaData['nome'] ?? data['clinicaNome'] ?? 'Clínica Parceira';

    final Map<String, dynamic> labData =
        data['laboratorioDestino'] as Map<String, dynamic>? ?? {};
    final String labId = labData['id'] ?? data['laboratorioId'] ?? '';
    final String labNome =
        labData['nome'] ?? data['laboratorioNome'] ?? 'Laboratório Parceiro';

    final Map<String, dynamic>? entregadorMap =
        data['entregador'] as Map<String, dynamic>?;
    Entregador? objEntregador;

    if (entregadorMap != null) {
      try {
        objEntregador = Entregador.fromMap(entregadorMap);
      } catch (_) {}
    }

    DateTime? dataParseada;
    // 💡 CORREÇÃO AQUI: Prioriza a leitura do agendamento futuro!
    if (data['dataAgendamento'] is Timestamp) {
      dataParseada = (data['dataAgendamento'] as Timestamp).toDate();
    } else if (data['dataAgendamento'] is String) {
      dataParseada = DateTime.tryParse(data['dataAgendamento']);
    } else if (data['dataSolicitacao'] is Timestamp) {
      dataParseada = (data['dataSolicitacao'] as Timestamp).toDate();
    } else if (data['dataCriacao'] is Timestamp) {
      dataParseada = (data['dataCriacao'] as Timestamp).toDate();
    } else if (data['atualizadoEm'] is Timestamp) {
      dataParseada = (data['atualizadoEm'] as Timestamp).toDate();
    }

    final bool isCollectionInsumo =
        doc.reference.parent.id == 'pedidos_insumos';
    final bool hasItems = data.containsKey('itens');
    final bool flagInsumo =
        data['possuiInsumo'] == true ||
        data['isInsumo'] == true ||
        data['tipo']?.toString().toLowerCase() == 'insumo';

    final itensList = (data['itens'] as List<dynamic>?) ?? [];
    final historicoList =
        (data['historico'] as List<dynamic>?) ??
        (data['historicoLogs'] as List<dynamic>?) ??
        [];

    return Coleta(
      id: doc.id,
      status: data['status'] ?? 'Aguardando',
      isUrgente: data['isUrgente'] ?? data['urgente'] ?? false,
      isInsumo: isCollectionInsumo || hasItems || flagInsumo,
      codigoAcompanhamento: data['codigoAcompanhamento'] ?? data['codigo'],
      dataSolicitacao: dataParseada,
      enderecoFlat: data['enderecoCompleto'] ?? data['endereco'],
      entregador: objEntregador,
      entregadorIdFlat: data['entregadorId'],
      entregadorNomeFlat: data['nomeEntregador'],
      itens: itensList,
      historico: historicoList,
      clinicaOrigem: Clinica(
        id: clinicaId,
        nome: clinicaNome,
        email: clinicaData['email'] ?? '',
        telefone: clinicaData['telefone'] ?? '',
        cnpj: clinicaData['cnpj'] ?? '',
        endereco: Endereco.fromMap(
          clinicaData['endereco'] as Map<String, dynamic>? ?? {},
        ),
      ),
      laboratorioDestino: Laboratorio(
        id: labId,
        nome: labNome,
        email: labData['email'] ?? '',
        telefone: labData['telefone'] ?? '',
        cnpj: labData['cnpj'] ?? '',
        endereco: Endereco.fromMap(
          labData['endereco'] as Map<String, dynamic>? ?? {},
        ),
      ),
    );
  }
}
