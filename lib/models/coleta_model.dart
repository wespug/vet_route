import 'package:cloud_firestore/cloud_firestore.dart';
import 'clinica_model.dart';
import 'laboratorio_model.dart';
import 'entregador_model.dart';
import 'endereco_model.dart';

class Coleta {
  final String id;
  final Clinica clinicaOrigem;
  final Laboratorio laboratorioDestino;
  final Entregador?
  entregador; // Nullable porque a coleta pode estar aguardando aceite
  final String status; // Ex: 'Aguardando', 'Em Rota', 'Entregue'

  Coleta({
    required this.id,
    required this.clinicaOrigem,
    required this.laboratorioDestino,
    this.entregador,
    this.status = 'Aguardando',
  });

  // 💡 Converte o objeto Coleta completo em um Map para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'clinicaOrigem': clinicaOrigem.toMap(),
      'laboratorioDestino': laboratorioDestino.toMap(),
      'entregador': entregador
          ?.toMap(), // Executa apenas se o entregador não for nulo
      'dataAtualizacao': FieldValue.serverTimestamp(),
    };
  }

  // 💡 Reconstrói o objeto Coleta a partir de um DocumentSnapshot do Firestore
  factory Coleta.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Coleta(
      id: doc.id,
      status: data['status'] ?? 'Aguardando',

      // Reconstrói a Clínica a partir do mapa interno embutido no documento
      clinicaOrigem: Clinica(
        id: data['clinicaOrigem']['id'] ?? '',
        nome: data['clinicaOrigem']['nome'] ?? '',
        email: data['clinicaOrigem']['email'] ?? '',
        telefone: data['clinicaOrigem']['telefone'] ?? '',
        cnpj: data['clinicaOrigem']['cnpj'] ?? '',
        endereco: Endereco.fromMap(
          data['clinicaOrigem']['endereco'] as Map<String, dynamic>? ?? {},
        ),
      ),

      // Reconstrói o Laboratório a partir do mapa interno embutido no documento
      laboratorioDestino: Laboratorio(
        id: data['laboratorioDestino']['id'] ?? '',
        nome: data['laboratorioDestino']['nome'] ?? '',
        email: data['laboratorioDestino']['email'] ?? '',
        telefone: data['laboratorioDestino']['telefone'] ?? '',
        cnpj: data['laboratorioDestino']['cnpj'] ?? '',
        endereco: Endereco.fromMap(
          data['laboratorioDestino']['endereco'] as Map<String, dynamic>? ?? {},
        ),
      ),

      // Trata o entregador de forma condicional se ele houver assumido a corrida
      entregador: data['entregador'] != null
          ? Entregador.fromMap(data['entregador'] as Map<String, dynamic>)
          : null,
    );
  }
}
