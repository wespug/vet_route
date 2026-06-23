import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/models/perfil_usuario.dart';

class Administrador {
  final String? id;
  final String nome;
  final String email;
  final String telefone;

  Administrador({
    this.id,
    required this.nome,
    required this.email,
    required this.telefone,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'telefone': telefone,
      // ... dentro do método toMap()
      'perfil': PerfilUsuario
          .administrador
          .toFirestoreString, // 💡 Blindado // 💡 Essencial para o main.dart liberar o acesso Web
      'dataCadastro': FieldValue.serverTimestamp(),
    };
  }

  factory Administrador.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Administrador(
      id: doc.id,
      nome: data['nome'] ?? '',
      email: data['email'] ?? '',
      telefone: data['telefone'] ?? '',
    );
  }
}
