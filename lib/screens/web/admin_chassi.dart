import 'package:flutter/material.dart';
import 'package:vet_route/l10n/app_localizations.dart';
import 'package:vet_route/services/auth_service.dart';

class AdminChassi extends StatelessWidget {
  final Widget conteudo;
  final String titulo;

  const AdminChassi({super.key, required this.conteudo, required this.titulo});

  @override
  Widget build(BuildContext context) {
    // Cores clássicas inspiradas no AdminLTE
    const corMenuLateral = Color(0xFF343A40); // Cinza escuro/chumbo
    const corFundo = Color(0xFFF4F6F9); // Cinza bem clarinho

    // LayoutBuilder verifica a largura da tela em tempo real
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        return Scaffold(
          backgroundColor: corFundo,
          // A BARRA SUPERIOR
          appBar: AppBar(
            title: Text(
              titulo, // Obs: Esse título já vem da tela que chama o Chassi, então a tradução dele é feita lá!
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 1, // Sombra leve
          ),

          // O MENU LATERAL (DRAWER) - Escondido no celular, fixo no PC
          // Passamos o 'context' para a função saber o idioma!
          drawer: isDesktop
              ? null
              : _construirMenuLateral(context, corMenuLateral),

          // O CORPO DA TELA
          body: Row(
            children: [
              // Se for PC, mostra o menu fixo na esquerda
              if (isDesktop)
                SizedBox(
                  width: 250,
                  child: _construirMenuLateral(context, corMenuLateral),
                ),

              // A área central de conteúdo (onde suas telas vão aparecer)
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
  // Recebe o BuildContext agora
  Widget _construirMenuLateral(BuildContext context, Color corFundo) {
    // Atalho Sênior para não digitar código longo toda hora
    final i18n = AppLocalizations.of(context)!;

    return Material(
      color: corFundo,
      child: ListView(
        children: [
          // Cabeçalho do Menu Lateral
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF23272B)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pets, color: Colors.white, size: 40),
                const SizedBox(height: 10),
                Text(
                  i18n.adminMenuHeader,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
              ],
            ),
          ),

          // Botões do Menu puxando do Dicionário
          _itemMenu(Icons.people, i18n.users, () {}),
          _itemMenu(Icons.local_hospital, i18n.clinics, () {}),
          _itemMenu(Icons.science, i18n.lab, () {}),
          _itemMenu(Icons.motorcycle, i18n.couriers, () {}),

          const Divider(color: Colors.white24), // Uma linha divisória

          _itemMenu(Icons.exit_to_app, i18n.logout, () {
            AuthService().logout();
          }),
        ],
      ),
    );
  }

  // Widget auxiliar para os botões do menu ficarem padronizados
  Widget _itemMenu(IconData icone, String titulo, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icone, color: Colors.white70),
      title: Text(titulo, style: const TextStyle(color: Colors.white)),
      hoverColor: Colors.white12, // Efeito visual ao passar o mouse
      onTap: onTap,
    );
  }
}
