import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Modelos e Providers
import 'package:lucasbeatsfederacao/models/clan_model.dart';
import 'package:lucasbeatsfederacao/models/federation_model.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/providers/map_navigation_provider.dart';

// Serviços
import 'package:lucasbeatsfederacao/services/clan_service.dart';
import 'package:lucasbeatsfederacao/services/federation_service.dart';

// Widgets e Telas
import 'package:lucasbeatsfederacao/screens/clan_detail_screen.dart';
import 'package:lucasbeatsfederacao/screens/maps/map_editor_screen.dart';
import 'package:lucasbeatsfederacao/screens/maps/create_federation_territory_screen.dart';
import 'package:lucasbeatsfederacao/widgets/maps/federation_control_panel.dart';
import 'package:lucasbeatsfederacao/widgets/maps/clan_control_panel.dart';
import 'package:lucasbeatsfederacao/widgets/maps/admin_control_panel.dart';

const Size _originalMapSize = Size(2048, 1024);

class ImmersiveMapScreen extends StatefulWidget {
  const ImmersiveMapScreen({super.key});

  @override
  State<ImmersiveMapScreen> createState() => _ImmersiveMapScreenState();
}

class _ImmersiveMapScreenState extends State<ImmersiveMapScreen> with SingleTickerProviderStateMixin {
  late final TransformationController _transformationController;
  late final AnimationController _animationController;

  bool _isLoading = true;
  List<Federation> _federations = [];
  List<Clan> _allClans = [];
  
  String? _userClanId;
  Role? _userRole;
  String? _userFederationId;

  bool _isAdminPanelVisible = true;

  void _toggleAdminPanelVisibility() {
    setState(() {
      _isAdminPanelVisible = !_isAdminPanelVisible;
    });
  }

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _userClanId = authProvider.currentUser?.clanId;
    _userRole = authProvider.currentUser?.role;
    if (_userRole == Role.federationLeader) {
       _userFederationId = authProvider.currentUser?.federationId;
    }

    _fetchAllMapData();

    final mapProvider = Provider.of<MapNavigationProvider>(context, listen: false);
    mapProvider.addListener(_onMapStateChange);
  }

  @override
  void dispose() {
    Provider.of<MapNavigationProvider>(context, listen: false).removeListener(_onMapStateChange);
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onMapStateChange() {
    final mapProvider = Provider.of<MapNavigationProvider>(context, listen: false);
    
    switch (mapProvider.currentAltitude) {
      case MapAltitude.world:
        _animateTo(Offset(_originalMapSize.width / 2, _originalMapSize.height / 2), 1.0);
        break;
      case MapAltitude.federation:
        if (mapProvider.focusedFederation != null) {
          final fed = mapProvider.focusedFederation!;
          _animateTo(Offset(fed.mapX ?? 0, fed.mapY ?? 0), 2.5);
        }
        break;
      case MapAltitude.clan:
         if (mapProvider.focusedClan != null) {
          final clan = mapProvider.focusedClan!;
          _animateTo(Offset(clan.mapX ?? 0, clan.mapY ?? 0), 4.0);
        }
        break;
    }
  }

  Future<void> _fetchAllMapData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    try {
      final federationService = Provider.of<FederationService>(context, listen: false);
      final clanService = Provider.of<ClanService>(context, listen: false);
      
      final results = await Future.wait([
        federationService.getFederationsWithTerritories(),
        clanService.getClansWithTerritories(),
      ]);
      
      if (mounted) {
        setState(() {
          _federations = results[0] as List<Federation>;
          _allClans = results[1] as List<Clan>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados do mapa: $e')),
        );
      }
    }
  }

  void _animateTo(Offset targetPoint, double targetScale) {
    final screenSize = MediaQuery.of(context).size;
    final zoomedX = -targetPoint.dx * targetScale + (screenSize.width / 2);
    final zoomedY = -targetPoint.dy * targetScale + (screenSize.height / 2);

    final targetMatrix = Matrix4.identity()
      ..translate(zoomedX, zoomedY)
      ..scale(targetScale);

    final animation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic));

    animation.addListener(() {
      _transformationController.value = animation.value;
    });

    _animationController.forward(from: 0.0);
  }

  void _onFederationTap(Federation federation, MapNavigationProvider provider) {
    provider.zoomToFederation(federation);
  }

  void _onClanTap(Clan clan, MapNavigationProvider provider) {
    final parentFederation = _federations.firstWhereOrNull((f) => f.id == clan.federationId);
    provider.zoomToClan(clan, parentFederation: parentFederation);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapNavigationProvider>(
      builder: (context, mapProvider, child) {
        final bool shouldShowAdminFab = _userRole == Role.admMaster &&
                                   !_isAdminPanelVisible &&
                                   mapProvider.currentAltitude == MapAltitude.world;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(
              _getAppBarTitle(mapProvider),
              style: const TextStyle(shadows: [Shadow(blurRadius: 10, color: Colors.black)]),
            ),
            backgroundColor: Colors.black.withOpacity(0.4),
            elevation: 0,
            leading: mapProvider.currentAltitude != MapAltitude.world
                ? IconButton(
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: () => mapProvider.zoomOut(),
                    tooltip: 'Subir Nível',
                  )
                : null,
          ),
          floatingActionButton: shouldShowAdminFab
              ? FloatingActionButton(
                  onPressed: _toggleAdminPanelVisibility,
                  tooltip: 'Mostrar Painel ADM',
                  backgroundColor: Colors.red[900],
                  child: const Icon(Icons.construction),
                )
              : null,
          backgroundColor: Colors.black,
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    InteractiveViewer(
                      transformationController: _transformationController,
                      constrained: false,
                      minScale: 0.15,
                      maxScale: 8.0,
                      boundaryMargin: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height / 2),
                      child: GestureDetector(
                        onLongPressStart: (details) {
                          if (_userRole == Role.admMaster && mapProvider.currentAltitude == MapAltitude.world) {
                            final RenderBox renderBox = context.findRenderObject() as RenderBox;
                            final localPosition = renderBox.globalToLocal(details.globalPosition);
                            final matrix = _transformationController.value;
                            final inverseMatrix = Matrix4.inverted(matrix);
                            final transformedOffset = MatrixUtils.transformPoint(inverseMatrix, localPosition);

                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => CreateFederationTerritoryScreen(
                                initialMapCoordinates: transformedOffset,
                              ),
                            ));
                          }
                        },
                        child: Stack(
                          children: [
                            Image.asset(
                              'assets/images/map/mapa.png',
                              width: _originalMapSize.width,
                              height: _originalMapSize.height,
                              fit: BoxFit.cover,
                            ),
                            ..._buildMapMarkers(mapProvider),
                          ],
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: _buildControlPanel(mapProvider),
                    ),
                  ],
                ),
        );
      },
    );
  }

  String _getAppBarTitle(MapNavigationProvider provider) {
    switch (provider.currentAltitude) {
      case MapAltitude.world:
        return 'Mapa de Guerra';
      case MapAltitude.federation:
        return provider.focusedFederation?.name ?? 'Território da Federação';
      case MapAltitude.clan:
        return provider.focusedClan?.name ?? 'Território do Clã';
    }
  }

  List<Widget> _buildMapMarkers(MapNavigationProvider provider) {
    if (provider.currentAltitude == MapAltitude.world) {
      final independentClans = _allClans.where((clan) => clan.federationId == null && clan.mapX != null && clan.mapY != null).toList();
      return [
        ..._federations.where((fed) => fed.mapX != null && fed.mapY != null).map((fed) => _buildFederationMarker(fed, provider)),
        ...independentClans.map((clan) => _buildClanMarker(clan, provider)),
      ];
    } 
    else if (provider.isFederationView) {
      final memberClans = _allClans.where((clan) => clan.federationId == provider.focusedFederation!.id && clan.mapX != null && clan.mapY != null).toList();
      return memberClans.map((clan) => _buildClanMarker(clan, provider)).toList();
    }
    else if (provider.isClanView) {
       final clan = provider.focusedClan!;
       return [_buildClanMarker(clan, provider)];
    }
    return [];
  }

  Widget _buildFederationMarker(Federation federation, MapNavigationProvider provider) {
    final position = Offset(federation.mapX!, federation.mapY!);
    final radius = federation.radius ?? 60.0;

    return Positioned(
      left: position.dx - radius,
      top: position.dy - radius,
      width: radius * 2,
      height: radius * 2,
      child: GestureDetector(
        onTap: () => _onFederationTap(federation, provider),
        child: Tooltip(
          message: federation.name,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.deepPurple.withOpacity(0.25),
              border: Border.all(color: Colors.deepPurple.shade300, width: 2.5),
            ),
            child: Center(
              child: Text(
                federation.tag ?? federation.name.substring(0, 1),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24, shadows: [Shadow(blurRadius: 5, color: Colors.black)]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClanMarker(Clan clan, MapNavigationProvider provider) {
    final position = Offset(clan.mapX!, clan.mapY!);
    final radius = clan.radius ?? 25.0;

    return Positioned(
      left: position.dx - radius,
      top: position.dy - radius,
      width: radius * 2,
      height: radius * 2,
      child: GestureDetector(
        onTap: () => _onClanTap(clan, provider),
        child: Tooltip(
          message: clan.name,
          child: clan.flag != null && clan.flag!.isNotEmpty
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: clan.flag!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _defaultClanIcon(radius),
                    errorWidget: (context, url, error) => _defaultClanIcon(radius),
                  ),
                )
              : _defaultClanIcon(radius),
        ),
      ),
    );
  }

  Widget _defaultClanIcon(double radius) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.teal.withOpacity(0.4),
        border: Border.all(color: Colors.teal.shade300, width: 2),
      ),
      child: Icon(Icons.shield, color: Colors.white.withOpacity(0.8), size: radius),
    );
  }

  Widget _buildControlPanel(MapNavigationProvider provider) {
    if (_userRole == Role.admMaster &&
        provider.currentAltitude == MapAltitude.world &&
        _isAdminPanelVisible) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: AdminControlPanel(onHide: _toggleAdminPanelVisibility),
      );
    }
    
    if (provider.isFederationView && (_userRole == Role.admMaster || provider.focusedFederation!.id == _userFederationId)) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: FederationControlPanel(federation: provider.focusedFederation!),
      );
    }

    if (provider.isClanView && (_userRole == Role.admMaster || provider.focusedClan!.id == _userClanId)) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: ClanControlPanel(clan: provider.focusedClan!),
      );
    }

    return const SizedBox.shrink();
  }
}
