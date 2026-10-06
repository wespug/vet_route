import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/entregador_model.dart';
import '../models/perfil_usuario.dart';
import '../repositories/firestore_coleta_repository.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EntregadorController {
  final FirestoreColetaRepository? _repository;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription? _rastreioGPS;

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
  // 🟢 MÉTODOS DE ADMINISTRAÇÃO WEB (CRUD NO FIRESTORE + AUTH)
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
      // 💡 1. Cria a conta no Firebase Authentication de forma isolada
      FirebaseApp appSecundario = await Firebase.initializeApp(
        name: 'CriadorMotoboyAdmin',
        options: Firebase.app().options,
      );

      UserCredential credencial =
          await FirebaseAuth.instanceFor(
            app: appSecundario,
          ).createUserWithEmailAndPassword(
            email: entregador.email,
            password:
                entregador.senha ?? '123456', // Usa a senha digitada no form
          );

      final novoUid = credencial.user!.uid;

      // 💡 2. Salva no banco de dados vinculando ao UID oficial do Auth
      await _db.collection('usuarios').doc(novoUid).set({
        ...entregador.toMap(),
        'id': novoUid,
        'ativo': true,
      });

      await appSecundario
          .delete(); // Limpa a instância para não deslogar o painel

      await carregarEntregadores();
      return true;
    } catch (e) {
      debugPrint('Erro ao salvar entregador no Auth/DB: $e');
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

  // =========================================================================
  // 📍 RASTREIO INTELIGENTE (ATIVADO NA RECOLHA, DESLIGADO NA ENTREGA)
  // =========================================================================
  Future iniciarRastreioInteligente(String entregadorId) async {
    // Trava de segurança: Se já estiver a rastrear, não duplica o serviço
    if (_rastreioGPS != null) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // 💡 FILTRO DE ECONOMIA: Só envia para a nuvem se a mota andar 100 metros
    const LocationSettings configuracaoGPS = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );

    debugPrint("🟢 [GPS] Rastreio Inteligente Iniciado para a viagem!");

    _rastreioGPS =
        Geolocator.getPositionStream(locationSettings: configuracaoGPS).listen((
          Position position,
        ) {
          // Grava a coordenada na coleção 'usuarios' onde o perfil do motoboy vive
          _db
              .collection('usuarios')
              .doc(entregadorId)
              .set({
                'latitudeAtual': position.latitude,
                'longitudeAtual': position.longitude,
                'ultimaAtualizacaoGPS': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true))
              .catchError((e) {
                debugPrint("Erro ao atualizar GPS do motoboy: $e");
              });
        });
  }

  void pararRastreio() {
    _rastreioGPS?.cancel();
    _rastreioGPS = null;
    debugPrint("🛑 [GPS] Viagem concluída. Rastreio Desligado.");
  }

  void dispose() {
    isLoading.dispose();
    todosEntregadores.dispose();
    entregadoresAtivos.dispose();
    marcadores.dispose();
  }
}
