class PerfilAcesso {
  final String id;
  final String nome;

  PerfilAcesso({required this.id, required this.nome});

  // Converte o objeto para o formato que o Firestore entende
  Map<String, dynamic> toMap() {
    return {'nome': nome};
  }

  // Mapeia o documento vindo do Firestore de volta para a nossa classe
  factory PerfilAcesso.fromFirestore(String id, Map<String, dynamic> data) {
    return PerfilAcesso(id: id, nome: data['nome'] ?? '');
  }
}
