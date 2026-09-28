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
  final List<dynamic> itens;
  final List<dynamic> historico;

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
  });

  bool get isEmergencia => isUrgente;

  // 💡 CORRIGIDO: Nomes ajustados para origemVisual e destinoVisual
  String get origemVisual => isInsumo
      ? (laboratorioDestino.nome.isNotEmpty
            ? laboratorioDestino.nome
            : (nomeLaboratorioOrigemTexto ?? 'Laboratório'))
      : (clinicaOrigem.nome.isNotEmpty
            ? clinicaOrigem.nome
            : 'Clínica não informada');

  // 💡 CORRIGIDO: Nomes ajustados para origemVisual e destinoVisual

  String get destinoVisual => isInsumo
      ? (clinicaOrigem.nome.isNotEmpty
            ? clinicaOrigem.nome
            : 'Clínica não informada')
      : (laboratorioDestino.nome.isNotEmpty
            ? laboratorioDestino.nome
            : 'Laboratório não informado');

  String get enderecoOrigemVisual => isInsumo
      ? (laboratorioDestino.endereco.logradouro.isNotEmpty
            ? laboratorioDestino.endereco.logradouro
            : 'Sem endereço do Laboratorio Origem')
      : (clinicaOrigem.endereco.logradouro.isNotEmpty
            ? clinicaOrigem.endereco.logradouro
            : "Sem endereço da Clinica Origem");

  String get enderecoDestinoVisual => isInsumo
      ? (clinicaOrigem.endereco.logradouro.isNotEmpty
            ? clinicaOrigem.endereco.logradouro
            : "Sem endereço da Clinica Destino")
      : (laboratorioDestino.endereco.logradouro.isNotEmpty
            ? laboratorioDestino.endereco.logradouro
            : 'Sem endereço do Laboratorio Destino');

  String get nomeClinica => clinicaOrigem.nome;
  String get codigo => codigoAcompanhamento ?? id;
  DateTime? get dataCriacao => dataSolicitacao;

  String get idDoEntregador => entregador?.id ?? '';
  String get nomeDoEntregador => entregador?.nome ?? 'Aguardando Entregador';

  // 💡 CORRIGIDO: Método toMap() adicionado para suportar o Repository
  Map<String, dynamic> toMap() {
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
      'dataSolicitacao': dataSolicitacao != null
          ? Timestamp.fromDate(dataSolicitacao!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory Coleta.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final String collectionName = doc.reference.parent.path;

    final bool ehInsumo =
        collectionName.contains('pedidos_insumos') ||
        (data['codigoAcompanhamento'] != null &&
            data['codigoAcompanhamento'].toString().contains('INS')) ||
        data['itens'] != null ||
        data['possuiInsumo'] == true ||
        data['tipo']?.toString().toLowerCase() == 'insumo';

    final Map<String, dynamic> clinicaData =
        data['clinicaOrigem'] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> labData =
        data['laboratorioDestino'] as Map<String, dynamic>? ?? {};

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
      itens: (data['itens'] as List<dynamic>?) ?? [],
      historico:
          (data['historico'] as List<dynamic>?) ??
          (data['historicoLogs'] as List<dynamic>?) ??
          [],

      clinicaOrigem: Clinica(
        id: clinicaId,
        nome: clinicaNome,
        email: clinicaData['email'] ?? '',
        telefone: clinicaData['telefone'] ?? '',
        cnpj: clinicaData['cnpj'] ?? '',
        // 💡 BLINDAGEM DE TIPAGEM: Conversão segura do mapa aninhado
        endereco: Endereco.fromMap(
          Map.from(clinicaData['endereco'] as Map? ?? {}),
        ),
      ),

      laboratorioDestino: Laboratorio(
        id: labData['id'] ?? data['laboratorioId'] ?? '',
        nome: labData['nome'] ?? data['laboratorioNome'] ?? '',
        email: labData['email'] ?? '',
        telefone: labData['telefone'] ?? '',
        cnpj: labData['cnpj'] ?? '',
        // 💡 BLINDAGEM DE TIPAGEM: Conversão segura do mapa aninhado
        endereco: Endereco.fromMap(Map.from(labData['endereco'] as Map? ?? {})),
      ),

      entregador:
          data['entregador'] != null &&
              data['entregador'] is Map<String, dynamic>
          ? Entregador.fromMap(data['entregador'] as Map<String, dynamic>)
          : null,
    );
  }
}
