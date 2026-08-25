import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vet_route/models/coleta_model.dart';
import 'package:vet_route/controllers/coleta_controller.dart';

class ConfirmarRecusaDialog extends StatelessWidget {
  final Coleta item;

  const ConfirmarRecusaDialog({super.key, required this.item});

  static void exibir(BuildContext context, Coleta item) {
    showDialog(
      context: context,
      builder: (context) => ConfirmarRecusaDialog(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Recusar Pedido"),
      content: Text(
        "Deseja mover o pedido ${item.codigo} para finalizados/recusados?",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            final controller = Provider.of<ColetaController>(
              context,
              listen: false,
            );
            await controller.recusarColeta(item.id);
          },
          child: const Text(
            "Recusar",
            style: TextStyle(
              color: Color(0xFFFF3B30),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
