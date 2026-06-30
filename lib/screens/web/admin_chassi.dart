import 'package:flutter/material.dart';
import 'package:vet_route/l10n/app_localizations.dart';
import 'package:vet_route/screens/web/laboratorios/lista_laboratorios_screen.dart';
import 'package:vet_route/screens/widgets/gestao_menus_hub.dart';
import 'package:vet_route/screens/widgets/gestao_perfis_hub.dart';
import 'package:vet_route/screens/widgets/gestao_submenus_hub.dart';
import 'package:vet_route/screens/widgets/gestao_usuarios_hub.dart';
import 'package:vet_route/services/auth_service.dart';
import 'package:vet_route/controllers/permissoes_controller.dart';

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
  // 💡 CENTRALIZADOR DE ICONES: Transforma String do Firebase em IconData Real do Flutter
  static const Map<String, IconData> _iconesMapeados = {
    'local_hospital': Icons.local_hospital,
    'science': Icons.science,
    'motorcycle': Icons.motorcycle,
    'admin_panel_settings': Icons.admin_panel_settings_outlined,
    'layers': Icons.layers_rounded,
    'account_tree': Icons.account_tree_outlined,
    'people': Icons.people_alt_outlined,
    'dashboard': Icons.dashboard,
  };

  // 💡 CENTRALIZADOR DE TELAS: Vincula a Rota do Firebase ao Widget correspondente
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

                // FALLBACK INTELIGENTE: Se não houver nada no banco ainda, carrega a lista legada
                if (permissoesGlobais.menusPermitidos.isEmpty) {
                  return ListView(
                    padding: EdgeInsets.zero,
                    children: _construirMenuEstaticoFallback(i18n),
                  );
                }

                // 🚀 SISTEMA TOTALMENTE DINÂMICO E DATA-DRIVEN
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
                        return ListTile(
                          contentPadding: const EdgeInsets.only(left: 56),
                          leading: const Icon(
                            Icons.subdirectory_arrow_right,
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
                          onTap: () {
                            // Submenu usa a rota que foi configurada nele ou herda do pai
                            _executarNavegacao(context, sub.titulo, menu.rota);
                          },
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
              if (context.mounted)
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
    );
  }

  // 💡 Lógica Dinâmica de Roteamento sem Hardcoding
  void _executarNavegacao(
    BuildContext context,
    String titulo,
    String chaveRota,
  ) {
    // Puxa a construtora da tela direto do mapa estático
    final construtoraTela = _telasMapeadas[chaveRota];
    final Widget telaDestino = construtoraTela != null
        ? construtoraTela()
        : Center(child: Text("Rota '$chaveRota' indefinida."));

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

  List<Widget> _construirMenuEstaticoFallback(AppLocalizations i18n) {
    return [
      _itemMenu(
        Icons.local_hospital,
        i18n.clinics ?? 'Clínicas',
        () => _executarNavegacao(
          context,
          i18n.clinics ?? 'Gestão de Clínicas',
          'clinica_gestao',
        ),
      ),
      _itemMenu(
        Icons.science,
        i18n.lab ?? 'Laboratórios',
        () => _executarNavegacao(
          context,
          i18n.labManagement ?? 'Gestão de Laboratórios',
          'lista_laboratorios',
        ),
      ),
      _itemMenu(
        Icons.motorcycle,
        i18n.couriers ?? 'Motoboys',
        () => _executarNavegacao(
          context,
          i18n.couriers ?? 'Gestão de Motoboys',
          'entregador_gestao',
        ),
      ),
      const Divider(color: Colors.white24, height: 32),
      const Padding(
        padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
        child: Text(
          "CONTROLE DE ACESSO",
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      _itemMenu(
        Icons.admin_panel_settings_outlined,
        'Gestão de Perfis',
        () => _executarNavegacao(context, 'Gestão de Perfis', 'gestao_perfis'),
      ),
      _itemMenu(
        Icons.layers_rounded,
        'Gestão de Menus',
        () => _executarNavegacao(context, 'Gestão de Menus', 'gestao_menus'),
      ),
      _itemMenu(
        Icons.account_tree_outlined,
        'Gestão de Submenus',
        () => _executarNavegacao(
          context,
          'Gestão de Submenus',
          'gestao_submenus',
        ),
      ),
      _itemMenu(
        Icons.people_alt_outlined,
        'Usuários',
        () => _executarNavegacao(
          context,
          'Gestão de Usuários',
          'gestao_usuarios',
        ),
      ),
    ];
  }
}
