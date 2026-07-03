import 'package:cloud_firestore/cloud_firestore.dart';

class PerfilAcesso {
  final String id; // Mantido como String não-nula (Padrão da sua arquitetura)
  final String nome;
  final String descricao; // 💡 NOVO: Para a interface de gestão
  final bool ativo; // 💡 NOVO: Para bloquear/desbloquear perfis no futuro
  final List<String> menusAcesso;
  final List<String> submenusAcesso;
  final bool visivelWeb; // 💡 Mantido: Chave Mestra Web
  final bool visivelApp; // 💡 Mantido: Chave Mestra Mobile
  final List<String>
  exibirEm; // 💡 NOVO: A nossa Regra Mestre de Módulos (Data-Driven)

  PerfilAcesso({
    this.id =
        '', // 💡 Passou a ter fallback vazio para não quebrar na criação de novos perfis
    required this.nome,
    this.descricao = '',
    this.ativo = true,
    this.menusAcesso = const [],
    this.submenusAcesso = const [],
    this.visivelWeb = false,
    this.visivelApp = false,
    this.exibirEm = const [], // 💡 Inicializa vazio
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'descricao': descricao,
      'ativo': ativo,
      'menusAcesso': menusAcesso,
      'submenusAcesso': submenusAcesso,
      'visivelWeb': visivelWeb,
      'visivelApp': visivelApp,
      'exibirEm': exibirEm, // 💡 Persistindo a nova regra
    };
  }

  factory PerfilAcesso.fromFirestore(String id, Map<String, dynamic> data) {
    return PerfilAcesso(
      id: id,
      nome: data['nome'] ?? '',
      descricao: data['descricao'] ?? '',
      ativo: data['ativo'] ?? true,
      visivelWeb: data['visivelWeb'] ?? false,
      visivelApp: data['visivelApp'] ?? false,
      menusAcesso: data['menusAcesso'] != null
          ? List<String>.from(data['menusAcesso'])
          : [],
      submenusAcesso: data['submenusAcesso'] != null
          ? List<String>.from(data['submenusAcesso'])
          : [],
      exibirEm: data['exibirEm'] != null
          ? List<String>.from(data['exibirEm'])
          : [], // 💡 Lendo a nova regra
    );
  }
}
