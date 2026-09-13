import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/models/perfil_usuario.dart';
import 'endereco_model.dart';
import 'veiculo_model.dart';

class Entregador {
  final String? id;
  final String nome;
  final String email;
  final String telefone;
  final Veiculo? veiculo;
  final Endereco endereco;
  final String? senha;
  final String?
  perfilId; // 💡 NOVO: Vínculo dinâmico com a matriz de permissões

  Entregador({
    this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    this.veiculo,
    required this.endereco,
    this.senha,
    this.perfilId,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'veiculo': veiculo?.toMap(),
      'perfilId': perfilId, // 💡 Gravando o perfil real no Firebase
      'perfil': PerfilUsuario.entregadores.toFirestoreString, // Fallback legado
      'endereco': endereco.toMap(),
      'dataCadastro': FieldValue.serverTimestamp(),
    };
  }

  factory Entregador.fromMap(Map<String, dynamic> map, {String? id}) {
    return Entregador(
      id: id,
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      telefone: map['telefone'] ?? '',
      perfilId: map['perfilId'],
      veiculo: map['veiculo'] != null
          ? Veiculo.fromMap(map['veiculo'] as Map<String, dynamic>)
          : null,
      endereco: Endereco.fromMap(
        map['endereco'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  factory Entregador.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Entregador.fromMap(data, id: doc.id);
  }
}
