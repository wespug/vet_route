import 'package:flutter/material.dart';

class ListaLaboratoriosView extends StatelessWidget {
  const ListaLaboratoriosView({super.key});

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
              const Text(
                "Laboratórios Credenciados 🔬",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text("Vincular Novo"),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                columns: const [
                  DataColumn(
                    label: Text(
                      'Nome do Laboratório',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Localização',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: [
                  _buildRow("Lab Vet Central", "São Paulo - SP", true),
                  _buildRow("Biotech Diagnósticos", "Campinas - SP", true),
                  _buildRow(
                    "Análises Clínicas Animal",
                    "Rio de Janeiro - RJ",
                    false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildRow(String nome, String cidade, bool ativo) {
    return DataRow(
      cells: [
        DataRow(
          cells: [
            DataCell(
              Text(nome, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            DataCell(Text(cidade)),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ativo ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ativo ? "Ativo" : "Inativo",
                  style: TextStyle(
                    color: ativo ? Colors.green.shade700 : Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ).cells[0],
        DataRow(
          cells: [
            DataCell(Text(nome)),
            DataCell(Text(cidade)),
            DataCell(Text(ativo.toString())),
          ],
        ).cells[1],
        DataRow(
          cells: [
            DataCell(Text(nome)),
            DataCell(Text(cidade)),
            DataCell(Text(ativo.toString())),
          ],
        ).cells[2],
      ],
    );
  }
}
