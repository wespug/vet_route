import 'package:flutter/material.dart';
import 'package:vet_route/controllers/permissoes_controller.dart';
import 'package:vet_route/screens/web/laboratorios/view/adicionar_usuario_lab_view.dart';
import 'package:vet_route/screens/widgets/generic_tab_hub.dart';
import 'package:vet_route/models/laboratorio_model.dart';

// 💡 IMPORTS CORRIGIDOS: Sem a pasta 'views' e com o nome no singular!
// Certifique-se de que estes 3 arquivos estejam na mesma pasta (lib/screens/web/laboratorios/)
import 'package:vet_route/screens/web/laboratorios/lista_laboratorio_view.dart';
import 'package:vet_route/screens/web/laboratorios/lab_dashboard_view.dart';

class LaboratoriosHub extends StatefulWidget {
  const LaboratoriosHub({super.key});

  @override
  State<LaboratoriosHub> createState() => _LaboratoriosHubState();
}

class _LaboratoriosHubState extends State<LaboratoriosHub> {
  // 💡 O Coração da Nova UX: Controla qual laboratório está sob gestão ativa
  Laboratorio? _labSelecionado;

  // 💡 MAPEAMENTO DINÂMICO DE CHAVES DE SUBMENU DO FIRESTORE
  Widget _resolverConteudoDaAba(String rotaSubmenu) {
    switch (rotaSubmenu) {
      case 'lab_dashboard':
        return const LabDashboardView();
      case 'lab_adicionar_usuario':
        // Passamos o laboratório selecionado para a tela já nascer com ele travado/pré-selecionado!
        return AdicionarUsuarioLabView(labContexto: _labSelecionado);
      default:
        return _buildPlaceholder(
          'Funcionalidade ($rotaSubmenu) em desenvolvimento 🚧',
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
    // 📊 CENÁRIO 1: NENHUM LABORATÓRIO SELECIONADO -> MOSTRA A LISTAGEM GLOBAL
    if (_labSelecionado == null) {
      return ListaLaboratoriosView(
        onLabSelected: (lab) {
          setState(() {
            _labSelecionado = lab;
          });
        },
      );
    }

    // 🔬 CENÁRIO 2: LABORATÓRIO SELECIONADO -> EXIBE O HUB DE SUBMENUS CONTEXTUALIZADO
    return ListenableBuilder(
      listenable: permissoesGlobais,
      builder: (context, child) {
        final menusFiltrados = permissoesGlobais.menusPermitidos.where(
          (m) => m.rota == 'lista_laboratorios',
        );

        if (menusFiltrados.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blue),
          );
        }

        final menuPai = menusFiltrados.first;
        final submenus = permissoesGlobais.getSubmenusDoMenu(menuPai.id);

        // Removemos o submenu de listagem se ele vier do banco, pois já passamos por ele
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
                    "Nenhuma aba operacional (ex: Dashboard, Usuários) liberada para o seu perfil no Firestore.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        }

        // Ordenação por Peso do Firebase
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
            // Cabeçalho de Navegação (Breadcrumb + Botão Voltar)
            _buildBarraTopoBreadcrumb(),
            const SizedBox(height: 16),
            // Renderiza as abas dinamicamente
            Expanded(child: GenericTabHub(abas: abasDinamicas)),
          ],
        );
      },
    );
  }

  // 💡 Componente Visual Sênior de Navegação e Contexto
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
          TextButton.icon(
            onPressed: () {
              setState(() {
                _labSelecionado =
                    null; // Zera o estado e o chassi volta para a lista global!
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
