// lib/screens/maps/map_editor_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucasbeatsfederacao/models/clan_model.dart';
import 'package:lucasbeatsfederacao/models/federation_model.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/services/admin_service.dart';
import 'package:lucasbeatsfederacao/services/clan_service.dart';
import 'package:lucasbeatsfederacao/services/federation_service.dart';
import 'package:lucasbeatsfederacao/widgets/custom_snackbar.dart';
import 'package:provider/provider.dart';

// CRÍTICO: Deve ser o mesmo valor usado na ImmersiveMapScreen.
const Size _originalMapSize = Size(2048, 1024);

enum EditorMode { editFederation, allocateClanByAdmin, recruitClanByLeader }

class MapEditorScreen extends StatefulWidget {
  final EditorMode mode;
  final Federation federation;
  final Clan? clanToRecruit; // Usado apenas no modo de recrutamento

  const MapEditorScreen({
    super.key,
    required this.mode,
    required this.federation,
    this.clanToRecruit,
  });

  @override
  State<MapEditorScreen> createState() => _MapEditorScreenState();
}

class _MapEditorScreenState extends State<MapEditorScreen> {
  // Posição e raio do território principal (Federação)
  late Offset _federationPosition;
  late double _federationRadius;

  // Posição e raio do território secundário (Clã)
  Offset? _clanPosition;
  double? _clanRadius;

  // Estado da UI
  bool _isLoading = false;
  Clan? _selectedClanForAllocation;

  @override
  void initState() {
    super.initState();
    _federationPosition = Offset(widget.federation.mapX ?? _originalMapSize.width / 2, widget.federation.mapY ?? _originalMapSize.height / 2);
    _federationRadius = widget.federation.radius ?? 100.0;

    if (widget.mode == EditorMode.recruitClanByLeader) {
      _clanPosition = _federationPosition; // Começa no centro da federação
      _clanRadius = 50.0; // Raio padrão para um novo clã
    }
  }

  // --- LÓGICA DE SALVAMENTO ---

  Future<void> _saveFederationTerritory() async {
    setState(() { _isLoading = true; });
    try {
      final adminService = Provider.of<AdminService>(context, listen: false);
      await adminService.setFederationTerritory(
        federationId: widget.federation.id,
        mapX: _federationPosition.dx,
        mapY: _federationPosition.dy,
        radius: _federationRadius,
      );
      if (mounted) CustomSnackbar.showSuccess(context, 'Território da federação salvo com sucesso!');
    } catch (e) {
      if (mounted) CustomSnackbar.showError(context, 'Erro ao salvar território: $e');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _allocateClanTerritory() async {
    if (_selectedClanForAllocation == null || _clanPosition == null || _clanRadius == null) {
      CustomSnackbar.showError(context, 'Selecione um clã e defina seu território.');
      return;
    }
    setState(() { _isLoading = true; });
    try {
      final federationService = Provider.of<FederationService>(context, listen: false);
      // O backend já deve lidar com a adição do clã à federação ao alocar território.
      await federationService.allocateClanTerritory(
        federationId: widget.federation.id,
        clanId: _selectedClanForAllocation!.id,
        lat: _clanPosition!.dx, // Usando lat/lng como mapX/mapY
        lng: _clanPosition!.dy,
        radius: _clanRadius!,
      );
      if (mounted) CustomSnackbar.showSuccess(context, 'Clã alocado com sucesso no território!');
      setState(() {
        _selectedClanForAllocation = null;
        _clanPosition = null;
        _clanRadius = null;
      });
    } catch (e) {
      if (mounted) CustomSnackbar.showError(context, 'Erro ao alocar clã: $e');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _sendRecruitmentInvite() async {
    if (widget.clanToRecruit == null || _clanPosition == null || _clanRadius == null) return;
    
    setState(() { _isLoading = true; });
    
    // ======================= IMPLEMENTAÇÃO FUTURA =======================
    // Este é o local onde a chamada para o novo endpoint de convite com território seria feita.
    // Por enquanto, exibimos uma mensagem e simulamos sucesso.
    
    await Future.delayed(const Duration(seconds: 1)); // Simula chamada de rede

    /*
    try {
      final federationService = Provider.of<FederationService>(context, listen: false);
      
      // CHAMADA AO ENDPOINT FUTURO:
      await federationService.sendTerritoryRecruitmentInvite(
        federationId: widget.federation.id,
        clanId: widget.clanToRecruit!.id,
        mapX: _clanPosition!.dx,
        mapY: _clanPosition!.dy,
        radius: _clanRadius!,
      );

      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Convite de recrutamento enviado para ${widget.clanToRecruit!.name}!');
        Navigator.of(context).pop();
      }

    } catch (e) {
      if (mounted) CustomSnackbar.showError(context, 'Erro ao enviar convite: $e');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
    */

    // Lógica de simulação atual:
    if (mounted) {
      CustomSnackbar.showSuccess(context, 'Convite para ${widget.clanToRecruit!.name} preparado e pronto para ser enviado (Endpoint Pendente).');
      Navigator.of(context).pop();
    }
    // ====================================================================
  }


  // --- LÓGICA DE INTERAÇÃO E UI ---

  void _handlePanUpdate(DragUpdateDetails details, bool isFederation) {
    setState(() {
      if (isFederation) {
        _federationPosition += details.delta;
      } else if (_clanPosition != null) {
        final newPos = _clanPosition! + details.delta;
        // Lógica de fronteira: impede que o clã saia do território da federação.
        final distance = (_federationPosition - newPos).distance;
        if (distance <= (_federationRadius - (_clanRadius ?? 0))) {
          _clanPosition = newPos;
        }
      }
    });
  }

  void _showClanSelectionDialog() async {
    final clanService = Provider.of<ClanService>(context, listen: false);
    // Busca apenas clãs que ainda não pertencem a uma federação.
    final availableClans = (await clanService.getAllClans()).where((c) => c.federationId == null).toList();

    if (!mounted) return;

    final Clan? selected = await showDialog<Clan>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Clã para Alocar'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableClans.length,
            itemBuilder: (context, index) {
              final clan = availableClans[index];
              return ListTile(
                title: Text(clan.name),
                onTap: () => Navigator.of(context).pop(clan),
              );
            },
          ),
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedClanForAllocation = selected;
        _clanPosition = _federationPosition; // Posiciona o clã no centro para começar
        _clanRadius = 50.0; // Raio padrão
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bool isAdm = authProvider.currentUser?.role == Role.admMaster;

    return Scaffold(
      appBar: AppBar(
        title: Text('Editor de Território: ${widget.federation.name}'),
        actions: [
          if (widget.mode == EditorMode.editFederation)
            IconButton(icon: const Icon(Icons.save), onPressed: _saveFederationTerritory, tooltip: 'Salvar Território da Federação'),
          if (widget.mode == EditorMode.allocateClanByAdmin && _selectedClanForAllocation != null)
            IconButton(icon: const Icon(Icons.save), onPressed: _allocateClanTerritory, tooltip: 'Salvar Território do Clã'),
          if (widget.mode == EditorMode.recruitClanByLeader)
            IconButton(icon: const Icon(Icons.send), onPressed: _sendRecruitmentInvite, tooltip: 'Enviar Convite de Recrutamento'),
        ],
      ),
      body: Stack(
        children: [
          // O mapa como fundo
          Image.asset(
            'assets/images_map/mapa.png',
            width: _originalMapSize.width,
            height: _originalMapSize.height,
            fit: BoxFit.cover,
          ),

          // Território da Federação (visualização)
          Positioned(
            left: _federationPosition.dx - _federationRadius,
            top: _federationPosition.dy - _federationRadius,
            child: Container(
              width: _federationRadius * 2,
              height: _federationRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepPurple.withOpacity(0.2),
                border: Border.all(color: Colors.deepPurple.shade200, width: 2, style: BorderStyle.solid),
              ),
            ),
          ),

          // Território do Clã (arrastável)
          if (_clanPosition != null && _clanRadius != null)
            Positioned(
              left: _clanPosition!.dx - _clanRadius!,
              top: _clanPosition!.dy - _clanRadius!,
              child: GestureDetector(
                onPanUpdate: (details) => _handlePanUpdate(details, false),
                child: Container(
                  width: _clanRadius! * 2,
                  height: _clanRadius! * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.teal.withOpacity(0.4),
                    border: Border.all(color: Colors.teal.shade200, width: 2),
                  ),
                ),
              ),
            ),
          
          // Território da Federação (arrastável, apenas para ADM)
          if (isAdm && widget.mode == EditorMode.editFederation)
            Positioned(
              left: _federationPosition.dx - _federationRadius,
              top: _federationPosition.dy - _federationRadius,
              child: GestureDetector(
                onPanUpdate: (details) => _handlePanUpdate(details, true),
                child: Container(
                  width: _federationRadius * 2,
                  height: _federationRadius * 2,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent, // Apenas a área de toque
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
                child: _buildControlPanel(isAdm),
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildControlPanel(bool isAdm) {
    switch (widget.mode) {
      case EditorMode.editFederation:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ajustar Território da Federação'),
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
          ],
        );
      case EditorMode.allocateClanByAdmin:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedClanForAllocation == null)
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Selecionar Clã para Alocar'),
                onPressed: _showClanSelectionDialog,
              )
            else ...[
              Text('Ajustar Território para: ${_selectedClanForAllocation!.name}'),
              Slider(
                value: _clanRadius ?? 50.0,
                min: 20,
                max: _federationRadius - 10, // Clã não pode ser maior que a federação
                divisions: 50,
                label: (_clanRadius ?? 50.0).round().toString(),
                onChanged: (double value) {
                  setState(() { _clanRadius = value; });
                },
              ),
            ]
          ],
        );
      case EditorMode.recruitClanByLeader:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Preparar Território para: ${widget.clanToRecruit!.name}'),
            Slider(
              value: _clanRadius ?? 50.0,
              min: 20,
              max: _federationRadius - 10,
              divisions: 50,
              label: (_clanRadius ?? 50.0).round().toString(),
              onChanged: (double value) {
                setState(() { _clanRadius = value; });
              },
            ),
          ],
        );
    }
  }
}
