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
  final String status;
  final bool isUrgente;
  final String? codigoAcompanhamento;
  final DateTime? dataSolicitacao;
  final bool isInsumo;
  final String? nomeLaboratorioOrigemTexto;
  final List itens;
  final List historico;
  final double? latitudeOrigem;
  final double? longitudeOrigem;
  // 💡 NOVO: Coordenadas de destino adicionadas
  final double? latitudeDestino;
  final double? longitudeDestino;

  Coleta({
    required this.id,
    required this.clinicaOrigem,
    required this.laboratorioDestino,
    this.entregador,
    this.status = 'Aguardando',
    this.isUrgente = false,
    this.codigoAcompanhamento,
    this.dataSolicitacao,
    this.isInsumo = false,
    this.nomeLaboratorioOrigemTexto,
    this.itens = const [],
    this.historico = const [],
    this.latitudeOrigem,
    this.longitudeOrigem,
    this.latitudeDestino, // 💡 NOVO
    this.longitudeDestino, // 💡 NOVO
  });

  bool get isEmergencia => isUrgente;

  String get origemVisual => isInsumo
      ? (laboratorioDestino.nome.isNotEmpty
            ? laboratorioDestino.nome
            : (nomeLaboratorioOrigemTexto ?? 'Laboratório'))
      : (clinicaOrigem.nome.isNotEmpty
            ? clinicaOrigem.nome
            : 'Clínica não informada');

  String get origem => origemVisual;
  String get codigo => codigoAcompanhamento ?? id;

  String get destinoVisual => isInsumo
      ? (clinicaOrigem.nome.isNotEmpty
            ? clinicaOrigem.nome
            : 'Clínica não informada')
      : (laboratorioDestino.nome.isNotEmpty
            ? laboratorioDestino.nome
            : 'Laboratório não informado');

  String get enderecoOrigemVisual => isInsumo
      ? laboratorioDestino.endereco.enderecoCompleto
      : clinicaOrigem.endereco.enderecoCompleto;

  String get enderecoDestinoVisual => isInsumo
      ? clinicaOrigem.endereco.enderecoCompleto
      : laboratorioDestino.endereco.enderecoCompleto;

  String get codigoFormatado {
    final String original = codigo.isNotEmpty ? codigo : id;
    if (original.length >= 6) {
      return original.substring(0, 6).toUpperCase();
    }
    return original.toUpperCase();
  }

  String get nomeClinica => clinicaOrigem.nome;

  DateTime? get dataCriacao => dataSolicitacao;

  String get idDoEntregador => entregador?.id ?? '';
  String get nomeDoEntregador => entregador?.nome ?? 'Aguardando Entregador';

  Map toMap() {
    return {
      'status': status,
      'isUrgente': isUrgente,
      'isInsumo': isInsumo,
      'codigoAcompanhamento': codigoAcompanhamento,
      'nomeLaboratorioOrigemTexto': nomeLaboratorioOrigemTexto,
      'itens': itens,
      'historico': historico,
      'clinicaOrigem': clinicaOrigem.toMap(),
      'laboratorioDestino': laboratorioDestino.toMap(),
      'entregador': entregador?.toMap(),
      'latitudeOrigem': latitudeOrigem,
      'longitudeOrigem': longitudeOrigem,
      'latitudeDestino': latitudeDestino, // 💡 NOVO
      'longitudeDestino': longitudeDestino, // 💡 NOVO
      'dataSolicitacao': dataSolicitacao != null
          ? Timestamp.fromDate(dataSolicitacao!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory Coleta.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map? ?? {};
    final String collectionName = doc.reference.parent.path;

    final bool ehInsumo =
        collectionName.contains('pedidos_insumos') ||
        (data['codigoAcompanhamento'] != null &&
            data['codigoAcompanhamento'].toString().contains('INS')) ||
        data['itens'] != null ||
        data['possuiInsumo'] == true ||
        data['tipo']?.toString().toLowerCase() == 'insumo';

    final Map clinicaData = data['clinicaOrigem'] as Map? ?? {};
    final Map labData = data['laboratorioDestino'] as Map? ?? {};

    String clinicaNome = clinicaData['nome'] ?? data['clinicaNome'] ?? '';
    String clinicaId = clinicaData['id'] ?? data['clinicaId'] ?? '';

    final bool flagUrgencia =
        data['isEmergencia'] == true ||
        data['isUrgencia'] == true ||
        data['isUrgente'] == true ||
        data['urgente'] == true;

    return Coleta(
      id: doc.id,
      status: data['status'] ?? 'Aguardando',
      isUrgente: flagUrgencia,
      codigoAcompanhamento:
          data['codigoAcompanhamento'] ?? data['codigo'] ?? data['id'],
      isInsumo: ehInsumo,
      nomeLaboratorioOrigemTexto:
          data['laboratorioNome'] ?? data['laboratorioId'],
      dataSolicitacao: data['dataSolicitacao'] is Timestamp
          ? (data['dataSolicitacao'] as Timestamp).toDate()
          : (data['dataCriacao'] is Timestamp
                ? (data['dataCriacao'] as Timestamp).toDate()
                : null),
      itens: (data['itens'] as List?) ?? [],
      historico:
          (data['historico'] as List?) ??
          (data['historicoLogs'] as List?) ??
          [],

      clinicaOrigem: Clinica(
        id: clinicaId,
        nome: clinicaNome,
        email: clinicaData['email'] ?? '',
        telefone: clinicaData['telefone'] ?? '',
        cnpj: clinicaData['cnpj'] ?? '',
        endereco: Endereco.fromMap(
          clinicaData['endereco'] ?? data['enderecoOrigem'] ?? data['endereco'],
        ),
      ),

      laboratorioDestino: Laboratorio(
        id: labData['id'] ?? data['laboratorioId'] ?? '',
        nome: labData['nome'] ?? data['laboratorioNome'] ?? '',
        email: labData['email'] ?? '',
        telefone: labData['telefone'] ?? '',
        cnpj: labData['cnpj'] ?? '',
        endereco: Endereco.fromMap(
          labData['endereco'] ?? data['enderecoDestino'] ?? data['endereco'],
        ),
      ),

      entregador: data['entregador'] != null && data['entregador'] is Map
          ? Entregador.fromMap(data['entregador'] as Map<String, dynamic>)
          : null,

      latitudeOrigem: (data['latitudeOrigem'] as num?)?.toDouble(),
      longitudeOrigem: (data['longitudeOrigem'] as num?)?.toDouble(),
      latitudeDestino: (data['latitudeDestino'] as num?)?.toDouble(), // 💡 NOVO
      longitudeDestino: (data['longitudeDestino'] as num?)
          ?.toDouble(), // 💡 NOVO
    );
  }
}
