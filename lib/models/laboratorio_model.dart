import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/models/perfil_usuario.dart';
import 'endereco_model.dart'; // 💡 Reaproveitando o nosso modelo universal

class Laboratorio {
  final String? id;
  final String nome;
  final String email;
  final String telefone;
  final String cnpj;
  final Endereco endereco; // 💡 Fortemente tipado com o padrão unificado

  Laboratorio({
    this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.cnpj,
    required this.endereco,
  });

  // Transforma o objeto Laboratório em Map para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'cnpj': cnpj,
      'perfil': PerfilUsuario.laboratorio.toFirestoreString,
      'endereco': endereco
          .toMap(), // 💡 Delega a conversão para a classe Endereco
      'dataCadastro': FieldValue.serverTimestamp(),
    };
  }

  // Reconstrói o objeto Laboratório a partir dos dados brutos do Firestore
  factory Laboratorio.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Laboratorio(
      id: doc.id,
      nome: data['nome'] ?? '',
      email: data['email'] ?? '',
      telefone: data['telefone'] ?? '',
      cnpj: data['cnpj'] ?? '',
      // 💡 Transforma o nó 'endereco' do Firestore diretamente no nosso objeto tipado
      endereco: Endereco.fromMap(
        data['endereco'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}
