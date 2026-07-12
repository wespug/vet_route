import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/controllers/permissoes_controller.dart';
import 'package:vet_route/l10n/app_localizations.dart';
import 'package:vet_route/screens/web/admin_chassi.dart';
import 'package:vet_route/screens/web/mobile_chassi.dart';
import 'package:vet_route/theme/app_theme.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vet_route/screens/login_screen.dart';
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
        '/home': (context) => kIsWeb
            ? const AdminChassi(
                conteudo: SizedBox(),
                titulo: 'Painel Vet Route',
              )
            // 📱 Mobile Roteador cai no Chassi
            : const MobileChassi(),
      },
      // 🛡️ O GUARDIÃO DO FIREBASE
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            // 🚀 BIFURCAÇÃO CRÍTICA DO SISTEMA
            if (kIsWeb) {
              return const AdminChassi(
                conteudo: SizedBox(),
                titulo: 'Painel Vet Route',
              );
            } else {
              // 📱 Mobile force o aplicativo a abrir o Chassi com o Menu
              return const MobileChassi();
            }
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
