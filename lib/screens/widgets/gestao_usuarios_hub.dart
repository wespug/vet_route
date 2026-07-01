import 'package:flutter/material.dart';
import 'package:vet_route/controllers/usuario_controller.dart';
import 'package:vet_route/controllers/perfil_controller.dart';
import 'package:vet_route/models/usuario_model.dart';

class GestaoUsuarioHub extends StatefulWidget {
  const GestaoUsuarioHub({super.key});

  @override
  State<GestaoUsuarioHub> createState() => _GestaoUsuarioHubState();
}

class _GestaoUsuarioHubState extends State<GestaoUsuarioHub> {
  final UsuarioController _usuarioController = UsuarioController();
  final PerfilController _perfilController = PerfilController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _vinculoIdController = TextEditingController();
  final TextEditingController _senhaController =
      TextEditingController(); // <-- Novo: Controlador de Senha

  String? _usuarioEdicaoId;
  String? _perfilSelecionado;
  bool _isAtivo = true;

  @override
  void initState() {
    super.initState();
    _usuarioController.carregarUsuarios();
    _perfilController.carregarPerfis();
    _vinculoIdController.text = '1'; // <-- Padrão inicial
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _vinculoIdController.dispose();
    _senhaController.dispose();
    _usuarioController.dispose();
    _perfilController.dispose();
    super.dispose();
  }

  void _entrarModoEdicao(UsuarioModel user) {
    setState(() {
      _usuarioEdicaoId = user.id;
      _nomeController.text = user.nome;
      _emailController.text = user.email;
      _vinculoIdController.text = user.vinculoId ?? '1';
      _senhaController.clear(); // Limpa para não mostrar a senha antiga
      _perfilSelecionado = user.perfilId;
      _isAtivo = user.ativo;
    });
  }

  void _limparFormulario() {
    setState(() {
      _usuarioEdicaoId = null;
      _nomeController.clear();
      _emailController.clear();
      _senhaController.clear();
      _vinculoIdController.text = '1'; // <-- Retorna ao padrão
      _perfilSelecionado = null;
      _isAtivo = true;
    });
  }

  String _obterNomePerfil(String perfilId) {
    try {
      return _perfilController.perfis.firstWhere((p) => p.id == perfilId).nome;
    } catch (e) {
      return 'Perfil Órfão';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditando = _usuarioEdicaoId != null;

    return ListenableBuilder(
      listenable: Listenable.merge([_usuarioController, _perfilController]),
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Gestão de Utilizadores",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isEditando
                    ? "A editar utilizador selecionado..."
                    : "Controlo de acessos global e vínculo de perfis.",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),

              // PAINEL DE FORMULÁRIO
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isEditando
                      ? Colors.blue.shade50.withValues(alpha: 0.4)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isEditando
                        ? Colors.blue.shade200
                        : Colors.grey.shade200,
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _nomeController,
                              decoration: InputDecoration(
                                labelText: "Nome Completo",
                                prefixIcon: const Icon(Icons.person_outline),
                                fillColor: Colors.white,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? "Obrigatório"
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: "E-mail de Acesso",
                                prefixIcon: const Icon(Icons.alternate_email),
                                fillColor: Colors.white,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (v) => v == null || !v.contains("@")
                                  ? "E-mail inválido"
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              initialValue: _perfilSelecionado,
                              decoration: InputDecoration(
                                labelText: "Perfil / Cargo",
                                prefixIcon: const Icon(Icons.badge_outlined),
                                fillColor: Colors.white,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: _perfilController.perfis
                                  .map(
                                    (p) => DropdownMenuItem(
                                      value: p.id,
                                      child: Text(p.nome),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _perfilSelecionado = val),
                              validator: (v) => v == null ? "Selecione" : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Switch(
                            value: _isAtivo,
                            activeThumbColor: Colors.green,
                            onChanged: (val) => setState(() => _isAtivo = val),
                          ),
                          Text(
                            _isAtivo ? "Ativo" : "Inativo",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isAtivo ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _vinculoIdController,
                              decoration: InputDecoration(
                                labelText: "ID Vínculo",
                                prefixIcon: const Icon(Icons.link),
                                fillColor: Colors.white,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? "Obrigatório"
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _senhaController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: isEditando
                                    ? "Nova Senha (Opcional)"
                                    : "Senha de Acesso",
                                prefixIcon: const Icon(Icons.lock_outline),
                                fillColor: Colors.white,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (v) {
                                // Exige senha se for um usuário novo
                                if (!isEditando &&
                                    (v == null || v.trim().isEmpty)) {
                                  return "Senha inicial obrigatória";
                                }
                                // Bloqueia senhas menores que 6 caracteres
                                if (v != null &&
                                    v.isNotEmpty &&
                                    v.trim().length < 6) {
                                  return "Mínimo de 6 caracteres";
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (isEditando)
                            TextButton(
                              onPressed: _limparFormulario,
                              child: const Text(
                                "Cancelar",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _usuarioController.carregando
                                ? null
                                : _processarFormulario,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isEditando
                                  ? Colors.blue.shade700
                                  : Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                            icon: Icon(
                              isEditando ? Icons.save : Icons.add,
                              color: Colors.white,
                            ),
                            label: Text(
                              isEditando ? "Guardar" : "Cadastrar",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // TABELA
              Expanded(
                child:
                    _usuarioController.carregando ||
                        _perfilController.carregando
                    ? const Center(child: CircularProgressIndicator())
                    : _buildTabelaUsuarios(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _processarFormulario() async {
    if (_formKey.currentState!.validate() && _perfilSelecionado != null) {
      await _usuarioController.salvarUsuario(
        _usuarioEdicaoId ?? '',
        _nomeController.text.trim(),
        _emailController.text.trim(),
        _senhaController.text.trim(), // <-- Passando a Senha
        _perfilSelecionado!,
        _vinculoIdController.text.trim(),
        _isAtivo,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Operação concluída!"),
            backgroundColor: Colors.green,
          ),
        );
      }
      _limparFormulario();
    }
  }

  Widget _buildTabelaUsuarios() {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
          columns: const [
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Nome')),
            DataColumn(label: Text('E-mail')),
            DataColumn(label: Text('Perfil')),
            DataColumn(label: Text('Vínculo')), // <-- Nova Coluna!
            DataColumn(label: Text('Ações')),
          ],
          rows: _usuarioController.usuarios.map((user) {
            return DataRow(
              cells: [
                DataCell(
                  Icon(
                    user.ativo ? Icons.check_circle : Icons.cancel,
                    color: user.ativo ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ),
                DataCell(
                  Text(
                    user.nome,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(Text(user.email)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _obterNomePerfil(user.perfilId),
                      style: const TextStyle(
                        color: Colors.indigo,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(user.vinculoId ?? '1')), // <-- Mostra o Vínculo!
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.blue,
                          size: 20,
                        ),
                        onPressed: () => _entrarModoEdicao(user),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () => _confirmarExclusao(user.id),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  void _confirmarExclusao(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remover Usuário?"),
        content: const Text(
          "Tem certeza que deseja apagar este usuário do sistema?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              await _usuarioController.excluirUsuario(id);
            },
            child: const Text("Remover", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
