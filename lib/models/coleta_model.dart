import 'package:cloud_firestore/cloud_firestore.dart';
import 'clinica_model.dart';
import 'laboratorio_model.dart';
import 'entregador_model.dart';
import 'endereco_model.dart';

class Coleta {
  final String id;
  final Clinica clinicaOrigem;
  final Laboratorio laboratorioDestino;
  final Entregador? entregador; // Objeto completo (se a rota antiga enviar)
  final String? entregadorIdFlat; // 💡 Campo NoSQL Plano (Sem Gambiarra)
  final String? entregadorNomeFlat; // 💡 Campo NoSQL Plano (Sem Gambiarra)
  final String status;
  final bool isUrgente;
  final String? codigoAcompanhamento;
  final DateTime? dataSolicitacao;
  final String? enderecoFlat;

  Coleta({
    required this.id,
    required this.clinicaOrigem,
    required this.laboratorioDestino,
    this.entregador,
    this.entregadorIdFlat,
    this.entregadorNomeFlat,
    this.status = 'Aguardando',
    this.isUrgente = false,
    this.codigoAcompanhamento,
    this.dataSolicitacao,
    this.enderecoFlat,
  });

  bool get isEmergencia => isUrgente;
  String get nomeClinica =>
      clinicaOrigem.nome.isNotEmpty ? clinicaOrigem.nome : 'Clínica Parceira';
  String get codigo => codigoAcompanhamento ?? id;

  // 💡 GETTERS INTELIGENTES: Lê do objeto completo se existir, senão lê do campo plano!
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

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'isUrgente': isUrgente,
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
    };
  }

  factory Coleta.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // 1. Mapeamento Inteligente da Clínica
    final Map<String, dynamic> clinicaData =
        data['clinicaOrigem'] as Map<String, dynamic>? ?? {};
    final String clinicaId = clinicaData['id'] ?? data['clinicaId'] ?? '';
    final String clinicaNome =
        clinicaData['nome'] ?? data['clinicaNome'] ?? 'Clínica Parceira';

    // 2. Mapeamento do Laboratório
    final Map<String, dynamic> labData =
        data['laboratorioDestino'] as Map<String, dynamic>? ?? {};
    final String labId = labData['id'] ?? data['laboratorioId'] ?? '';
    final String labNome =
        labData['nome'] ?? data['laboratorioNome'] ?? 'Laboratório Parceiro';

    // 3. Mapeamento do Entregador (SEM GAMBIARRAS)
    // Lê o objeto real apenas se ele vier completo do banco.
    final Map<String, dynamic>? entregadorMap =
        data['entregador'] as Map<String, dynamic>?;
    Entregador? objEntregador;

    if (entregadorMap != null) {
      try {
        objEntregador = Entregador.fromMap(entregadorMap);
      } catch (e) {
        // Se a rota antiga mandar um objeto quebrado, não trava o app
      }
    }

    // 4. Mapeamento de Datas
    DateTime? dataParseada;
    if (data['dataSolicitacao'] is Timestamp) {
      dataParseada = (data['dataSolicitacao'] as Timestamp).toDate();
    } else if (data['dataCriacao'] is Timestamp) {
      dataParseada = (data['dataCriacao'] as Timestamp).toDate();
    } else if (data['atualizadoEm'] is Timestamp) {
      dataParseada = (data['atualizadoEm'] as Timestamp).toDate();
    }

    return Coleta(
      id: doc.id,
      status: data['status'] ?? 'Aguardando',
      isUrgente: data['isUrgente'] ?? data['urgente'] ?? false,
      codigoAcompanhamento: data['codigoAcompanhamento'] ?? data['codigo'],
      dataSolicitacao: dataParseada,
      enderecoFlat: data['enderecoCompleto'] ?? data['endereco'],

      entregador: objEntregador,
      entregadorIdFlat: data['entregadorId'], // Guarda a string pura
      entregadorNomeFlat: data['nomeEntregador'], // Guarda a string pura

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
