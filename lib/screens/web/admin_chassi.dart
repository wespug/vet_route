import 'package:flutter/material.dart';
import 'package:vet_route/l10n/app_localizations.dart';
import 'package:vet_route/services/auth_service.dart';

// Nossas Telas de Gestão
import 'package:vet_route/screens/web/laboratorio_gestao_web.dart';
import 'package:vet_route/screens/web/entregador_gestao_web.dart';
import 'package:vet_route/screens/web/clinica_gestao_web.dart'; // 💡 Ajuste esse import para o nome real do seu arquivo de Clínicas se for diferente

class AdminChassi extends StatelessWidget {
  final Widget conteudo;
  final String titulo;

  const AdminChassi({super.key, required this.conteudo, required this.titulo});

  @override
  Widget build(BuildContext context) {
    // Cores clássicas inspiradas no AdminLTE
    const corMenuLateral = Color(0xFF343A40); // Cinza escuro/chumbo
    const corFundo = Color(0xFFF4F6F9); // Cinza bem clarinho

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        return Scaffold(
          backgroundColor: corFundo,
          // A BARRA SUPERIOR
          appBar: AppBar(
            title: Text(
              titulo,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 1,
          ),

          // O MENU LATERAL (DRAWER) - Escondido no celular, fixo no PC
          drawer: isDesktop
              ? null
              : _construirMenuLateral(context, corMenuLateral),

          // O CORPO DA TELA
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

  // O VISUAL DO MENU (SIDEBAR)
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
                  conteudo:
                      ClinicaGestaoWeb(), // 💡 Sem o "const"! Ajuste o nome se necessário
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
                  conteudo: LaboratorioGestaoWeb(), // 💡 Sem o "const"!
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
                  conteudo:
                      EntregadorGestaoWeb(), // 💡 Chamando a tela novinha!
                ),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }),

          const Divider(color: Colors.white24),

          // 🚪 MENU: SAIR
          _itemMenu(
            Icons.exit_to_app,
            i18n.logout ?? 'Sair do Sistema',
            () async {
              await AuthService().logout();

              // Garantir redirecionamento imediato para a tela de login
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/', // 💡 Ajuste aqui se a sua rota de login for diferente de '/'
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para os botões do menu
  Widget _itemMenu(IconData icone, String titulo, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icone, color: Colors.white70),
      title: Text(titulo, style: const TextStyle(color: Colors.white)),
      hoverColor: Colors.white12,
      onTap: onTap,
    );
  }
}
