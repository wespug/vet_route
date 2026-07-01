class UsuarioModel {
  final String id;
  final String nome;
  final String email;
  final String perfilId;
  final String? vinculoId; // 💡 O SEGREDO DO NEGÓCIO ESTÁ AQUI
  final bool ativo;

  UsuarioModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.perfilId,
    this.vinculoId,
    this.ativo = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'perfilId': perfilId,
      'vinculoId': vinculoId,
      'ativo': ativo,
    };
  }

  factory UsuarioModel.fromFirestore(String id, Map<String, dynamic> data) {
    return UsuarioModel(
      id: id,
      nome: data['nome'] ?? '',
      email: data['email'] ?? '',
      perfilId: data['perfilId'] ?? '',
      vinculoId: data['vinculoId'],
      ativo: data['ativo'] ?? true,
    );
  }
}
