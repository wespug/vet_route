import 'package:flutter/material.dart';
import 'package:vet_route/l10n/app_localizations.dart';
import 'package:vet_route/screens/web/laboratorios/lista_laboratorios_screen.dart';
import 'package:vet_route/screens/widgets/gestao_perfis_hub.dart';
import 'package:vet_route/screens/widgets/gestao_usuarios_hub.dart';
import 'package:vet_route/services/auth_service.dart';

// Nossas Telas de Gestão
import 'package:vet_route/screens/web/entregador_gestao_web.dart';
import 'package:vet_route/screens/web/clinica_gestao_web.dart';

class AdminChassi extends StatelessWidget {
  final Widget conteudo;
  final String titulo;

  const AdminChassi({super.key, required this.conteudo, required this.titulo});

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
              titulo,
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
                  child: conteudo,
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
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF23272B)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pets, color: Colors.white, size: 40),
                const SizedBox(height: 10),
                Text(
                  i18n.adminMenuHeader ?? 'Vet Route Admin',
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
              ],
            ),
          ),

          // 🏥 MENU: CLÍNICAS
          _itemMenu(Icons.local_hospital, i18n.clinics ?? 'Clínicas', () {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => AdminChassi(
                  titulo: i18n.clinics ?? 'Gestão de Clínicas',
                  conteudo: ClinicaGestaoWeb(),
                ),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }),

          // 🔬 MENU: LABORATÓRIOS
          _itemMenu(Icons.science, i18n.lab ?? 'Laboratórios', () {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => AdminChassi(
                  titulo: i18n.labManagement ?? 'Gestão de Laboratórios',
                  // 💡 AJUSTE AQUI: Chamando a lista nova em vez do form antigo!
                  conteudo: const ListaLaboratoriosScreen(),
                ),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }),

          // 🛵 MENU: MOTOBOYS
          _itemMenu(Icons.motorcycle, i18n.couriers ?? 'Motoboys', () {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => AdminChassi(
                  titulo: i18n.couriers ?? 'Gestão de Motoboys',
                  conteudo: EntregadorGestaoWeb(),
                ),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }),

          // --- NOVO BLOCO: CONTROLE DE ACESSO ---
          const Divider(color: Colors.white24, height: 32),

          const Padding(
            padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
            child: Text(
              "CONTROLE DE ACESSO",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),

          // 🛡️ MENU: GESTÃO DE PERFIS
          _itemMenu(Icons.admin_panel_settings_outlined, 'Gestão de Perfis', () {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => AdminChassi(
                  titulo: 'Gestão de Perfis',
                  // 💡 Atenção: passe a variável do laboratório que você já tem nessa tela
                  conteudo: GestaoPerfisHub(),
                ),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }),

          // 👥 MENU: USUÁRIOS E PERMISSÕES
          _itemMenu(Icons.people_alt_outlined, 'Usuários', () {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => AdminChassi(
                  titulo: 'Gestão de Usuários',
                  // 💡 Atenção: passe a variável do laboratório que você já tem nessa tela
                  conteudo: GestaoUsuarioHub(),
                ),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }),

          // --------------------------------------
          const Divider(color: Colors.white24, height: 32),

          // 🚪 MENU: SAIR
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

  Widget _itemMenu(IconData icone, String titulo, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icone, color: Colors.white70),
      title: Text(titulo, style: const TextStyle(color: Colors.white)),
      hoverColor: Colors.white12,
      onTap: onTap,
    );
  }
}
