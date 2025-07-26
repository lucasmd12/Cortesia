import 'package:flutter/material.dart';
import 'package:lucasbeatsfederacao/models/clan_model.dart';
import 'package:lucasbeatsfederacao/models/federation_model.dart';

/// Define os diferentes níveis de zoom ou "altitude" no mapa.
enum MapAltitude {
  /// Visão global do mapa do mundo.
  world,
  /// Visão focada no território de uma federação, mostrando os clãs dentro dela.
  federation,
  /// Visão focada em um clã específico.
  clan,
}

/// Gerencia o estado de navegação e o contexto do mapa imersivo.
///
/// Este provider atua como o "Maestro", controlando o nível de zoom (altitude),
/// a entidade em foco (federação ou clã) e notificando os widgets para
/// reconstruírem a UI e a câmera do mapa de acordo.
class MapNavigationProvider with ChangeNotifier {
  // --- ESTADO PRIVADO ---

  MapAltitude _currentAltitude = MapAltitude.world;
  Federation? _focusedFederation;
  Clan? _focusedClan;

  // --- GETTERS PÚBLICOS ---

  /// O nível de altitude atual do mapa.
  MapAltitude get currentAltitude => _currentAltitude;

  /// A federação que está atualmente em foco. Null se a visão for do mundo ou de um clã.
  Federation? get focusedFederation => _focusedFederation;

  /// O clã que está atualmente em foco. Null se a visão for do mundo ou de uma federação.
  Clan? get focusedClan => _focusedClan;

  /// Retorna true se a UI deve mostrar os controles de uma federação.
  bool get isFederationView => _currentAltitude == MapAltitude.federation && _focusedFederation != null;

  /// Retorna true se a UI deve mostrar os controles de um clã.
  bool get isClanView => _currentAltitude == MapAltitude.clan && _focusedClan != null;

  // --- MÉTODOS DE AÇÃO (MODIFICADORES DE ESTADO) ---

  /// Leva a câmera e a UI para a visão de uma federação específica.
  /// Chamado quando o usuário toca no território de uma federação.
  void zoomToFederation(Federation federation) {
    _currentAltitude = MapAltitude.federation;
    _focusedFederation = federation;
    _focusedClan = null; // Garante que não há um clã em foco
    notifyListeners(); // Notifica os widgets (mapa e painéis) para se atualizarem
  }

  /// Leva a câmera e a UI para a visão de um clã específico.
  /// Chamado quando o usuário toca no marcador de um clã.
  void zoomToClan(Clan clan, {Federation? parentFederation}) {
    _currentAltitude = MapAltitude.clan;
    _focusedClan = clan;
    // Se o clã pertence a uma federação, mantemos essa informação no contexto.
    _focusedFederation = parentFederation;
    notifyListeners();
  }

  /// Retorna a câmera e a UI para o nível de altitude anterior.
  /// Ex: Da visão de um clã para a visão da federação, ou da federação para o mundo.
  void zoomOut() {
    if (_currentAltitude == MapAltitude.clan) {
      // Se estávamos vendo um clã dentro de uma federação, voltamos para a federação.
      if (_focusedFederation != null) {
        zoomToFederation(_focusedFederation!);
      } else {
        // Se era um clã isolado, voltamos para o mapa do mundo.
        zoomToWorld();
      }
    } else if (_currentAltitude == MapAltitude.federation) {
      zoomToWorld();
    }
  }

  /// Leva a câmera e a UI de volta para a visão global do mapa.
  void zoomToWorld() {
    _currentAltitude = MapAltitude.world;
    _focusedFederation = null;
    _focusedClan = null;
    notifyListeners();
  }
}
