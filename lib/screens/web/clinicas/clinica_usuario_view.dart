import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 💡 NOVO: Importação para usar o Clipboard
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/controllers/perfil_controller.dart';
import 'package:vet_route/models/clinica_model.dart';

class UsuariosClinicaView extends StatefulWidget {
  final Clinica clinicaContexto;
  final String chavePermissao;

  const UsuariosClinicaView({
    super.key,
    required this.clinicaContexto,
    required this.chavePermissao,
  });

  @override
  State<UsuariosClinicaView> createState() => _UsuariosClinicaViewState();
}

class _UsuariosClinicaViewState extends State<UsuariosClinicaView> {
  final PerfilController _perfilController = PerfilController();

  String _termoBusca = '';
  int _colunaOrdenacaoIndex = 0;
  bool _ordemCrescente = true;
  int _linhasPorPagina = PaginatedDataTable.defaultRowsPerPage;

  @override
  void initState() {
    super.initState();
    _perfilController.carregarPerfis();
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

  void _ordenar<T>(
    Comparable<T> Function(Map<String, dynamic> data) getField,
    int columnIndex,
    bool ascending,
  ) {
    setState(() {
      _colunaOrdenacaoIndex = columnIndex;
      _ordemCrescente = ascending;
    });
  }

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Operadores da Clínica 👥",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Gestão de acessos ao painel de ${widget.clinicaContexto.nome}",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _abrirModalCaixaUsuario(context),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text(
                  "Novo Usuário",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por nome ou e-mail...',
              prefixIcon: const Icon(Icons.search, color: Colors.teal),
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
                borderSide: const BorderSide(color: Colors.teal, width: 2),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _termoBusca = value;
              });
            },
          ),
          const SizedBox(height: 16),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .where('vinculoId', isEqualTo: widget.clinicaContexto.id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
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
                          "Nenhum operador vinculado a esta clínica.",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListenableBuilder(
                  listenable: _perfilController,
                  builder: (context, child) {
                    List<QueryDocumentSnapshot> docsFiltrados = snapshot
                        .data!
                        .docs
                        .where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final nome = (data['nome'] ?? '')
                              .toString()
                              .toLowerCase();
                          final email = (data['email'] ?? '')
                              .toString()
                              .toLowerCase();
                          final termo = _termoBusca.toLowerCase();
                          return nome.contains(termo) || email.contains(termo);
                        })
                        .toList();

                    docsFiltrados.sort((a, b) {
                      final dataA = a.data() as Map<String, dynamic>;
                      final dataB = b.data() as Map<String, dynamic>;

                      int comparacao = 0;
                      switch (_colunaOrdenacaoIndex) {
                        case 0:
                          comparacao = (dataA['nome'] ?? '').compareTo(
                            dataB['nome'] ?? '',
                          );
                          break;
                        case 1:
                          comparacao = (dataA['email'] ?? '').compareTo(
                            dataB['email'] ?? '',
                          );
                          break;
                        case 2:
                          final perfilA = _obterNomeDoPerfil(dataA['perfilId']);
                          final perfilB = _obterNomeDoPerfil(dataB['perfilId']);
                          comparacao = perfilA.compareTo(perfilB);
                          break;
                        case 3:
                          final statusA = dataA['ativo'] ?? false ? 1 : 0;
                          final statusB = dataB['ativo'] ?? false ? 1 : 0;
                          comparacao = statusA.compareTo(statusB);
                          break;
                      }
                      return _ordemCrescente ? comparacao : -comparacao;
                    });

                    final dataSource = _UsuarioDataSource(
                      context: context,
                      docs: docsFiltrados,
                      obterNomePerfil: _obterNomeDoPerfil,
                      onEdit: (doc) =>
                          _abrirModalCaixaUsuario(context, usuarioDoc: doc),
                      onDelete: (doc, nome) =>
                          _confirmarExclusaoUsuario(context, doc, nome),
                    );

                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: PaginatedDataTable(
                          header: const Text(
                            "Lista de Operadores",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          rowsPerPage: _linhasPorPagina,
                          availableRowsPerPage: const [5, 10, 20, 50],
                          onRowsPerPageChanged: (value) {
                            setState(() {
                              _linhasPorPagina =
                                  value ??
                                  PaginatedDataTable.defaultRowsPerPage;
                            });
                          },
                          sortColumnIndex: _colunaOrdenacaoIndex,
                          sortAscending: _ordemCrescente,
                          columns: [
                            DataColumn(
                              label: const Text(
                                'Nome do Operador',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onSort: (columnIndex, ascending) => _ordenar(
                                (data) => data['nome'] ?? '',
                                columnIndex,
                                ascending,
                              ),
                            ),
                            DataColumn(
                              label: const Text(
                                'E-mail de Login',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onSort: (columnIndex, ascending) => _ordenar(
                                (data) => data['email'] ?? '',
                                columnIndex,
                                ascending,
                              ),
                            ),
                            DataColumn(
                              label: const Text(
                                'Perfil de Acesso',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onSort: (columnIndex, ascending) => _ordenar(
                                (data) => _obterNomeDoPerfil(data['perfilId']),
                                columnIndex,
                                ascending,
                              ),
                            ),
                            DataColumn(
                              label: const Text(
                                'Status',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onSort: (columnIndex, ascending) => _ordenar(
                                (data) => data['ativo'] ?? false ? 1 : 0,
                                columnIndex,
                                ascending,
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Ações',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          source: dataSource,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
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
                    color: Colors.teal,
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
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.teal.shade100),
                          ),
                          child: Text(
                            "🔒 Vínculo Corporativo Automatizado:\n${widget.clinicaContexto.nome}",
                            style: TextStyle(
                              color: Colors.teal.shade800,
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

                        if (!isEdicao) ...[
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
                          const SizedBox(height: 16),
                        ],

                        ListenableBuilder(
                          listenable: _perfilController,
                          builder: (context, child) {
                            final perfisPermitidosParaClinica =
                                _perfilController.perfis.where((perfil) {
                                  return perfil.exibirEm.contains(
                                    widget.chavePermissao,
                                  );
                                }).toList();

                            return DropdownButtonFormField<String>(
                              value: idPerfilSelecionado,
                              decoration: const InputDecoration(
                                labelText: "Perfil Operacional / Permissões",
                                prefixIcon: Icon(Icons.gpp_good_outlined),
                              ),
                              items: perfisPermitidosParaClinica.map((perfil) {
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
                                    'vinculoId': widget.clinicaContexto.id,
                                    'ativo': true,
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
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Falha: $e"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
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
                    backgroundColor: Colors.teal,
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

class _UsuarioDataSource extends DataTableSource {
  final BuildContext context;
  final List<QueryDocumentSnapshot> docs;
  final String Function(String?) obterNomePerfil;
  final Function(DocumentSnapshot) onEdit;
  final Function(DocumentSnapshot, String) onDelete;

  _UsuarioDataSource({
    required this.context,
    required this.docs,
    required this.obterNomePerfil,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= docs.length) return null;
    final doc = docs[index];
    final data = doc.data() as Map<String, dynamic>;
    final bool ativo = data['ativo'] ?? false;
    final String? perfilId = data['perfilId'];
    final String email =
        data['email'] ?? 'Sem e-mail'; // 💡 Email extraído aqui

    return DataRow(
      cells: [
        DataCell(
          Text(
            data['nome'] ?? 'Sem nome',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.teal,
            ),
          ),
        ),
        // 💡 NOVO: Célula de E-mail com botão de cópia
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(email),
              const SizedBox(width: 8),
              if (email != 'Sem e-mail')
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: email));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('E-mail $email copiado!'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: Colors.teal,
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              obterNomePerfil(perfilId),
              style: TextStyle(
                fontSize: 12,
                color: Colors.teal.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ativo ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: ativo ? Colors.green.shade200 : Colors.red.shade200,
              ),
            ),
            child: Text(
              ativo ? "Ativo" : "Inativo",
              style: TextStyle(
                color: ativo ? Colors.green.shade700 : Colors.red.shade700,
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
                icon: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                tooltip: "Editar Operador",
                onPressed: () => onEdit(doc),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
                tooltip: "Excluir Operador",
                onPressed: () => onDelete(doc, data['nome'] ?? 'este operador'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => docs.length;

  @override
  int get selectedRowCount => 0;
}
