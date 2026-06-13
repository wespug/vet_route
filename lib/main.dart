import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:logger/logger.dart';

final logger = Logger();

// ==========================================
// 1. INICIALIZAÇÃO (LIGA O FIREBASE)
// ==========================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const VetRouteAPP());
}

// ==========================================
// 2. O CHASSI DO APLICATIVO
// ==========================================
class VetRouteAPP extends StatelessWidget {
  const VetRouteAPP({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vet Route',
      debugShowCheckedModeBanner: false, // Tira aquela faixa de "Debug" da tela
      // O 'home' é onde amarramos o chassi com a tela visível!
      home: const TelaInicial(),
    );
  }
}

// ==========================================
// 3. A TELA VISÍVEL (NOVA TELA DE LOGIN)
// ==========================================
class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  // Controladores para capturar e-mail e senha
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Perfil padrão
  String _perfilSelecionado = 'Clínica';

  // Função que muda a cor dependendo do perfil (Ideia da nossa reunião!)
  Color _obterCorPorPerfil() {
    switch (_perfilSelecionado) {
      case 'Motoboy':
        return Colors.orange;
      case 'Laboratório':
        return Colors.indigo;
      case 'Clínica':
      default:
        return Colors.teal; // Verde-água para fugir do vermelho
    }
  }

  @override
  Widget build(BuildContext context) {
    final corDoTema = _obterCorPorPerfil();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vet Route - Acesso'),
        backgroundColor: corDoTema,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.local_shipping, size: 80, color: corDoTema),
                const SizedBox(height: 16),
                Text(
                  'Bem-vindo ao Vet Route',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: corDoTema,
                  ),
                ),
                const SizedBox(height: 32),

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 16),

                // Seletor de Perfil
                DropdownButtonFormField<String>(
                  initialValue: _perfilSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Selecione seu Perfil',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: ['Clínica', 'Motoboy', 'Laboratório'].map((
                    String perfil,
                  ) {
                    return DropdownMenuItem<String>(
                      value: perfil,
                      child: Text(perfil),
                    );
                  }).toList(),
                  onChanged: (novoPerfil) {
                    setState(() {
                      _perfilSelecionado = novoPerfil!;
                    });
                  },
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: () {
                    logger.i('Tentando login com: ${_emailController.text}');
                    //print('Testando login com: ${_emailController.text}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: corDoTema,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Entrar', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
