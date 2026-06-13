import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vet_route/screens/login_scr.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const VetRouteAPP());
}

class VetRouteAPP extends StatelessWidget {
  const VetRouteAPP({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Vet Route',
      debugShowCheckedModeBanner: false,
      home: LoginScreen(), // Chamando a classe isolada
    );
  }
}
