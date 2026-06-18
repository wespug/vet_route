import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; // <-- Importante para saber se é Web ou App
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/l10n/app_localizations.dart';
import 'package:vet_route/theme/app_theme.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vet_route/screens/login_screen.dart';
import 'package:vet_route/screens/web/cadastro_usuario_web.dart';
import 'package:vet_route/services/auth_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vet_route/screens/clinica_screen.dart';

// Importe suas telas mobile aqui (MotoboyScreen, ClinicaScreen, etc) quando existirem

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

      // === 2. ADICIONE ESTE BLOCO DE INTERNACIONALIZAÇÃO ===
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', ''), // Português
        Locale('en', ''), // Inglês
        Locale('es', ''), // Espanhol (quando você criar o app_es.arb)
      ],
      // ====================================================

      // 1. PRIMEIRO PASSO: Ouve se o usuário tem token de acesso (Auth)
      home: StreamBuilder<User?>(
        stream: AuthService().usuarioStatus,
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Se não tem login, volta pro LoginScreen (tanto web quanto app)
          if (!authSnapshot.hasData) {
            return const LoginScreen();
          }

          // 2. SEGUNDO PASSO: O usuário está logado! Vamos descobrir o perfil dele no Banco.
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

              // Prevenção de erro: Se o usuário logou, mas o documento dele foi apagado do banco
              if (!firestoreSnapshot.hasData ||
                  !firestoreSnapshot.data!.exists) {
                return _telaErroAcesso(
                  'Perfil de usuário não encontrado no banco de dados.',
                );
              }

              // Extrai o perfil do banco
              final perfil = firestoreSnapshot.data!.get('perfil') as String?;

              // === 3. A GRANDE TRIAGEM (A MÁGICA ACONTECE AQUI) ===

              // SE ESTIVER NO NAVEGADOR (WEB)
              if (kIsWeb) {
                if (perfil == 'Administrador') {
                  return const CadastroUsuarioWeb(); // Deixa o admin passar
                } else {
                  return _telaErroAcesso(
                    'Acesso Negado. Seu perfil ($perfil) só pode acessar via Aplicativo de Celular.',
                  );
                }
              }
              // SE ESTIVER NO CELULAR (MOBILE)
              else {
                if (perfil == 'Administrador') {
                  return _telaErroAcesso(
                    'Administradores devem utilizar a versão Web pelo computador.',
                  );
                }

                // Rotas do Mobile
                if (perfil == 'Motoboy') {
                  return const Scaffold(
                    body: Center(
                      child: Text('TELA DO MOTOBOY (Em construção)'),
                    ),
                  );
                }
                if (perfil == 'Clínica') {
                  return const ClinicaScreen();
                }

                if (perfil == 'Laboratório') {
                  return const Scaffold(
                    body: Center(
                      child: Text('TELA DO LABORATÓRIO (Em construção)'),
                    ),
                  );
                }

                return _telaErroAcesso('Perfil desconhecido: $perfil');
              }
            },
          );
        },
      ),
    );
  }

  // Widget de apoio: Uma telinha amigável para quando o usuário for barrado
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
