// lib/models/coleta_model.dart

import 'clinica_model.dart';
import 'laboratorio_model.dart';
import 'entregador_model.dart';

class Coleta {
  final String id;
  final Clinica clinicaOrigem;
  final Laboratorio laboratorioDestino;
  final Entregador?
  entregador; // '?' porque a coleta pode estar aguardando alguém aceitar
  final String status; // Ex: 'Aguardando', 'Em Rota', 'Entregue'

  Coleta({
    required this.id,
    required this.clinicaOrigem,
    required this.laboratorioDestino,
    this.entregador,
    this.status = 'Aguardando', // Valor padrão ao criar uma nova coleta
  });
}
