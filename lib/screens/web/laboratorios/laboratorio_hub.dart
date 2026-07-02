import 'package:flutter/material.dart';
import 'package:vet_route/controllers/permissoes_controller.dart';
import 'package:vet_route/screens/web/laboratorios/lab_dashboard_view.dart';
import 'package:vet_route/screens/web/laboratorios/lista_laboratorio_view.dart';
import 'package:vet_route/screens/widgets/generic_tab_hub.dart';

class LaboratoriosHub extends StatelessWidget {
  const LaboratoriosHub({super.key});

  // 💡 MAPEAMENTO DE CHAVES DE SUBMENU DO FIRESTORE
  Widget _resolverConteudoDaAba(String rotaSubmenu) {
    switch (rotaSubmenu) {
      case 'lab_dashboard': // 🔗 Rota que você vai cadastrar para o Dashboard!
        return const LabDashboardView();
      case 'lista_laboratorios_aba': // 🔗 Rota para ver a tabela de laboratórios!
        return const ListaLaboratoriosView();
      case 'lab_adicionar_usuario':
        return _buildPlaceholder(
          'Formulário de Criação de Usuários de Laboratório 👤',
          Icons.person_add_alt_1_rounded,
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
    return ListenableBuilder(
      listenable: permissoesGlobais,
      builder: (context, child) {
        // 1. Localiza o Menu Pai de Laboratórios para isolar seus filhos
        final menusFiltrados = permissoesGlobais.menusPermitidos.where(
          (m) => m.rota == 'lista_laboratorios',
        );

        if (menusFiltrados.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blue),
          );
        }

        final menuPai = menusFiltrados.first;

        // 2. Captura a lista de submenus injetados dinamicamente via Firestore
        final submenus = permissoesGlobais.getSubmenusDoMenu(menuPai.id);

        if (submenus.isEmpty) {
          return const Center(
            child: Text(
              "Nenhum submenu ativo. Configure as abas na tela de Gestão de Submenus.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        // 3. Aplica a Ordenação por Peso definida por você no banco!
        submenus.sort((a, b) => a.peso.compareTo(b.peso));

        // 4. Monta a lista de abas finais de forma limpa para o Hub Genérico
        final abasDinamicas = submenus.map((submenu) {
          return TabItemModel(
            titulo: submenu.titulo,
            conteudo: _resolverConteudoDaAba(submenu.rota),
          );
        }).toList();

        return GenericTabHub(abas: abasDinamicas);
      },
    );
  }
}
