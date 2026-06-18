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
    // 💡 Precisa receber o CS aqui ou ter acesso a ele
    isLoading.value = true;
    try {
      final lista = await _repository.obterEntregadoresAtivos();
      entregadoresAtivos.value = lista;
      _atualizarMarcadores(
        lista,
        cs,
      ); // 💡 O segundo argumento estava faltando!
    } catch (e) {
      debugPrint("Erro ao carregar entregadores: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _atualizarMarcadores(List<Entregador> lista, ColorScheme cs) {
    marcadores.value = lista
        .map(
          (e) => Marker(
            markerId: MarkerId(e.id),
            position: e.localizacao,
            // Usamos a cor terciária vinda do esquema de cores, não um número fixo!
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _converterColorToHue(cs.tertiary),
            ),
            infoWindow: InfoWindow(title: e.nome),
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
