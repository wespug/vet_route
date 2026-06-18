import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/l10n/app_localizations.dart';
import 'package:vet_route/theme/app_theme.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vet_route/screens/login_screen.dart';
import 'package:vet_route/screens/web/cadastro_usuario_web.dart';
import 'package:vet_route/screens/clinica_screen.dart'; // <-- IMPORTANTE: Nossa tela real
import 'package:vet_route/models/perfil_usuario.dart'; // <-- IMPORTANTE: Nosso novo Enum
import 'package:vet_route/services/auth_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
      theme: VetRouteTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', ''), Locale('en', '')],
      home: StreamBuilder<User?>(
        stream: AuthService().usuarioStatus,
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (!authSnapshot.hasData) {
            return const LoginScreen();
          }

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('usuarios')
                .doc(authSnapshot.data!.uid)
                .get(),
            builder: (context, firestoreSnapshot) {
              if (firestoreSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (!firestoreSnapshot.hasData ||
                  !firestoreSnapshot.data!.exists) {
                return _telaErroAcesso(
                  'Perfil de usuário não encontrado no banco de dados.',
                );
              }

              // 💡 Extrai a String e converte imediatamente para o Enum Blindado
              final stringPerfil =
                  firestoreSnapshot.data!.get('perfil') as String?;
              final perfil = PerfilUsuario.fromString(stringPerfil);

              // === A GRANDE TRIAGEM (COM ENUMS E SWITCH) ===

              // SE ESTIVER NO NAVEGADOR (WEB)
              if (kIsWeb) {
                if (perfil == PerfilUsuario.administrador) {
                  return const CadastroUsuarioWeb();
                } else {
                  return _telaErroAcesso(
                    'Acesso Negado. Seu perfil só pode acessar via Aplicativo de Celular.',
                  );
                }
              }
              // SE ESTIVER NO CELULAR (MOBILE)
              else {
                switch (perfil) {
                  case PerfilUsuario.administrador:
                    return _telaErroAcesso(
                      'Administradores devem utilizar a versão Web pelo computador.',
                    );

                  case PerfilUsuario.clinica:
                    return const ClinicaScreen(); // <-- Abrindo nossa tela 100% real

                  case PerfilUsuario.laboratorio:
                    return const Scaffold(
                      body: Center(
                        child: Text('TELA DO LABORATÓRIO (Em construção)'),
                      ),
                    );

                  case PerfilUsuario.motoboy:
                    return const Scaffold(
                      body: Center(
                        child: Text('TELA DO MOTOBOY (Em construção)'),
                      ),
                    );

                  case PerfilUsuario.desconhecido:
                    return _telaErroAcesso(
                      'Perfil inválido ou não reconhecido pelo sistema.',
                    );
                }
              }
            },
          );
        },
      ),
    );
  }

  Widget _telaErroAcesso(String mensagem) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, color: Colors.red, size: 80),
              const SizedBox(height: 20),
              Text(
                mensagem,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => AuthService().logout(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar para o Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
