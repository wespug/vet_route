import 'package:cloud_firestore/cloud_firestore.dart';

class UsuarioModel {
  final String id;
  final String nome;
  final String email;
  final String perfil;
  final String?
  vinculoId; // Para amarrar o usuário a uma clínica/laboratório específica
  final DateTime? dataCadastro;

  UsuarioModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.perfil,
    this.vinculoId,
    this.dataCadastro,
  });

  // MÁGICA 1: Transforma o mapa que vem do Firestore em um Objeto seguro no Dart
  factory UsuarioModel.fromFirestore(DocumentSnapshot doc) {
    final dados = doc.data() as Map<String, dynamic>? ?? {};

    return UsuarioModel(
      id: doc.id,
      nome: dados['nome'] ?? '',
      email: dados['email'] ?? '',
      perfil: dados['perfil'] ?? 'Clínica',
      vinculoId: dados['vinculoId'],
      dataCadastro: (dados['dataCadastro'] as Timestamp?)?.toDate(),
    );
  }

  // MÁGICA 2: Transforma o nosso objeto Dart em um mapa para salvar no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'email': email,
      'perfil': perfil,
      'vinculoId': vinculoId,
      'dataCadastro': dataCadastro != null
          ? Timestamp.fromDate(dataCadastro!)
          : FieldValue.serverTimestamp(),
    };
  }
}
