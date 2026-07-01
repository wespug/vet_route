import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/controllers/permissoes_controller.dart';
import 'package:vet_route/l10n/app_localizations.dart';
import 'package:vet_route/screens/entregador_screen.dart';
import 'package:vet_route/screens/laboratorio_screen.dart';
import 'package:vet_route/screens/web/admin_chassi.dart';
import 'package:vet_route/theme/app_theme.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vet_route/screens/login_screen.dart';
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

      routes: {
        '/login': (context) => const LoginScreen(),
        '/admin': (context) => const AdminChassi(
          titulo: "Vet Route",
          conteudo: Center(
            child: Text(
              "Selecione uma opção no menu lateral",
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
          ),
        ),
        '/clinica': (context) => const ClinicaScreen(),
        '/laboratorio': (context) => const LaboratorioScreen(),
        '/motoboy': (context) => EntregadorScreen(),
      },

      home: const AuthGatekeeper(),
    );
  }
}

class AuthGatekeeper extends StatelessWidget {
  const AuthGatekeeper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
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

            if (userData == null || userData['ativo'] == false) {
              return _telaErroAcesso(
                'Esta conta está desativada. Contate o suporte.',
              );
            }

            final perfilId = userData['perfilId'] ?? '';

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

                // 🛠️ AS CHAVES MESTRAS UNIVERSAIS
                final bool visivelWeb = perfilData['visivelWeb'] ?? false;
                final bool visivelApp = perfilData['visivelApp'] ?? false;

                final nomePerfil = (perfilData['nome'] ?? '')
                    .toString()
                    .toLowerCase();

                // ============================================================
                // 🖥️ FLUXO DE ACESSO VIA NAVEGADOR (WEB)
                // ============================================================
                if (kIsWeb) {
                  if (visivelWeb) {
                    // Qualquer um que tenha 'visivelWeb: true' ganha a casca administrativa.
                    // O menu lateral vai carregar APENAS o que ele tiver direito de ver!
                    permissoesGlobais.inicializarParaUsuario(perfilId);

                    return const AdminChassi(
                      titulo: "Painel de Operações",
                      conteudo: Center(
                        child: Text(
                          "Selecione uma opção no menu lateral para começar.",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  } else {
                    AuthService().logout();
                    return _telaErroAcesso(
                      'Acesso Negado. O seu perfil não possui autorização para aceder à versão Web.',
                    );
                  }
                }
                // ============================================================
                // 📱 FLUXO DE ACESSO VIA APLICATIVO DE CELULAR (MOBILE)
                // ============================================================
                else {
                  if (visivelApp) {
                    // Aqui roteamos para as interfaces operacionais de celular
                    if (nomePerfil.contains('clínica') ||
                        nomePerfil.contains('clinica')) {
                      return const ClinicaScreen();
                    } else if (nomePerfil.contains('laboratório') ||
                        nomePerfil.contains('laboratorio')) {
                      return const LaboratorioScreen();
                    } else if (nomePerfil.contains('motoboy') ||
                        nomePerfil.contains('entregador')) {
                      return EntregadorScreen();
                    } else {
                      // Se for um Gestor/Admin tentando acessar o celular e tiver 'visivelApp: true', cai num placeholder
                      // Futuramente pode ser um Dashboard App de relatórios gerenciais!
                      return Scaffold(
                        appBar: AppBar(
                          title: const Text('App Gestão'),
                          backgroundColor: Colors.blueGrey.shade900,
                        ),
                        body: const Center(
                          child: Text(
                            "Visão Mobile Gerencial em Desenvolvimento 🚧",
                          ),
                        ),
                      );
                    }
                  } else {
                    AuthService().logout();
                    return _telaErroAcesso(
                      'Acesso Negado. O seu perfil não possui autorização para usar a versão Mobile.',
                    );
                  }
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _telaErroAcesso(String mensagem) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.gpp_bad_outlined, color: Colors.red, size: 80),
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
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => AuthService().logout(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar para o Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
