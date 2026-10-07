import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart' as dev;
import 'firebase_options_prod.dart' as prod;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vet_route/controllers/entregador_controller.dart';
import 'package:vet_route/repositories/coleta_repository.dart';
import 'package:vet_route/repositories/firestore_coleta_repository.dart';
import 'package:vet_route/controllers/coleta_controller.dart';
import 'package:vet_route/l10n/app_localizations.dart';
import 'package:vet_route/screens/web/admin_chassi.dart';
import 'package:vet_route/screens/web/mobile_chassi.dart';
import 'package:vet_route/theme/app_theme.dart';
import 'package:vet_route/screens/login_screen.dart';

const String environment = String.fromEnvironment('ENV', defaultValue: 'dev');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FirebaseOptions currentOptions;

  if (environment == 'prod') {
    currentOptions = prod.DefaultFirebaseOptions.currentPlatform;
    print("A iniciar Firebase em modo PRODUÇÃO");
  } else {
    currentOptions = dev.DefaultFirebaseOptions.currentPlatform;
    print("A iniciar Firebase em modo HOMOLOGAÇÃO");
  }

  await Firebase.initializeApp(options: currentOptions);

  runApp(const VetRouteAPP()); // Erro corrigido aqui!
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
        '/home': (context) => kIsWeb
            ? const AdminChassi(
                conteudo: SizedBox(),
                titulo: 'Painel Vet Route',
              )
            : const MobileChassi(),
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            if (kIsWeb) {
              return const AdminChassi(
                conteudo: SizedBox(),
                titulo: 'Painel Vet Route',
              );
            } else {
              return const MobileChassi();
            }
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
