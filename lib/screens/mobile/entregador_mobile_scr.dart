import 'package:flutter/material.dart';

class EntregadorMobileScr extends StatelessWidget {
  const EntregadorMobileScr({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.deepOrange,
      body: Center(
        child: Text(
          "ENTREGADOR",
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2.0,
          ),
        ),
      ),
    );
  }
}
