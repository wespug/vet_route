import 'package:cloud_firestore/cloud_firestore.dart';
import 'clinica_model.dart';
import 'laboratorio_model.dart';
import 'entregador_model.dart';
import 'endereco_model.dart';

class Coleta {
  final String id;
  final Clinica clinicaOrigem;
  final Laboratorio laboratorioDestino;
  final Entregador? entregador; // Nullable se estiver aguardando aceite
  final String status; // Ex: 'Aguardando', 'Em Rota', 'Entregue'
  final bool isUrgente;
  final String? codigoAcompanhamento;
  final DateTime? dataSolicitacao;

  Coleta({
    required this.id,
    required this.clinicaOrigem,
    required this.laboratorioDestino,
    this.entregador,
    this.status = 'Aguardando',
    this.isUrgente = false,
    this.codigoAcompanhamento,
    this.dataSolicitacao,
  });

  // 💡 Getters de conveniência para uso direto na View (evita erros de compilação)
  bool get isEmergencia => isUrgente;
  String get nomeClinica => clinicaOrigem.nome;
  String get codigo => codigoAcompanhamento ?? id;
  String get enderecoCompleto =>
      '${clinicaOrigem.endereco.logradouro}, ${clinicaOrigem.endereco.numero} - ${clinicaOrigem.endereco.bairro}';
  DateTime? get dataCriacao => dataSolicitacao;

  // 💡 Converte o objeto Coleta em Map para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'isUrgente': isUrgente,
      'codigoAcompanhamento': codigoAcompanhamento,
      'clinicaOrigem': clinicaOrigem.toMap(),
      'laboratorioDestino': laboratorioDestino.toMap(),
      'entregador': entregador?.toMap(),
      'dataSolicitacao': dataSolicitacao != null
          ? Timestamp.fromDate(dataSolicitacao!)
          : FieldValue.serverTimestamp(),
      'dataAtualizacao': FieldValue.serverTimestamp(),
    };
  }

  // 💡 Reconstrói o objeto Coleta a partir de um DocumentSnapshot do Firestore
  factory Coleta.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final Map<String, dynamic> clinicaData =
        data['clinicaOrigem'] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> labData =
        data['laboratorioDestino'] as Map<String, dynamic>? ?? {};

    return Coleta(
      id: doc.id,
      status: data['status'] ?? 'Aguardando',
      isUrgente: data['isUrgente'] ?? data['urgente'] ?? false,
      codigoAcompanhamento: data['codigoAcompanhamento'] ?? data['codigo'],
      dataSolicitacao: data['dataSolicitacao'] is Timestamp
          ? (data['dataSolicitacao'] as Timestamp).toDate()
          : null,

      // Reconstrói a Clínica
      clinicaOrigem: Clinica(
        id: clinicaData['id'] ?? '',
        nome: clinicaData['nome'] ?? '',
        email: clinicaData['email'] ?? '',
        telefone: clinicaData['telefone'] ?? '',
        cnpj: clinicaData['cnpj'] ?? '',
        endereco: Endereco.fromMap(
          clinicaData['endereco'] as Map<String, dynamic>? ?? {},
        ),
      ),

      // Reconstrói o Laboratório
      laboratorioDestino: Laboratorio(
        id: labData['id'] ?? '',
        nome: labData['nome'] ?? '',
        email: labData['email'] ?? '',
        telefone: labData['telefone'] ?? '',
        cnpj: labData['cnpj'] ?? '',
        endereco: Endereco.fromMap(
          labData['endereco'] as Map<String, dynamic>? ?? {},
        ),
      ),

      // Trata o entregador condicionalmente
      entregador: data['entregador'] != null
          ? Entregador.fromMap(data['entregador'] as Map<String, dynamic>)
          : null,
    );
  }
}
