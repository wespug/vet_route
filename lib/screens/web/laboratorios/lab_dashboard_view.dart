import 'package:flutter/material.dart';

class LabDashboardView extends StatelessWidget {
  const LabDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Visão Geral da Operação 📊",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),

          // GRID DE MÉTRICAS SAAS
          Row(
            children: [
              _buildCardMetrica(
                "Solicitações Hoje",
                "42",
                Icons.analytics_rounded,
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildCardMetrica(
                "Coletas em Espera",
                "12",
                Icons.pending_actions_rounded,
                Colors.orange,
              ),
              const SizedBox(width: 16),
              _buildCardMetrica(
                "Estafetas na Rua",
                "8",
                Icons.motorcycle_rounded,
                Colors.green,
              ),
            ],
          ),

          const SizedBox(height: 32),
          const Text(
            "Últimas Atualizações de Rotas",
            // 💡 Corrigido de black70 para black87 (que existe nativamente no Flutter)
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Center(
                child: Text(
                  "Gráfico de Monitoramento em Tempo Real (Aguardando Integração) 🧪",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardMetrica(
    String titulo,
    String valor,
    IconData icone,
    Color cor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              // 💡 Corrigido de 'cor:' para 'color:' (Parâmetro nativo do BoxDecoration)
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icone, color: cor, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}
