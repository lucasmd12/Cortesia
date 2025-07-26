import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/services/admin_service.dart';
import 'package:lucasbeatsfederacao/services/clan_service.dart';
import 'package:lucasbeatsfederacao/utils/custom_snackbar.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

const Size _originalMapSize = Size(2048, 1024);

class CreateClanTerritoryScreen extends StatefulWidget {
  final String federationId;
  final Offset initialMapCoordinates;

  const CreateClanTerritoryScreen({super.key, required this.federationId, required this.initialMapCoordinates});

  @override
  State<CreateClanTerritoryScreen> createState() => _CreateClanTerritoryScreenState();
}

class _CreateClanTerritoryScreenState extends State<CreateClanTerritoryScreen> {
  late Offset _clanPosition;
  double _clanRadius = 50.0; // Raio inicial padrão para clã
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _leaderUsernameController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _clanPosition = widget.initialMapCoordinates;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    _leaderUsernameController.dispose();
    super.dispose();
  }

  Future<void> _createClan() async {
    if (!mounted) return;

    final name = _nameController.text.trim();
    final tag = _tagController.text.trim();
    final leaderUsername = _leaderUsernameController.text.trim();

    if (name.isEmpty || tag.isEmpty) {
      CustomSnackbar.showError(context, 'Nome e TAG do clã são obrigatórios.');
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final adminService = Provider.of<AdminService>(context, listen: false);
      
      final response = await adminService.createClanWithTerritory(
        name: name,
        tag: tag,
        federationId: widget.federationId,
        leaderUsername: leaderUsername.isNotEmpty ? leaderUsername : null,
        mapX: _clanPosition.dx,
        mapY: _clanPosition.dy,
        radius: _clanRadius,
      );

      if (mounted) {
        if (response['success']) {
          CustomSnackbar.showSuccess(context, response['msg'] ?? 'Clã criado com sucesso!');
          Navigator.of(context).pop(); // Volta para o mapa
        } else {
          CustomSnackbar.showError(context, response['msg'] ?? 'Erro ao criar clã.');
        }
      }
    } catch (e) {
      Logger.error('Erro ao criar clã: $e');
      if (mounted) CustomSnackbar.showError(context, 'Erro interno ao criar clã: ${e.toString()}');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _clanPosition += details.delta;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isAdm = authProvider.currentUser?.role == Role.admMaster;

    if (!isAdm) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acesso Negado')),
        body: const Center(child: Text('Você não tem permissão para acessar esta tela.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Novo Clã'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _createClan,
              tooltip: 'Criar Clã',
            ),
        ],
      ),
      body: Stack(
        children: [
          // O mapa como fundo
          Image.asset(
            'assets/images/map/mapa.png',
            width: _originalMapSize.width,
            height: _originalMapSize.height,
            fit: BoxFit.cover,
          ),

          // Território do Clã (arrastável e redimensionável)
          Positioned(
            left: _clanPosition.dx - _clanRadius,
            top: _clanPosition.dy - _clanRadius,
            child: GestureDetector(
              onPanUpdate: _handlePanUpdate,
              child: Container(
                width: _clanRadius * 2,
                height: _clanRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.teal.withOpacity(0.25), // Fundo transparente
                  border: Border.all(color: Colors.teal.shade200, width: 2, style: BorderStyle.solid),
                ),
                child: Center(
                  child: Text(
                    _tagController.text.isNotEmpty ? _tagController.text.toUpperCase() : 'CLÃ',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24, shadows: [Shadow(blurRadius: 5, color: Colors.black)]),
                  ),
                ),
              ),
            ),
          ),

          // Painel de Controles
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Material(
              elevation: 8,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Clã',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        labelText: 'TAG do Clã',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 5,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _leaderUsernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username do Líder (opcional)',
                        hintText: 'Deixe em branco para não atribuir líder agora',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Raio do Território: ${_clanRadius.round()}'),
                    Slider(
                      value: _clanRadius,
                      min: 20,
                      max: 200,
                      divisions: 90,
                      label: _clanRadius.round().toString(),
                      onChanged: (double value) {
                        setState(() { _clanRadius = value; });
                      },
                    ),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


