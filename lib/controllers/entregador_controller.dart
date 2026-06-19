import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/entregador_model.dart';
import '../repositories/firestore_coleta_repository.dart';

class EntregadorController {
  final FirestoreColetaRepository _repository;

  final ValueNotifier<List<Entregador>> entregadoresAtivos = ValueNotifier([]);
  final ValueNotifier<Set<Marker>> marcadores = ValueNotifier({});
  final ValueNotifier<bool> isLoading = ValueNotifier(true);

  EntregadorController(this._repository);

  Future<void> inicializarRadar(ColorScheme cs) async {
    isLoading.value = true;
    try {
      // 💡 Atenção: Certifique-se de que o método obterEntregadoresAtivos
      // foi criado lá no seu FirestoreColetaRepository!
      final lista = await _repository.obterEntregadoresAtivos();
      entregadoresAtivos.value = lista;
      _atualizarMarcadores(lista, cs);
    } catch (e) {
      debugPrint("Erro ao carregar entregadores: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _atualizarMarcadores(List<Entregador> lista, ColorScheme cs) {
    marcadores.value = lista
        .map(
          // 💡 É AQUI QUE O "e" NASCE! Ele representa 1 entregador da lista.
          (e) => Marker(
            markerId: MarkerId(
              e.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
            ),
            position: e.localizacao,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _converterColorToHue(cs.tertiary),
            ),
            // 💡 O INFO WINDOW FICA AQUI DENTRO DO MARKER!
            infoWindow: InfoWindow(title: e.nome, snippet: e.veiculo),
          ),
        )
        .toSet();
  }

  double _converterColorToHue(Color color) {
    return HSVColor.fromColor(color).hue;
  }

  void dispose() {
    entregadoresAtivos.dispose();
    marcadores.dispose();
    isLoading.dispose();
  }
}
