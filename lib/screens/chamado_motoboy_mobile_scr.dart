import 'package:flutter/material.dart';

class ChamadoMotoboyMobileScreen extends StatelessWidget {
  final String rotaQueChamou;

  const ChamadoMotoboyMobileScreen({super.key, required this.rotaQueChamou});

  @override
  Widget build(BuildContext context) {
    // Definimos cores do tema premium Vet Route
    const Color indigoPremium = Color(0xFF1F2959); // Indigo shade 900
    const Color greenAccentBrand = Color(0xFF7FFFD4); // GreenAccent (Pata)
    const Color whiteBackground = Colors.white;
    const Color colorSuccess = Color(
      0xFF10B981,
    ); // 🛠️ CORREÇÃO: Verde esmeralda válido

    return Scaffold(
      backgroundColor: whiteBackground,
      // AppBar limpa com a Pata de Marca centrada
      appBar: AppBar(
        backgroundColor: whiteBackground,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: indigoPremium),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.pets_rounded, size: 20, color: greenAccentBrand), // Pata
            SizedBox(width: 10),
            Text(
              "VET ROUTE",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: indigoPremium,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        // Generous padding for clean look
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Cabeçalho de Secção com ícone moderno
            const Icon(
              Icons.two_wheeler_rounded,
              size: 56,
              color: indigoPremium,
            ), // Duas rodas
            const SizedBox(height: 24),
            const Text(
              "SOLICITAR MOTOBOY",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: indigoPremium,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Confirme os detalhes e solicite o serviço",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 48),

            // O CARTÃO ELEVADO PREMIUM (Foco na Ação)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Secção de Confirmação visual
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: greenAccentBrand.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: colorSuccess,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Rota Autorizada",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorSuccess,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Título da Ação
                  const Text(
                    "Serviço de Motoboy de Rotina",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: indigoPremium,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // O Detalhe técnico dynamic detail (como no banco)
                  Text(
                    "Confirme a rota: $rotaQueChamou",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1, color: Colors.black12),
                  const SizedBox(height: 24),

                  // BOTÃO DE AÇÃO PREMIUM ÚNICO E ELEGANTE (confirmar solicitação)
                  ElevatedButton.icon(
                    onPressed: () {
                      // Ação de confirmação...
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Solicitação de Motoboy enviada com sucesso!",
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: indigoPremium, // Indigo Premium
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text(
                      "Confirmar Solicitação",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
