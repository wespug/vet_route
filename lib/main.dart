import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:vet_route/repositories/coleta_repository.dart';
import 'package:vet_route/repositories/firestore_coleta_repository.dart';
import 'package:vet_route/controllers/coleta_controller.dart';

import 'package:vet_route/l10n/app_localizations.dart';
import 'package:vet_route/screens/web/admin_chassi.dart';
import 'package:vet_route/screens/web/mobile_chassi.dart';
import 'package:vet_route/theme/app_theme.dart';
import 'package:vet_route/screens/login_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        // 1. Injeção da Interface com a Implementação Concreta
        Provider<ColetaRepository>(create: (_) => FirestoreColetaRepository()),
        // 2. Controller que consome a interface ColetaRepository
        ChangeNotifierProvider<ColetaController>(
          create: (context) =>
              ColetaController(context.read<ColetaRepository>()),
        ),
      ],
      child: const VetRouteAPP(),
    ),
  );
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
