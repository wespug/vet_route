import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vet_route/screens/web/admin_chassi.dart';

import 'package:vet_route/screens/login_screen.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:vet_route/screens/web/cadastro_usuario_web.dart';
import 'package:vet_route/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const VetRouteAPP());
}

class VetRouteAPP extends StatelessWidget {
  const VetRouteAPP({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vet Route',
      debugShowCheckedModeBanner: false,
      // O 'home' agora é reativo e inteligente
      home: StreamBuilder<User?>(
        stream: AuthService().usuarioStatus,
        builder: (context, snapshot) {
          // Se o Firebase ainda estiver pensando/carregando o status
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Se existir um usuário autenticado na sessão...
          if (snapshot.hasData) {
            // Entra direto no Painel Web Admin com a tela de Cadastro no meio!
            return const CadastroUsuarioWeb();
          }

          // Se não tiver ninguém logado, exibe a tela de login padrão
          return const LoginScreen();
        },
      ),
    );
  }
}
