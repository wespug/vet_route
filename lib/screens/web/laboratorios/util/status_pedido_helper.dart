import 'package:flutter/material.dart';

class StatusPedidoHelper {
  // Trata 'EM_SEPARACAO' para 'Em Separação', 'AGUARDANDO_COLETA' para 'Aguardando Coleta', etc.
  static String obterLabelStatus(String status) {
    if (status.isEmpty) return '-';

    final s = status.toLowerCase();

    if (s == 'em_separacao' || s == 'em separação' || s == 'em separacao') {
      return 'Em Separação';
    }
    if (s == 'aguardando_coleta' || s == 'aguardando coleta') {
      return 'Aguardando Coleta';
    }
    if (s == 'aguardando_entregador' || s == 'aguardando entregador') {
      return 'Aguardando Entregador';
    }
    if (s == 'recusado') return 'Recusado';
    if (s == 'cancelado') return 'Cancelado';
    if (s == 'entregue') return 'Entregue';
    if (s == 'pendente') return 'Pendente';

    // Fallback: substitui underline e capitaliza
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }

  // Cor do Texto
  static Color obterCorStatus(String status) {
    final s = status.toLowerCase();
    if (s.contains('separacao') || s.contains('separação')) {
      return Colors.indigo.shade800; // Azul/Índigo forte
    }
    if (s.contains('entregador') || s.contains('coleta')) {
      return Colors.amber.shade900; // Laranja/Âmbar
    }
    if (s == 'pendente') {
      return Colors.orange.shade900;
    }
    if (s == 'recusado' || s == 'cancelado') {
      return Colors.red.shade800; // Vermelho
    }
    if (s == 'entregue') {
      return Colors.green.shade800; // Verde
    }
    return Colors.grey.shade800;
  }

  // Cor de Fundo da Tag (Chip)
  static Color obterCorFundoStatus(String status) {
    final s = status.toLowerCase();
    if (s.contains('separacao') || s.contains('separação')) {
      return Colors.indigo.shade50; // Fundo Azul Suave
    }
    if (s.contains('entregador') || s.contains('coleta')) {
      return Colors.amber.shade100;
    }
    if (s == 'pendente') {
      return Colors.orange.shade100;
    }
    if (s == 'recusado' || s == 'cancelado') {
      return Colors.red.shade50; // Fundo Vermelho Suave
    }
    if (s == 'entregue') {
      return Colors.green.shade50;
    }
    return Colors.grey.shade200;
  }

  // Ícones representativos
  static IconData obterIconeStatus(String status) {
    final s = status.toLowerCase();
    if (s.contains('separacao') || s.contains('separação')) {
      return Icons.inventory_2_outlined;
    }
    if (s.contains('entregador') || s.contains('coleta')) {
      return Icons.two_wheeler_rounded;
    }
    if (s == 'recusado' || s == 'cancelado') {
      return Icons.cancel_outlined;
    }
    if (s == 'entregue') {
      return Icons.check_circle_outline;
    }
    return Icons.access_time_rounded;
  }
}
