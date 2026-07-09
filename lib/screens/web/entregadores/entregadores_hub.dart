import 'package:flutter/material.dart';
import 'package:vet_route/controllers/permissoes_controller.dart';
import 'package:vet_route/screens/widgets/generic_tab_hub.dart';
import 'package:vet_route/models/entregador_model.dart';
import 'package:vet_route/screens/web/entregadores/lista_entregadores_view.dart';
import 'package:vet_route/screens/web/entregadores/entregador_dashboard_view.dart';

class EntregadoresHub extends StatefulWidget {
  final String? rotaAbaAtiva; // 💡 NOVO: Parâmetro Deep Link

  const EntregadoresHub({super.key, this.rotaAbaAtiva});

  @override
  State<EntregadoresHub> createState() => _EntregadoresHubState();
}

class _EntregadoresHubState extends State<EntregadoresHub> {
  Entregador? _entregadorSelecionado;

  Widget _resolverConteudoDaAba(String rotaSubmenu) {
    switch (rotaSubmenu) {
      case 'entregador_dashboard':
        return EntregadorDashboardView(
          entregadorContexto: _entregadorSelecionado!,
        );

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
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_entregadorSelecionado == null) {
      return ListaEntregadoresView(
        onEntregadorSelected: (entregador) {
          setState(() {
            _entregadorSelecionado = entregador;
          });
        },
      );
    }

    return ListenableBuilder(
      listenable: permissoesGlobais,
      builder: (context, child) {
        final menusFiltrados = permissoesGlobais.menusPermitidos.where(
          (m) => m.rota == 'entregador_gestao',
        );

        if (menusFiltrados.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.deepOrange),
          );
        }

        final menuPai = menusFiltrados.first;
        final submenus = permissoesGlobais.getSubmenusDoMenu(menuPai.id);
        final submenusFiltrados = submenus
            .where((s) => s.rota != 'lista_entregadores_aba')
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
                    "Nenhuma aba configurada no Firestore para Entregadores.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        }

        submenusFiltrados.sort((a, b) => a.peso.compareTo(b.peso));

        // 💡 CÁLCULO DE FOCO: Sincroniza a aba com o menu lateral
        int indiceFoco = 0;
        final abasDinamicas = <TabItemModel>[];

        for (int i = 0; i < submenusFiltrados.length; i++) {
          final submenu = submenusFiltrados[i];
          abasDinamicas.add(
            TabItemModel(
              titulo: submenu.titulo,
              conteudo: _resolverConteudoDaAba(submenu.rota),
            ),
          );

          if (widget.rotaAbaAtiva != null &&
              widget.rotaAbaAtiva == submenu.rota) {
            indiceFoco = i;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBarraTopoBreadcrumb(),
            const SizedBox(height: 16),
            Expanded(
              child: GenericTabHub(
                abas: abasDinamicas,
                indiceInicial: indiceFoco, // Injeta o foco na aba correta!
              ),
            ),
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
              const Icon(
                Icons.sports_motorsports_rounded,
                color: Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                "Motoboys",
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
                _entregadorSelecionado!.nome,
                style: const TextStyle(
                  color: Colors.deepOrange,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () => setState(() => _entregadorSelecionado = null),
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text(
              "Voltar para Lista",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.deepOrange),
          ),
        ],
      ),
    );
  }
}
