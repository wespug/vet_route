// lib/models/clinica_model.dart

import 'endereco_model.dart';

class Clinica {
  final String id;
  final String nome;
  final String telefone;
  final Endereco endereco;

  Clinica({
    required this.id,
    required this.nome,
    required this.telefone,
    required this.endereco,
  });
}
