import 'package:flutter/material.dart';
import 'package:vet_route/l10n/app_localizations.dart';
import 'package:vet_route/services/auth_service.dart';
import 'package:vet_route/controllers/permissoes_controller.dart';

// Telas do Sistema
import 'package:vet_route/screens/web/laboratorios/lista_laboratorios_screen.dart';
import 'package:vet_route/screens/widgets/gestao_menus_hub.dart';
import 'package:vet_route/screens/widgets/gestao_perfis_hub.dart';
import 'package:vet_route/screens/widgets/gestao_submenus_hub.dart';
import 'package:vet_route/screens/widgets/gestao_usuarios_hub.dart';
import 'package:vet_route/screens/web/entregador_gestao_web.dart';
import 'package:vet_route/screens/web/clinica_gestao_web.dart';

class AdminChassi extends StatefulWidget {
  final Widget conteudo;
  final String titulo;

  const AdminChassi({super.key, required this.conteudo, required this.titulo});

  @override
  State<AdminChassi> createState() => _AdminChassiState();
}

class _AdminChassiState extends State<AdminChassi> {
  // 💡 ROTEADOR DE ÍCONES: Traduz a string do banco para o ícone visual
  static const Map<String, IconData> _iconesMapeados = {
    'local_hospital': Icons.local_hospital,
    'science': Icons.science,
    'motorcycle': Icons.motorcycle,
    'admin_panel_settings': Icons.admin_panel_settings_outlined,
    'layers': Icons.layers_rounded,
    'account_tree': Icons.account_tree_outlined,
    'people': Icons.people_alt_outlined,
    'dashboard': Icons.dashboard,
    'subdirectory_arrow_right': Icons.subdirectory_arrow_right_rounded,
    'analytics': Icons.analytics_outlined,
    'assignment': Icons.assignment_outlined,
    'payments': Icons.payments_outlined,
    'inventory': Icons.inventory_2_outlined,
  };

  // 💡 ROTEADOR DE TELAS: Traduz a rota do banco para o Widget real
  static final Map<String, Widget Function()> _telasMapeadas = {
    'clinica_gestao': () => ClinicaGestaoWeb(),
    'lista_laboratorios': () => const ListaLaboratoriosScreen(),
    'entregador_gestao': () => EntregadorGestaoWeb(),
    'gestao_perfis': () => const GestaoPerfisHub(),
    'gestao_menus': () => const GestaoMenusHub(),
    'gestao_submenus': () => const GestaoSubmenusHub(),
    'gestao_usuarios': () => const GestaoUsuarioHub(),
  };

  @override
  Widget build(BuildContext context) {
    const corMenuLateral = Color(0xFF343A40);
    const corFundo = Color(0xFFF4F6F9);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        return Scaffold(
          backgroundColor: corFundo,
          appBar: AppBar(
            title: Text(
              widget.titulo,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 1,
          ),
          drawer: isDesktop
              ? null
              : _construirMenuLateral(context, corMenuLateral),
          body: Row(
            children: [
              if (isDesktop)
                SizedBox(
                  width: 250,
                  child: _construirMenuLateral(context, corMenuLateral),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: widget.conteudo,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _construirMenuLateral(BuildContext context, Color corFundo) {
    final i18n = AppLocalizations.of(context)!;

    return Material(
      color: corFundo,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF23272B)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.pets, color: Colors.white, size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    i18n.adminMenuHeader ?? 'Vet Route Admin',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListenableBuilder(
              listenable: permissoesGlobais,
              builder: (context, child) {
                if (permissoesGlobais.carregando) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                // 💡 CLEAN CODE: Se não tem menu, apenas informa. Sem fallback estático!
                if (permissoesGlobais.menusPermitidos.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      "Nenhum módulo liberado para o seu perfil de acesso.",
                      style: TextStyle(color: Colors.white54),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                // 🚀 RENDERIZAÇÃO 100% BASEADA EM DADOS DO FIRESTORE
                return ListView(
                  padding: EdgeInsets.zero,
                  children: permissoesGlobais.menusPermitidos.map((menu) {
                    final submenus = permissoesGlobais.getSubmenusDoMenu(
                      menu.id,
                    );
                    final iconData =
                        _iconesMapeados[menu.icone] ?? Icons.widgets_outlined;

                    if (submenus.isEmpty) {
                      return _itemMenu(iconData, menu.titulo, () {
                        _executarNavegacao(context, menu.titulo, menu.rota);
                      });
                    }

                    return ExpansionTile(
                      iconColor: Colors.white,
                      collapsedIconColor: Colors.white70,
                      leading: Icon(iconData, color: Colors.white70),
                      title: Text(
                        menu.titulo,
                        style: const TextStyle(color: Colors.white),
                      ),
                      children: submenus.map((sub) {
                        final subIcon =
                            _iconesMapeados[sub.icone] ??
                            Icons.subdirectory_arrow_right_rounded;

                        return ListTile(
                          contentPadding: const EdgeInsets.only(left: 56),
                          leading: Icon(
                            subIcon,
                            color: Colors.white54,
                            size: 18,
                          ),
                          title: Text(
                            sub.titulo,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          hoverColor: Colors.white12,
                          onTap: () =>
                              _executarNavegacao(context, sub.titulo, sub.rota),
                        );
                      }).toList(),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          const Divider(color: Colors.white24, height: 1),
          _itemMenu(
            Icons.exit_to_app,
            i18n.logout ?? 'Sair do Sistema',
            () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  void _executarNavegacao(
    BuildContext context,
    String titulo,
    String chaveRota,
  ) {
    final construtoraTela = _telasMapeadas[chaveRota];
    final Widget telaDestino = construtoraTela != null
        ? construtoraTela()
        : Center(child: Text("Rota '$chaveRota' indefinida no Roteador."));

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, a1, a2) =>
            AdminChassi(titulo: titulo, conteudo: telaDestino),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  Widget _itemMenu(IconData icone, String titulo, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icone, color: Colors.white70),
      title: Text(titulo, style: const TextStyle(color: Colors.white)),
      hoverColor: Colors.white12,
      onTap: onTap,
    );
  }
}
