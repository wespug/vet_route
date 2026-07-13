import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/controllers/permissoes_controller.dart';
import 'package:vet_route/models/clinica_model.dart';
import 'package:vet_route/models/submenu_item_model.dart';
import 'package:vet_route/screens/web/clinicas/lista_clinicas_view.dart';
import 'package:vet_route/screens/web/clinicas/clinica_dashboard_view.dart';
import 'package:vet_route/screens/web/clinicas/gestao_chamados_view.dart';

// 🛠️ Importação EXATA do seu arquivo
import 'package:vet_route/screens/web/clinicas/clinica_usuario_view.dart';

class ClinicasHub extends StatefulWidget {
  final String? rotaAbaAtiva;

  const ClinicasHub({super.key, this.rotaAbaAtiva});

  @override
  State<ClinicasHub> createState() => _ClinicasHubState();
}

class _ClinicasHubState extends State<ClinicasHub>
    with TickerProviderStateMixin {
  Clinica? _clinicaSelecionada;
  bool _isLoading = true;
  bool _isUsuarioRestrito = false;

  TabController? _tabController;
  List<SubmenuItemModel> _submenus = [];

  @override
  void initState() {
    super.initState();
    _verificarVinculoUsuario();
  }

  // 🚀 REATIVIDADE AO CLIQUE DO MENU LATERAL
  @override
  void didUpdateWidget(ClinicasHub oldWidget) {
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
        final clinicaDoc = await FirebaseFirestore.instance
            .collection('clinicas')
            .doc(vinculoId)
            .get();
        if (clinicaDoc.exists) {
          _clinicaSelecionada = Clinica.fromFirestore(clinicaDoc);
        }
      }

      _configurarAbasDinamicas();
    } catch (e) {
      debugPrint("Erro ao verificar vínculo da clínica: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🧠 CONSTRUTOR DINÂMICO DE ABAS (LÊ DO FIRESTORE)
  void _configurarAbasDinamicas() {
    _submenus = permissoesGlobais.submenusPermitidos
        .where((s) => s.isWeb && s.rota.startsWith('clinica_'))
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

  // 🔀 ROTEADOR INTERNO DAS ABAS DA CLÍNICA
  Widget _obterTelaParaRota(String rota) {
    if (_clinicaSelecionada == null &&
        rota != 'clinica_gestao' &&
        rota != 'clinicas_lista') {
      return const Center(
        child: Text(
          "Selecione uma clínica no topo para gerir.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // 🛠️ CORREÇÃO: Passando clinicaContexto E chavePermissao e chamando a classe exata!
    switch (rota) {
      case 'clinica_dashboard':
        return ClinicaDashboardView(clinicaContexto: _clinicaSelecionada!);
      case 'clinica_gestao':
        return GestaoChamadosView(clinicaContexto: _clinicaSelecionada!);
      case 'clinica_adicionar_usuario':
      case 'clinica_usuarios':
        return UsuariosClinicaView(
          clinicaContexto: _clinicaSelecionada!,
          chavePermissao: rota, // 💡 O novo parâmetro que a classe exigia
        );
      case 'clinicas_lista':
        return ListaClinicasView(
          onClinicaSelected: (clinica) {
            setState(() {
              _clinicaSelecionada = clinica;
            });
          },
        );
      default:
        // Fallback Seguro Inteligente
        if (rota.contains('usuario')) {
          return UsuariosClinicaView(
            clinicaContexto: _clinicaSelecionada!,
            chavePermissao: rota,
          );
        }
        if (rota.contains('dashboard'))
          return ClinicaDashboardView(clinicaContexto: _clinicaSelecionada!);
        if (rota.contains('gestao') || rota.contains('chamado'))
          return GestaoChamadosView(clinicaContexto: _clinicaSelecionada!);

        return Center(
          child: Text(
            "Tela para a rota '$rota' não foi conectada no Hub da Clínica.",
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    // 1. MODO SUPER ADMIN (SELEÇÃO DE EMPRESA)
    if (_clinicaSelecionada == null) {
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
              "Gestão de Clínicas",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2959),
              ),
            ),
          ),
          Expanded(
            child: ListaClinicasView(
              onClinicaSelected: (clinica) {
                setState(() {
                  _clinicaSelecionada = clinica;
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
          "Nenhum módulo da clínica configurado para o seu perfil.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // 3. MODO HUB DINÂMICO (ABAS FUNCIONANDO)
    return Column(
      children: [
        _buildHeaderContexto(),
        Container(
          width: double.infinity,
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.grey.shade500,
            indicatorColor: Colors.teal,
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
            color: const Color(0xFFF5F7FA), // Fundo clean
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
              const Icon(
                Icons.local_hospital_outlined,
                color: Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                "Clínicas",
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
                _clinicaSelecionada!.nome,
                style: const TextStyle(
                  color: Colors.teal,
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
                  _clinicaSelecionada = null;
                });
              },
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: const Text(
                "Alternar Clínica",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(foregroundColor: Colors.teal),
            ),
        ],
      ),
    );
  }
}
