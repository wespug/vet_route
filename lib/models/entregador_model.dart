import 'package:cloud_firestore/cloud_firestore.dart';

class Entregador {
  final String? id;
  final String nome;
  final String email;
  final String telefone;
  final String veiculo;

  Entregador({
    this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.veiculo,
  });

  // O método que o Firebase usa
  factory Entregador.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Entregador.fromMap(data, id: doc.id);
  }

  // O método que resolve o erro do 'fromMap'
  factory Entregador.fromMap(Map<String, dynamic> map, {String? id}) {
    return Entregador(
      id: id,
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      telefone: map['telefone'] ?? '',
      veiculo: map['veiculo'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'veiculo': veiculo,
    };
  }
}
