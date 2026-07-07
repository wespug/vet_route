import 'package:flutter/material.dart';

class ClinicaGestaoWeb extends StatefulWidget {
  const ClinicaGestaoWeb({super.key});

  @override
  State<ClinicaGestaoWeb> createState() => _ClinicaGestaoWebState();
}

class _ClinicaGestaoWebState extends State<ClinicaGestaoWeb> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Gestão de Clínicas 🏥",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Gerencie as clínicas parceiras e acesse seus painéis individuais.",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Abrir modal de cadastro de nova clínica
                },
                icon: const Icon(Icons.add_business_rounded),
                label: const Text(
                  "Nova Clínica",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  backgroundColor: Colors
                      .teal, // Uma cor diferente para diferenciar de laboratórios
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // TODO: Implementar a tabela com StreamBuilder buscando do Firestore
          Expanded(
            child: Center(
              child: Text(
                "Tabela de Clínicas entrará aqui em breve...",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
