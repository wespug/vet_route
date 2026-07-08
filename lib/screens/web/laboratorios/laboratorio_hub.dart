import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/controllers/permissoes_controller.dart';
import 'package:vet_route/screens/web/laboratorios/usu%C3%A1rios_lab_view.dart';
import 'package:vet_route/screens/widgets/generic_tab_hub.dart';
import 'package:vet_route/models/laboratorio_model.dart';
import 'package:vet_route/screens/web/laboratorios/lista_laboratorio_view.dart';
import 'package:vet_route/screens/web/laboratorios/lab_dashboard_view.dart';

class LaboratoriosHub extends StatefulWidget {
  const LaboratoriosHub({super.key});

  @override
  State<LaboratoriosHub> createState() => _LaboratoriosHubState();
}

class _LaboratoriosHubState extends State<LaboratoriosHub> {
  Laboratorio? _labSelecionado;
  bool _isLoading = true; // 🔒 Bloqueia o vazamento de dados na inicialização
  bool _isUsuarioRestrito = false; // 🔒 Controla a exibição do botão voltar

  @override
  void initState() {
    super.initState();
    _verificarVinculoUsuario();
  }

  // 🛡️ CATRACA DE SEGURANÇA MULTI-TENANT PARA LABORATÓRIOS
  Future<void> _verificarVinculoUsuario() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 1. Busca o perfil do usuário logado diretamente na fonte
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      final userData = userDoc.data();

      // 2. Verifica se ele possui um vínculo com algum Laboratório
      if (userData != null &&
          userData.containsKey('vinculoId') &&
          userData['vinculoId'] != null &&
          userData['vinculoId'].toString().isNotEmpty) {
        final vinculoId = userData['vinculoId'];

        // 3. Busca na nuvem as informações reais deste laboratório específico
        final laboratorioDoc = await FirebaseFirestore.instance
            .collection('laboratorios')
            .doc(vinculoId)
            .get();

        if (laboratorioDoc.exists) {
          setState(() {
            // Injeta o laboratório diretamente no chassi da view usando o fromFirestore do modelo
            _labSelecionado = Laboratorio.fromFirestore(laboratorioDoc);
            _isUsuarioRestrito = true; // Isola o operador impedindo bypass
          });
        }
      }
    } catch (e) {
      debugPrint("Erro Crítico de Segurança no Hub de Labs: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _resolverConteudoDaAba(String rotaSubmenu) {
    switch (rotaSubmenu) {
      case 'lab_dashboard':
        return const LabDashboardView();

      case 'lab_adicionar_usuario':
        return UsuariosLabView(
          labContexto: _labSelecionado!,
          chavePermissao: 'lista_laboratorios',
        );

      default:
        return _buildPlaceholder(
          'Funcionalidade ($rotaSubmenu) configurada na gestão, mas em desenvolvimento 🚧',
          Icons.construction_rounded,
        );
    }
  }

  Widget _buildPlaceholder(String texto, IconData icone) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            texto,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ⏳ Trava de renderização enquanto o banco de dados responde
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.indigo),
      );
    }

    // 📊 NENHUM LABORATÓRIO SELECIONADO (Apenas Admins Globais chegam aqui)
    if (_labSelecionado == null) {
      return ListaLaboratoriosView(
        onLabSelected: (lab) {
          setState(() {
            _labSelecionado = lab;
          });
        },
      );
    }

    // 🔬 LABORATÓRIO ATIVO (Visão corporativa filtrada na nuvem)
    return ListenableBuilder(
      listenable: permissoesGlobais,
      builder: (context, child) {
        final menusFiltrados = permissoesGlobais.menusPermitidos.where(
          (m) => m.rota == 'lista_laboratorios',
        );

        if (menusFiltrados.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.indigo),
          );
        }

        final menuPai = menusFiltrados.first;
        final submenus = permissoesGlobais.getSubmenusDoMenu(menuPai.id);

        final submenusFiltrados = submenus
            .where((s) => s.rota != 'lista_laboratorios_aba')
            .toList();

        if (submenusFiltrados.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBarraTopoBreadcrumb(),
                const SizedBox(height: 40),
                const Center(
                  child: Text(
                    "Nenhum submenu ou aba complementar configurada para este módulo no Firestore.",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }

        submenusFiltrados.sort((a, b) => a.peso.compareTo(b.peso));

        final abasDinamicas = submenusFiltrados.map((submenu) {
          return TabItemModel(
            titulo: submenu.titulo,
            conteudo: _resolverConteudoDaAba(submenu.rota),
          );
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBarraTopoBreadcrumb(),
            const SizedBox(height: 16),
            Expanded(child: GenericTabHub(abas: abasDinamicas)),
          ],
        );
      },
    );
  }

  Widget _buildBarraTopoBreadcrumb() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
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
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
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
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // 🔒 Se for operador vinculado, removemos o controle de fuga para a listagem master global
          if (!_isUsuarioRestrito)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _labSelecionado = null;
                });
              },
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text(
                "Voltar para Lista",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(foregroundColor: Colors.indigo),
            ),
        ],
      ),
    );
  }
}
