// lib/repositories/firestore_coleta_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vet_route/models/endereco_model.dart';
import '../models/clinica_model.dart';
import '../models/laboratorio_model.dart';
import '../models/coleta_model.dart';
import 'coleta_repository.dart';

class FirestoreColetaRepository implements ColetaRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<Clinica> obterClinicaLogada() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("Nenhum usuário autenticado no Firebase Auth!");
    }

    // 💡 LOG CIRÚRGICO DE DEBUG:
    debugPrint(
      "🔍 DEBUG: O App está procurando na coleção 'clinicas' pelo documento com ID: ${user.uid}",
    );

    final doc = await _firestore.collection('clinicas').doc(user.uid).get();

    if (!doc.exists) {
      debugPrint("❌ DEBUG: Documento ${user.uid} NÃO EXISTE no Firestore!");
      throw Exception(
        "Perfil da clínica não encontrado para o UID: ${user.uid}",
      );
    }

    return Clinica.fromFirestore(doc);
  }

  @override
  Future<Laboratorio> obterLaboratorioPadrao() async {
    // 1. Obtém o utilizador atualmente autenticado
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("Nenhum utilizador autenticado no Firebase Auth!");
    }

    // 2. Vai à coleção 'laboratorios' e busca o documento com o UID dele
    final doc = await _firestore.collection('laboratorios').doc(user.uid).get();

    if (!doc.exists) {
      throw Exception(
        "Perfil de laboratório não encontrado para o UID: ${user.uid}",
      );
    }

    // 3. Retorna o objeto real mapeado da nuvem com o lat/long da Liberdade!
    return Laboratorio.fromFirestore(doc);
  }

  @override
  Future<List<Coleta>> buscarColetasNoRadar() async => [];

  @override
  Future<void> solicitarColeta(Coleta novaColeta) async {}
}
