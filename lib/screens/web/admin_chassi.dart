import 'package:flutter/material.dart';
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
              titulo,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 1, // Sombra leve
          ),

          // O MENU LATERAL (DRAWER) - Escondido no celular, fixo no PC
          drawer: isDesktop ? null : _construirMenuLateral(corMenuLateral),

          // O CORPO DA TELA
          body: Row(
            children: [
              // Se for PC, mostra o menu fixo na esquerda
              if (isDesktop)
                SizedBox(
                  width: 250,
                  child: _construirMenuLateral(corMenuLateral),
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
  Widget _construirMenuLateral(Color corFundo) {
    return Material( // <--- Trocamos para Material!
      color: corFundo,
      child: ListView(
        children: [
          // Cabeçalho do Menu Lateral
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF23272B)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pets, color: Colors.white, size: 40),
                SizedBox(height: 10),
                Text('Vet Route Admin', style: TextStyle(color: Colors.white, fontSize: 20)),
              ],
            ),
          ),
          // ... resto dos seus botões do menu ...

          // Botões do Menu
          _itemMenu(Icons.people, 'Usuários', () {}),
          _itemMenu(Icons.local_hospital, 'Clínicas', () {}),
          _itemMenu(Icons.science, 'Laboratórios', () {}),
          _itemMenu(Icons.motorcycle, 'Motoboys', () {}),
          const Divider(color: Colors.white24), // Uma linha divisória
          _itemMenu(Icons.exit_to_app, 'Sair do Sistema', () {
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
