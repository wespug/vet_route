class PerfilAcesso {
  final String id;
  final String nome;
  final List<String> menusAcesso;
  final List<String> submenusAcesso;
  final bool visivelWeb; // 💡 NOVO: Chave Mestra Web
  final bool visivelApp; // 💡 NOVO: Chave Mestra Mobile

  PerfilAcesso({
    required this.id,
    required this.nome,
    this.menusAcesso = const [],
    this.submenusAcesso = const [],
    this.visivelWeb = false,
    this.visivelApp = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'menusAcesso': menusAcesso,
      'submenusAcesso': submenusAcesso,
      'visivelWeb': visivelWeb, // 💡 Persistindo
      'visivelApp': visivelApp, // 💡 Persistindo
    };
  }

  factory PerfilAcesso.fromFirestore(String id, Map<String, dynamic> data) {
    return PerfilAcesso(
      id: id,
      nome: data['nome'] ?? '',
      visivelWeb:
          data['visivelWeb'] ?? false, // 💡 Lendo (fallback de segurança)
      visivelApp:
          data['visivelApp'] ?? false, // 💡 Lendo (fallback de segurança)
      menusAcesso: data['menusAcesso'] != null
          ? List<String>.from(data['menusAcesso'])
          : [],
      submenusAcesso: data['submenusAcesso'] != null
          ? List<String>.from(data['submenusAcesso'])
          : [],
    );
  }
}
