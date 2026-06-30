class PerfilAcesso {
  final String id;
  final String nome;
  final List<String> menusAcesso; // 💡 IDs dos menus permitidos
  final List<String> submenusAcesso; // 💡 IDs dos submenus permitidos

  PerfilAcesso({
    required this.id,
    required this.nome,
    this.menusAcesso = const [],
    this.submenusAcesso = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'menusAcesso': menusAcesso,
      'submenusAcesso': submenusAcesso,
    };
  }

  factory PerfilAcesso.fromFirestore(String id, Map<String, dynamic> data) {
    return PerfilAcesso(
      id: id,
      nome: data['nome'] ?? '',
      // 💡 Conversão segura de Listas do Firebase
      menusAcesso: data['menusAcesso'] != null
          ? List<String>.from(data['menusAcesso'])
          : [],
      submenusAcesso: data['submenusAcesso'] != null
          ? List<String>.from(data['submenusAcesso'])
          : [],
    );
  }
}
