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
import 'package:flutter/material.dart';

class EntregadorController extends ChangeNotifier {
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
  // =========================================================================
  // 📍 RASTREIO INTELIGENTE (ATIVADO NA RECOLHA, DESLIGADO NA ENTREGA)
  // =========================================================================
  // =========================================================================
  // 📍 RASTREIO INTELIGENTE (ATIVADO NA RECOLHA, DESLIGADO NA ENTREGA)
  // =========================================================================
  Future iniciarRastreioInteligente(String entregadorId) async {
    debugPrint("🚀 [GPS] Iniciando tentativa de rastreio para: $entregadorId");

    if (_rastreioGPS != null) {
      debugPrint(
        "⚠️️ [GPS] O rastreio já estava ativo. Abortando nova inicialização.",
      );
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint(
        "❌ [GPS] Serviço de localização (GPS) está desligado no aparelho!",
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      debugPrint("⚠️ [GPS] Permissão negada, solicitando ao usuário...");
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint("❌ [GPS] O usuário negou a permissão de localização.");
        return;
      }
    }

    // 💡 O "Empurrão" Inicial com Logs e Timeout (limite de 7 segundos)
    try {
      debugPrint("⏳ [GPS] Solicitando posição inicial ao satélite...");

      Position posicaoInicial =
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).timeout(
            const Duration(seconds: 7),
            onTimeout: () {
              throw Exception(
                "Timeout: O satélite demorou mais de 7 segundos para responder.",
              );
            },
          );

      debugPrint(
        "✅ [GPS] Posição recebida! Lat: \({posicaoInicial.latitude}, Lng:\){posicaoInicial.longitude}",
      );
      debugPrint("⏳ [GPS] Salvando coordenada inicial no Firebase...");

      await _db.collection('usuarios').doc(entregadorId).set({
        'latitudeAtual': posicaoInicial.latitude,
        'longitudeAtual': posicaoInicial.longitude,
        'ultimaAtualizacaoGPS': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint("🟢 [GPS] SUCESSO! Sinal inicial forçado no Firebase.");
    } catch (e) {
      debugPrint("❌ [GPS] FALHA NO EMPURRÃO INICIAL: $e");
    }

    // 💡 FILTRO DE ECONOMIA: A partir de agora, só envia se a mota andar 100 metros
    const LocationSettings configuracaoGPS = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );

    debugPrint(
      "🛣️ [GPS] Ligando o radar de viagem (100m de distância mínima)...",
    );

    _rastreioGPS =
        Geolocator.getPositionStream(locationSettings: configuracaoGPS).listen((
          Position position,
        ) {
          debugPrint(
            "📡 [GPS-MOVIMENTO] Andou 100m! Atualizando Firebase: \({position.latitude},\){position.longitude}",
          );

          _db
              .collection('usuarios')
              .doc(entregadorId)
              .set({
                'latitudeAtual': position.latitude,
                'longitudeAtual': position.longitude,
                'ultimaAtualizacaoGPS': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true))
              .catchError((e) {
                debugPrint("❌ [GPS-MOVIMENTO] Erro ao gravar no Firebase: $e");
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
