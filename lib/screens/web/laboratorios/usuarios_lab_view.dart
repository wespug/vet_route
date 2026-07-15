import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../controllers/perfil_controller.dart';
import '../../../models/laboratorio_model.dart';

class UsuariosLabView extends StatefulWidget {
  final Laboratorio labContexto;
  final String chavePermissao;

  const UsuariosLabView({
    super.key,
    required this.labContexto,
    required this.chavePermissao,
  });

  @override
  State<UsuariosLabView> createState() => _UsuariosLabViewState();
}

class _UsuariosLabViewState extends State<UsuariosLabView> {
  final PerfilController _perfilController = PerfilController();

  // 💡 MÁGICA CONTRA A PISCADINHA: Stream salvo na memória!
  late Stream<QuerySnapshot> _usuariosStream;

  // 🔎 VARIÁVEIS DE BUSCA, ORDENAÇÃO E PAGINAÇÃO LIMPA
  String _searchQuery = '';
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  int _sortColumnIndex = 0;
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    _perfilController.carregarPerfis();

    // Conectamos ao Firebase APENAS UMA VEZ para não piscar a tela
    _usuariosStream = FirebaseFirestore.instance
        .collection('usuarios')
        .where('vinculoId', isEqualTo: widget.labContexto.id)
        .snapshots();
  }

  @override
  void dispose() {
    _perfilController.dispose();
    super.dispose();
  }

  String _obterNomeDoPerfil(String? perfilId) {
    if (perfilId == null || perfilId.isEmpty) return 'Sem Perfil';
    try {
      final perfil = _perfilController.perfis.firstWhere(
        (p) => p.id == perfilId,
      );
      return perfil.nome;
    } catch (e) {
      return 'Perfil Desconhecido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Força o tamanho compacto
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Operadores do Sistema 👥",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Lista de contas com acesso exclusivo ao painel de ${widget.labContexto.nome}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _abrirModalCaixaUsuario(context),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: const Text(
                    "Novo Operador",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 🔎 CAMPO DE BUSCA
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar operador por nome ou e-mail...',
                prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.indigo, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _currentPage = 0; // Reseta a página ao buscar
                });
              },
            ),
            const SizedBox(height: 24),

            // 💡 TABELA PAGINADA - ALIMENTADA PELO STREAM SALVO NA MEMÓRIA
            StreamBuilder<QuerySnapshot>(
              stream: _usuariosStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(48.0),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.indigo),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.group_off_rounded,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? "Nenhum operador encontrado para '$_searchQuery'."
                                : "Nenhum operador vinculado a este laboratório.",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListenableBuilder(
                  listenable: _perfilController,
                  builder: (context, child) {
                    // 1. APLICA A BUSCA MANTENDO OS DADOS EM MEMÓRIA
                    List<QueryDocumentSnapshot> docsFiltrados = snapshot
                        .data!
                        .docs
                        .where((doc) {
                          if (_searchQuery.isEmpty) return true;

                          final data = doc.data() as Map<String, dynamic>;
                          final nome = (data['nome'] ?? '')
                              .toString()
                              .toLowerCase();
                          final email = (data['email'] ?? '')
                              .toString()
                              .toLowerCase();
                          final termo = _searchQuery.toLowerCase();

                          return nome.contains(termo) || email.contains(termo);
                        })
                        .toList();

                    // 2. APLICA A ORDENAÇÃO LOCAL
                    docsFiltrados.sort((a, b) {
                      final dataA = a.data() as Map<String, dynamic>;
                      final dataB = b.data() as Map<String, dynamic>;

                      int result = 0;
                      switch (_sortColumnIndex) {
                        case 0:
                          String nomeA = (dataA['nome'] ?? '')
                              .toString()
                              .toLowerCase();
                          String nomeB = (dataB['nome'] ?? '')
                              .toString()
                              .toLowerCase();
                          result = nomeA.compareTo(nomeB);
                          break;
                        case 1:
                          String emailA = (dataA['email'] ?? '')
                              .toString()
                              .toLowerCase();
                          String emailB = (dataB['email'] ?? '')
                              .toString()
                              .toLowerCase();
                          result = emailA.compareTo(emailB);
                          break;
                        case 3:
                          int statusA = (dataA['ativo'] ?? false) ? 1 : 0;
                          int statusB = (dataB['ativo'] ?? false) ? 1 : 0;
                          result = statusA.compareTo(statusB);
                          break;
                        default:
                          String nomeDefaultA = (dataA['nome'] ?? '')
                              .toString()
                              .toLowerCase();
                          String nomeDefaultB = (dataB['nome'] ?? '')
                              .toString()
                              .toLowerCase();
                          result = nomeDefaultA.compareTo(nomeDefaultB);
                      }
                      return _isAscending ? result : -result;
                    });

                    // 3. APLICAR PAGINAÇÃO MANUAL E COMPACTA
                    int totalItems = docsFiltrados.length;
                    int totalPages = (totalItems / _itemsPerPage).ceil();
                    if (_currentPage >= totalPages && totalPages > 0) {
                      _currentPage = totalPages - 1;
                    }

                    int startIndex = _currentPage * _itemsPerPage;
                    int endIndex = startIndex + _itemsPerPage;
                    if (endIndex > totalItems) endIndex = totalItems;

                    List<QueryDocumentSnapshot> paginados =
                        docsFiltrados.isNotEmpty
                        ? docsFiltrados.sublist(startIndex, endIndex)
                        : [];

                    if (paginados.isEmpty && _searchQuery.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(48.0),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Nenhum operador corresponde à busca.",
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              sortColumnIndex: _sortColumnIndex,
                              sortAscending: _isAscending,
                              headingRowColor: WidgetStateProperty.all(
                                Colors.grey.shade50,
                              ),
                              columns: [
                                DataColumn(
                                  label: const Text(
                                    'Nome do Operador',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onSort: (col, asc) => setState(() {
                                    _sortColumnIndex = col;
                                    _isAscending = asc;
                                  }),
                                ),
                                DataColumn(
                                  label: const Text(
                                    'E-mail de Login',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onSort: (col, asc) => setState(() {
                                    _sortColumnIndex = col;
                                    _isAscending = asc;
                                  }),
                                ),
                                const DataColumn(
                                  label: Text(
                                    'Perfil de Acesso',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: const Text(
                                    'Status',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onSort: (col, asc) => setState(() {
                                    _sortColumnIndex = col;
                                    _isAscending = asc;
                                  }),
                                ),
                                const DataColumn(
                                  label: Text(
                                    'Ações',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              rows: paginados.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final bool ativo = data['ativo'] ?? false;
                                final String? perfilId = data['perfilId'];

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 12,
                                            backgroundColor:
                                                Colors.indigo.shade50,
                                            child: const Icon(
                                              Icons.person,
                                              size: 14,
                                              color: Colors.indigo,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            data['nome'] ?? 'Sem nome',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.indigo,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Text(data['email'] ?? 'Sem e-mail'),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.indigo.shade50,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          _obterNomeDoPerfil(perfilId),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.indigo.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: ativo
                                              ? Colors.green.shade50
                                              : Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: ativo
                                                ? Colors.green.shade200
                                                : Colors.red.shade200,
                                          ),
                                        ),
                                        child: Text(
                                          ativo ? "Ativo" : "Inativo",
                                          style: TextStyle(
                                            color: ativo
                                                ? Colors.green.shade700
                                                : Colors.red.shade700,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit_note_rounded,
                                              color: Colors.blue,
                                            ),
                                            tooltip: "Editar Operador",
                                            onPressed: () =>
                                                _abrirModalCaixaUsuario(
                                                  context,
                                                  usuarioDoc: doc,
                                                ),
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              color: Colors.redAccent,
                                            ),
                                            tooltip: "Excluir Operador",
                                            onPressed: () =>
                                                _confirmarExclusaoUsuario(
                                                  context,
                                                  doc,
                                                  data['nome'] ??
                                                      'este operador',
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                        // Controles de Paginação sem Operadores Complexos (...)
                        if (totalPages > 1) const SizedBox(height: 12),
                        if (totalPages > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                "Página ${_currentPage + 1} de $totalPages",
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.chevron_left_rounded,
                                      ),
                                      color: _currentPage > 0
                                          ? Colors.indigo
                                          : Colors.grey.shade300,
                                      onPressed: _currentPage > 0
                                          ? () => setState(() => _currentPage--)
                                          : null,
                                    ),
                                    Container(
                                      width: 1,
                                      height: 24,
                                      color: Colors.grey.shade300,
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.chevron_right_rounded,
                                      ),
                                      color: _currentPage < totalPages - 1
                                          ? Colors.indigo
                                          : Colors.grey.shade300,
                                      onPressed: _currentPage < totalPages - 1
                                          ? () => setState(() => _currentPage++)
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _abrirModalCaixaUsuario(
    BuildContext context, {
    DocumentSnapshot? usuarioDoc,
  }) {
    final bool isEdicao = usuarioDoc != null;
    final Map<String, dynamic>? dataAtual = isEdicao
        ? usuarioDoc.data() as Map<String, dynamic>?
        : null;

    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController(
      text: dataAtual?['nome'] ?? '',
    );
    final emailController = TextEditingController(
      text: dataAtual?['email'] ?? '',
    );
    final senhaController = TextEditingController();

    String? idPerfilSelecionado = dataAtual?['perfilId'];
    bool ativoSelecionado = dataAtual?['ativo'] ?? true;
    bool salvando = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: [
                  Icon(
                    isEdicao
                        ? Icons.manage_accounts_rounded
                        : Icons.person_add_alt_1_rounded,
                    color: Colors.indigo,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEdicao
                        ? "Editar Configurações"
                        : "Vincular Novo Operador",
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.indigo.shade100),
                          ),
                          child: Text(
                            "🔒 Vínculo Corporativo Automatizado:\n${widget.labContexto.nome}",
                            style: TextStyle(
                              color: Colors.indigo.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: nomeController,
                          decoration: const InputDecoration(
                            labelText: "Nome Completo do Operador",
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? "Campo obrigatório"
                              : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: emailController,
                          enabled: !isEdicao,
                          decoration: InputDecoration(
                            labelText: "E-mail de Login",
                            prefixIcon: const Icon(Icons.alternate_email),
                            filled: isEdicao,
                            fillColor: isEdicao ? Colors.grey.shade100 : null,
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? "Campo obrigatório"
                              : null,
                        ),
                        const SizedBox(height: 16),

                        if (!isEdicao)
                          TextFormField(
                            controller: senhaController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: "Senha Inicial (Mín. 6 caracteres)",
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: (v) => (v == null || v.length < 6)
                                ? "Mínimo de 6 dígitos"
                                : null,
                          ),
                        if (!isEdicao) const SizedBox(height: 16),

                        ListenableBuilder(
                          listenable: _perfilController,
                          builder: (context, child) {
                            final perfisPermitidosParaLab = _perfilController
                                .perfis
                                .where((perfil) {
                                  return perfil.exibirEm.contains(
                                    widget.chavePermissao,
                                  );
                                })
                                .toList();

                            return DropdownButtonFormField<String>(
                              value: idPerfilSelecionado,
                              decoration: const InputDecoration(
                                labelText: "Perfil Operacional / Permissões",
                                prefixIcon: Icon(Icons.gpp_good_outlined),
                              ),
                              items: perfisPermitidosParaLab.map((perfil) {
                                return DropdownMenuItem<String>(
                                  value: perfil.id,
                                  child: Text(perfil.nome),
                                );
                              }).toList(),
                              onChanged: (val) => setModalState(
                                () => idPerfilSelecionado = val,
                              ),
                              validator: (v) => v == null
                                  ? "Selecione um perfil de acesso"
                                  : null,
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        SwitchListTile(
                          title: const Text(
                            "Conta Ativa",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            ativoSelecionado
                                ? "O operador pode fazer login"
                                : "Acesso bloqueado",
                          ),
                          value: ativoSelecionado,
                          activeColor: Colors.green,
                          onChanged: (val) =>
                              setModalState(() => ativoSelecionado = val),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: salvando ? null : () => Navigator.pop(context),
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: salvando
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate() ||
                              idPerfilSelecionado == null)
                            return;
                          setModalState(() => salvando = true);

                          try {
                            if (isEdicao) {
                              await FirebaseFirestore.instance
                                  .collection('usuarios')
                                  .doc(usuarioDoc.id)
                                  .update({
                                    'nome': nomeController.text.trim(),
                                    'perfilId': idPerfilSelecionado,
                                    'ativo': ativoSelecionado,
                                  });
                            } else {
                              FirebaseApp appSecundario =
                                  await Firebase.initializeApp(
                                    name: 'CriadorUsuariosAdmin',
                                    options: Firebase.app().options,
                                  );
                              UserCredential credencial =
                                  await FirebaseAuth.instanceFor(
                                    app: appSecundario,
                                  ).createUserWithEmailAndPassword(
                                    email: emailController.text.trim(),
                                    password: senhaController.text.trim(),
                                  );
                              final novoUid = credencial.user!.uid;

                              await FirebaseFirestore.instance
                                  .collection('usuarios')
                                  .doc(novoUid)
                                  .set({
                                    'nome': nomeController.text.trim(),
                                    'email': emailController.text.trim(),
                                    'perfilId': idPerfilSelecionado,
                                    'vinculoId': widget.labContexto.id,
                                    'ativo': ativoSelecionado,
                                    'dataCriacao': FieldValue.serverTimestamp(),
                                  });
                              await appSecundario.delete();
                            }
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEdicao ? "Atualizado!" : "Cadastrado!",
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Falha: $e"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                          } finally {
                            setModalState(() => salvando = false);
                          }
                        },
                  icon: salvando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          isEdicao
                              ? Icons.check_circle_outline
                              : Icons.how_to_reg_rounded,
                          size: 18,
                        ),
                  label: Text(
                    salvando
                        ? "Processando..."
                        : (isEdicao ? "Atualizar" : "Confirmar"),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmarExclusaoUsuario(
    BuildContext context,
    DocumentSnapshot doc,
    String nomeUsuario,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text("Remover Acesso?"),
            ],
          ),
          content: Text("Tem certeza de que deseja excluir '$nomeUsuario'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () async {
                Navigator.pop(context);
                await FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(doc.id)
                    .delete();
              },
              child: const Text(
                "Excluir",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
