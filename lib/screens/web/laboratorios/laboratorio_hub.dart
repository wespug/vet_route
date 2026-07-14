import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/controllers/permissoes_controller.dart';
import 'package:vet_route/models/laboratorio_model.dart';
import 'package:vet_route/models/submenu_item_model.dart';

import 'package:vet_route/screens/web/laboratorios/lista_laboratorio_view.dart';
import 'package:vet_route/screens/web/laboratorios/lab_dashboard_view.dart';
import 'package:vet_route/screens/web/laboratorios/cadastro_insumo.dart';
import 'package:vet_route/screens/web/laboratorios/usuarios_lab_view.dart';
import 'cadastro_exame_hub.dart';
import 'gestao_rotas_hub.dart';

class LaboratoriosHub extends StatefulWidget {
  final String? rotaAbaAtiva;

  const LaboratoriosHub({super.key, this.rotaAbaAtiva});

  @override
  State<LaboratoriosHub> createState() => _LaboratoriosHubState();
}

class _LaboratoriosHubState extends State<LaboratoriosHub>
    with TickerProviderStateMixin {
  Laboratorio? _labSelecionado;
  bool _isLoading = true;
  bool _isUsuarioRestrito = false;

  TabController? _tabController;
  List<SubmenuItemModel> _submenus = [];

  @override
  void initState() {
    super.initState();
    _verificarVinculoUsuario();
  }

  // 🚀 REATIVIDADE AO CLIQUE DO MENU LATERAL (Idêntico à Clínica)
  @override
  void didUpdateWidget(LaboratoriosHub oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rotaAbaAtiva != oldWidget.rotaAbaAtiva &&
        _tabController != null) {
      int newIndex = _submenus.indexWhere((s) => s.rota == widget.rotaAbaAtiva);
      if (newIndex != -1) {
        _tabController!.animateTo(newIndex);
      }
    }
  }

  Future<void> _verificarVinculoUsuario() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      if (!doc.exists) {
        setState(() => _isLoading = false);
        return;
      }

      final data = doc.data()!;
      final perfilId = data['perfilId'] as String?;
      final vinculoId = data['vinculoId'] as String?;

      if (perfilId != null) {
        final perfilDoc = await FirebaseFirestore.instance
            .collection('perfis')
            .doc(perfilId)
            .get();
        if (perfilDoc.exists && perfilDoc.data()?['nome'] == 'Super Admin') {
          _isUsuarioRestrito = false;
        } else {
          _isUsuarioRestrito = true;
        }
      }

      if (_isUsuarioRestrito && vinculoId != null && vinculoId.isNotEmpty) {
        final labDoc = await FirebaseFirestore.instance
            .collection('laboratorios')
            .doc(vinculoId)
            .get();
        if (labDoc.exists) {
          _labSelecionado = Laboratorio.fromFirestore(labDoc);
        }
      }

      _configurarAbasDinamicas();
    } catch (e) {
      debugPrint("Erro ao verificar vínculo do laboratório: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🧠 CONSTRUTOR DINÂMICO DE ABAS (LÊ DO FIRESTORE - Prefixo 'lab_')
  void _configurarAbasDinamicas() {
    _submenus = permissoesGlobais.submenusPermitidos
        .where((s) => s.isWeb && s.rota.startsWith('lab_'))
        .toList();

    // Respeita a ordem de peso configurada no Admin
    _submenus.sort((a, b) => a.peso.compareTo(b.peso));

    if (_submenus.isNotEmpty) {
      int initialIndex = 0;
      if (widget.rotaAbaAtiva != null) {
        initialIndex = _submenus.indexWhere(
          (s) => s.rota == widget.rotaAbaAtiva,
        );
        if (initialIndex == -1) initialIndex = 0;
      }
      _tabController = TabController(
        length: _submenus.length,
        initialIndex: initialIndex,
        vsync: this,
      );
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // 🔀 ROTEADOR INTERNO DAS ABAS DO LABORATÓRIO
  Widget _obterTelaParaRota(String rota) {
    if (_labSelecionado == null && rota != 'lista_laboratorios') {
      return const Center(
        child: Text(
          "Selecione um laboratório no topo para gerir.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    switch (rota) {
      case 'lab_dashboard':
        return const LabDashboardView(); // 💡 Dashboard atual
      case 'lab_adicionar_usuario':
      case 'lab_usuarios':
        return UsuariosLabView(
          labContexto: _labSelecionado!,
          chavePermissao: rota,
        );
      case 'lab_cadastro_exames':
        return CadastroExameHub(labContexto: _labSelecionado!);
      case 'lab_cadastro_insumos':
        return CadastroInsumoHub(labContexto: _labSelecionado!);
      case 'lab_gestao_rotas':
        return GestaoRotasHub(labContexto: _labSelecionado!);
      default:
        return _buildPlaceholder(rota);
    }
  }

  Widget _buildPlaceholder(String rota) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_rounded,
            size: 56,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "Funcionalidade ($rota) em desenvolvimento 🚧",
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.indigo),
      );
    }

    // 1. MODO SUPER ADMIN (SELEÇÃO DE EMPRESA)
    if (_labSelecionado == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: const Text(
              "Gestão de Laboratórios",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2959),
              ),
            ),
          ),
          Expanded(
            child: ListaLaboratoriosView(
              onLabSelected: (lab) {
                setState(() {
                  _labSelecionado = lab;
                });
              },
            ),
          ),
        ],
      );
    }

    // 2. MODO HUB BLOQUEADO (SEM PERMISSÕES)
    if (_submenus.isEmpty) {
      return const Center(
        child: Text(
          "Nenhum módulo de laboratório configurado para o seu perfil.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // 3. MODO HUB DINÂMICO (ABAS FUNCIONANDO IDÊNTICO À CLÍNICA)
    return Column(
      children: [
        _buildHeaderContexto(),
        Container(
          width: double.infinity,
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.indigo,
            unselectedLabelColor: Colors.grey.shade500,
            indicatorColor: Colors.indigo,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13.5,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
            tabs: _submenus.map((s) => Tab(text: s.titulo)).toList(),
          ),
        ),
        Expanded(
          child: Container(
            color: const Color(
              0xFFF5F7FA,
            ), // Fundo clean idêntico ao da clínica
            child: TabBarView(
              controller: _tabController,
              children: _submenus
                  .map((s) => _obterTelaParaRota(s.rota))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderContexto() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.science_outlined, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Laboratórios",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                _labSelecionado!.nome,
                style: const TextStyle(
                  color: Colors.indigo,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (!_isUsuarioRestrito)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _labSelecionado = null;
                });
              },
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: const Text(
                "Alternar Laboratório",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(foregroundColor: Colors.indigo),
            ),
        ],
      ),
    );
  }
}
