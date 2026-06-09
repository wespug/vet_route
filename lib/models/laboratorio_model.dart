// lib/models/laboratorio_model.dart

import 'endereco_model.dart';

class Laboratorio {
  final String id;
  final String nome;
  final String telefone;
  final Endereco endereco;

  Laboratorio({
    required this.id,
    required this.nome,
    required this.telefone,
    required this.endereco,
  });
}
