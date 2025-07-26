import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/services/admin_service.dart';
import 'package:lucasbeatsfederacao/services/user_service.dart';
import 'package:lucasbeatsfederacao/utils/custom_snackbar.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

const Size _originalMapSize = Size(2048, 1024);

class CreateFederationTerritoryScreen extends StatefulWidget {
  final Offset initialMapCoordinates;

  const CreateFederationTerritoryScreen({super.key, required this.initialMapCoordinates});

  @override
  State<CreateFederationTerritoryScreen> createState() => _CreateFederationTerritoryScreenState();
}

class _CreateFederationTerritoryScreenState extends State<CreateFederationTerritoryScreen> {
  late Offset _federationPosition;
  double _federationRadius = 100.0; // Raio inicial padrão
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _leaderUsernameController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _federationPosition = widget.initialMapCoordinates;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    _leaderUsernameController.dispose();
    super.dispose();
  }

  Future<void> _createFederation() async {
    if (!mounted) return;

    final name = _nameController.text.trim();
    final tag = _tagController.text.trim();
    final leaderUsername = _leaderUsernameController.text.trim();

    if (name.isEmpty) {
      CustomSnackbar.showError(context, 'O nome da federação é obrigatório.');
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final adminService = Provider.of<AdminService>(context, listen: false);
      
      final response = await adminService.createFederationWithTerritory(
        name: name,
        tag: tag.isNotEmpty ? tag : null,
        leaderUsername: leaderUsername.isNotEmpty ? leaderUsername : null,
        mapX: _federationPosition.dx,
        mapY: _federationPosition.dy,
        radius: _federationRadius,
      );

      if (mounted) {
        if (response['success']) {
          CustomSnackbar.showSuccess(context, response['msg'] ?? 'Federação criada com sucesso!');
          Navigator.of(context).pop(); // Volta para o mapa
        } else {
          CustomSnackbar.showError(context, response['msg'] ?? 'Erro ao criar federação.');
        }
      }
    } catch (e) {
      Logger.error('Erro ao criar federação: $e');
      if (mounted) CustomSnackbar.showError(context, 'Erro interno ao criar federação: ${e.toString()}');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _federationPosition += details.delta;
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
        title: const Text('Criar Nova Federação'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _createFederation,
              tooltip: 'Criar Federação',
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

          // Território da Federação (arrastável e redimensionável)
          Positioned(
            left: _federationPosition.dx - _federationRadius,
            top: _federationPosition.dy - _federationRadius,
            child: GestureDetector(
              onPanUpdate: _handlePanUpdate,
              child: Container(
                width: _federationRadius * 2,
                height: _federationRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurple.withOpacity(0.15), // Fundo transparente
                  border: Border.all(color: Colors.deepPurple.shade200, width: 2, style: BorderStyle.solid),
                ),
                child: Center(
                  child: Text(
                    _tagController.text.isNotEmpty ? _tagController.text.toUpperCase() : 'FED',
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
                        labelText: 'Nome da Federação',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        labelText: 'TAG da Federação (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 5,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _leaderUsernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username do Líder (opcional)',
                        hintText: 'Deixe em branco para ser o ADM atual',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Raio do Território: ${_federationRadius.round()}'),
                    Slider(
                      value: _federationRadius,
                      min: 50,
                      max: 500,
                      divisions: 90,
                      label: _federationRadius.round().toString(),
                      onChanged: (double value) {
                        setState(() { _federationRadius = value; });
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


