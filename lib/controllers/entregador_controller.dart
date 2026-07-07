import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/entregador_model.dart';
import '../models/perfil_usuario.dart';
import '../repositories/firestore_coleta_repository.dart';

class EntregadorController {
  final FirestoreColetaRepository? _repository;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- ESTADOS REATIVOS (COMPARTILHADOS) ---
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  // --- ESTADOS REATIVOS (USO DO ADMIN) ---
  final ValueNotifier<List<Entregador>> todosEntregadores =
      ValueNotifier<List<Entregador>>([]);

  // --- ESTADOS REATIVOS (USO DO MOBILE/APP) ---
  final ValueNotifier<List<Entregador>> entregadoresAtivos = ValueNotifier([]);
  final ValueNotifier<Set<Marker>> marcadores = ValueNotifier({});

  // 💡 Construtor com repositório opcional: o App usa, o Admin não.
  EntregadorController([this._repository]);

  // =========================================================================
  // 🟢 MÉTODOS DE ADMINISTRAÇÃO WEB (CRUD NO FIRESTORE)
  // =========================================================================

  Future<void> carregarEntregadores() async {
    isLoading.value = true;
    try {
      final snapshot = await _db
          .collection('usuarios')
          .where(
            'perfil',
            isEqualTo: PerfilUsuario.entregadores.toFirestoreString,
          )
          .get();

      todosEntregadores.value = snapshot.docs
          .map((doc) => Entregador.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Erro ao carregar entregadores: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> salvarEntregador(Entregador entregador) async {
    isLoading.value = true;
    try {
      await _db.collection('usuarios').add(entregador.toMap());
      await carregarEntregadores();
      return true;
    } catch (e) {
      debugPrint('Erro ao salvar entregador: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> atualizarEntregador(String id, Entregador entregador) async {
    isLoading.value = true;
    try {
      await _db.collection('usuarios').doc(id).update(entregador.toMap());
      await carregarEntregadores();
      return true;
    } catch (e) {
      debugPrint('Erro ao atualizar entregador: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deletarEntregador(String id) async {
    isLoading.value = true;
    try {
      await _db.collection('usuarios').doc(id).delete();
      await carregarEntregadores();
      return true;
    } catch (e) {
      debugPrint('Erro ao deletar entregador: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================================
  // 🔵 MÉTODOS MOBILE / APP
  // =========================================================================

  Future<void> inicializarRadar(ColorScheme cs) async {
    if (_repository == null) return;

    isLoading.value = true;
    try {
      final lista = await _repository!.obterEntregadoresAtivos();
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
          (e) => Marker(
            markerId: MarkerId(
              e.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _converterColorToHue(cs.tertiary),
            ),
            infoWindow: InfoWindow(
              title: e.nome,
              snippet: e.veiculo?.modelo ?? 'Veículo não informado',
            ),
          ),
        )
        .toSet();
  }

  double _converterColorToHue(Color color) {
    return HSVColor.fromColor(color).hue;
  }

  void dispose() {
    isLoading.dispose();
    todosEntregadores.dispose();
    entregadoresAtivos.dispose();
    marcadores.dispose();
  }
}
