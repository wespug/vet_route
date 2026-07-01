import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/l10n/app_localizations.dart';
import 'package:vet_route/screens/entregador_screen.dart';
import 'package:vet_route/screens/laboratorio_screen.dart';
import 'package:vet_route/theme/app_theme.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vet_route/screens/login_screen.dart';
import 'package:vet_route/screens/web/cadastro_usuario_web.dart';
import 'package:vet_route/screens/clinica_screen.dart';
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

      // 💡 AS ROTAS MÁGICAS! Aqui a Tela de Login sabe para onde jogar o usuário.
      // E o mais legal: já aplica as cores (Themes) certas para cada perfil!
      routes: {
        '/login': (context) => const LoginScreen(),
        '/admin': (context) => const CadastroUsuarioWeb(),
        '/clinica': (context) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          ),
          child: const ClinicaScreen(),
        ),
        '/laboratorio': (context) => Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
          child: const LaboratorioScreen(),
        ),
        '/motoboy': (context) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.amber.shade700,
              primary: Colors.amber.shade700,
              tertiary: Colors.amber.shade700,
            ),
          ),
          child: EntregadorScreen(),
        ),
      },

      // O home agora é o "Guardião" (Gatekeeper) para quando o app for reaberto já logado.
      home: const AuthGatekeeper(),
    );
  }
}

// ============================================================================
// 🛡️ O GUARDIÃO DE ACESSOS (Gatekeeper)
// Ele funciona quando o usuário já tem a sessão salva no celular e abre o app
// ============================================================================
class AuthGatekeeper extends StatelessWidget {
  const AuthGatekeeper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().usuarioStatus,
      builder: (context, authSnapshot) {
        // 1. Está carregando o status de autenticação?
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Não está logado? Manda para a tela de Login!
        if (!authSnapshot.hasData) {
          return const LoginScreen();
        }

        // 3. O usuário está logado. Vamos buscar os dados dele no banco!
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(authSnapshot.data!.uid)
              .get(),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!userSnap.hasData || !userSnap.data!.exists) {
              return _telaErroAcesso(
                'Perfil de usuário não encontrado no banco de dados.',
              );
            }

            final userData = userSnap.data!.data() as Map<String, dynamic>?;

            // Segurança extra: A conta está ativa?
            if (userData == null || userData['ativo'] == false) {
              return _telaErroAcesso(
                'Esta conta está desativada. Contate o suporte.',
              );
            }

            final perfilId = userData['perfilId'] ?? '';

            // 4. Busca o nome do cargo lá na tabela de perfis
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('perfis')
                  .doc(perfilId)
                  .get(),
              builder: (context, perfilSnap) {
                if (perfilSnap.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!perfilSnap.hasData || !perfilSnap.data!.exists) {
                  return _telaErroAcesso(
                    'O cargo vinculado a esta conta não existe mais.',
                  );
                }

                final perfilData =
                    perfilSnap.data!.data() as Map<String, dynamic>;
                final nomePerfil = (perfilData['nome'] ?? '')
                    .toString()
                    .toLowerCase();

                // === A GRANDE TRIAGEM AUTOMÁTICA ===

                if (nomePerfil.contains('admin')) {
                  if (kIsWeb) return const CadastroUsuarioWeb();
                  return _telaErroAcesso(
                    'Administradores devem utilizar a versão Web pelo computador.',
                  );
                } else if (nomePerfil.contains('clínica') ||
                    nomePerfil.contains('clinica')) {
                  if (kIsWeb)
                    return _telaErroAcesso(
                      'Acesso da Clínica deve ser feito pelo Celular.',
                    );
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.fromSeed(
                        seedColor: Colors.indigo,
                      ),
                    ),
                    child: const ClinicaScreen(),
                  );
                } else if (nomePerfil.contains('laboratório') ||
                    nomePerfil.contains('laboratorio')) {
                  if (kIsWeb)
                    return _telaErroAcesso(
                      'Acesso do Laboratório deve ser feito pelo Celular.',
                    );
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
                    ),
                    child: const LaboratorioScreen(),
                  );
                } else if (nomePerfil.contains('motoboy') ||
                    nomePerfil.contains('entregador')) {
                  if (kIsWeb)
                    return _telaErroAcesso(
                      'Acesso do Entregador deve ser feito pelo Celular.',
                    );
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.fromSeed(
                        seedColor: Colors.amber.shade700,
                        primary: Colors.amber.shade700,
                        tertiary: Colors.amber.shade700,
                      ),
                    ),
                    child: EntregadorScreen(),
                  );
                } else {
                  return _telaErroAcesso(
                    'Perfil inválido ou não reconhecido pelo sistema.',
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  // === TELA DE ERRO PADRÃO ===
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
