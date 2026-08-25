import 'package:cloud_firestore/cloud_firestore.dart';
import 'endereco_model.dart';

class Clinica {
  final String id;
  final String nome;
  final String cnpj;
  final String email;
  final String telefone;
  final Endereco endereco;

  Clinica({
    this.id = '',
    required this.nome,
    required this.cnpj,
    this.email = '',
    this.telefone = '',
    Endereco? endereco,
  }) : endereco = endereco ?? Endereco();

  factory Clinica.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Clinica.fromMap(data, id: doc.id);
  }

  factory Clinica.fromMap(Map<String, dynamic> map, {String id = ''}) {
    return Clinica(
      id: id.isNotEmpty ? id : (map['id'] ?? ''),
      nome: map['nome'] ?? '',
      cnpj: map['cnpj'] ?? '',
      email: map['email'] ?? '',
      telefone: map['telefone'] ?? '',
      endereco: Endereco.fromMap(
        map['endereco'] is Map<String, dynamic> ? map['endereco'] : null,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'cnpj': cnpj,
      'email': email,
      'telefone': telefone,
      'endereco': endereco.toMap(),
    };
  }
}
