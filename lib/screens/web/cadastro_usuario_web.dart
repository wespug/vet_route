import 'package:flutter/material.dart';
import 'package:vet_route/screens/widgets/gestao_usuarios_hub.dart';

class CadastroUsuarioWeb extends StatelessWidget {
  const CadastroUsuarioWeb({super.key});

  @override
  Widget build(BuildContext context) {
    // 💡 Agora ela é apenas um invólucro para a componente Hub, sem Sidebar!
    return const GestaoUsuarioHub();
  }
}
