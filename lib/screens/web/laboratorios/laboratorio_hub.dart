import 'package:flutter/material.dart';
import 'package:vet_route/controllers/permissoes_controller.dart';
import 'package:vet_route/screens/web/laboratorios/usu%C3%A1rios_lab_view.dart';
import 'package:vet_route/screens/widgets/generic_tab_hub.dart';
import 'package:vet_route/models/laboratorio_model.dart';

// 💡 IMPORTS BLINDADOS: Apontando exclusivamente para as duas visões definitivas do fluxo Mestre-Detalhe!
import 'package:vet_route/screens/web/laboratorios/lista_laboratorio_view.dart';

// Telas adicionais do módulo
import 'package:vet_route/screens/web/laboratorios/lab_dashboard_view.dart';

class LaboratoriosHub extends StatefulWidget {
  const LaboratoriosHub({super.key});

  @override
  State<LaboratoriosHub> createState() => _LaboratoriosHubState();
}

class _LaboratoriosHubState extends State<LaboratoriosHub> {
  // Coordenador de estado da UX Mestre-Detalhe
  Laboratorio? _labSelecionado;

  // 💡 CENTRALIZADOR DE COMPONENTES DO SUBMENU
  // Vincula milimetricamente as chaves cadastradas no seu Firestore com a View real correspondente
  Widget _resolverConteudoDaAba(String rotaSubmenu) {
    switch (rotaSubmenu) {
      case 'lab_dashboard':
        return const LabDashboardView();

      case 'lab_adicionar_usuario':
        // 🟢 INJEÇÃO CRUCIAL E CORRETA: Agora chama a UsuariosLabView passando a chave de permissão
        return UsuariosLabView(
          labContexto: _labSelecionado!,
          chavePermissao:
              'lista_laboratorios', // 💡 AQUI ESTÁ A CORREÇÃO! A chave foi injetada!
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
    // 📊 CENÁRIO 1: NENHUM LABORATÓRIO SELECIONADO -> EXIBE A TABELA MASTER GLOBAL
    if (_labSelecionado == null) {
      return ListaLaboratoriosView(
        onLabSelected: (lab) {
          setState(() {
            _labSelecionado = lab;
          });
        },
      );
    }

    // 🔬 CENÁRIO 2: LABORATÓRIO ATIVO -> MONTA O PRODUTO SAAS DINÂMICO BASEADO EM DADOS
    return ListenableBuilder(
      listenable: permissoesGlobais,
      builder: (context, child) {
        // Encontra o Menu Mestre de Laboratórios para isolar seus submenus
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

        // Filtro arquitetural: Remove a listagem geral dos submenus superiores (pois já passamos por ela)
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

        // Aplica a ordenação por peso definida na Gestão de Menus
        submenusFiltrados.sort((a, b) => a.peso.compareTo(b.peso));

        // Converte os dados reais em abas injetáveis para o nosso componente mestre genérico
        final abasDinamicas = submenusFiltrados.map((submenu) {
          return TabItemModel(
            titulo: submenu.titulo,
            conteudo: _resolverConteudoDaAba(submenu.rota),
          );
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra de Navegação Contextual Sênior (Breadcrumb)
            _buildBarraTopoBreadcrumb(),
            const SizedBox(height: 16),

            // 🚀 EXECUTANDO O SEU COMPONENTE REUTILIZÁVEL MESTRE COM AS VIEWS CORRETAS INSCRITAS!
            Expanded(child: GenericTabHub(abas: abasDinamicas)),
          ],
        );
      },
    );
  }

  // 💡 Componente Visual Breadcrumb para Destravar e Voltar o Contexto Mestre
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
                    null; // Reseta o estado e o chassi força o retorno à listagem
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
