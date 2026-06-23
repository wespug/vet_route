import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/models/perfil_usuario.dart';
import 'endereco_model.dart'; // 💡 Importamos o novo modelo

class Clinica {
  final String? id;
  final String nome;
  final String email;
  final String telefone;
  final String cnpj;
  final Endereco endereco; // 💡 Agora é fortemente tipado!

  Clinica({
    this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.cnpj,
    required this.endereco,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'cnpj': cnpj,
      'perfil': PerfilUsuario.clinica.toFirestoreString,
      'endereco': endereco
          .toMap(), // 💡 Delega a serialização para a classe Endereco
      'dataCadastro': FieldValue.serverTimestamp(),
    };
  }

  factory Clinica.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Clinica(
      id: doc.id,
      nome: data['nome'] ?? '',
      email: data['email'] ?? '',
      telefone: data['telefone'] ?? '',
      cnpj: data['cnpj'] ?? '',
      // 💡 Transforma o map do Firestore de volta no objeto Endereco
      endereco: Endereco.fromMap(
        data['endereco'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}
