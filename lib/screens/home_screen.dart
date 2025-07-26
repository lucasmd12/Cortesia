import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/screens/tabs/home_tab.dart';
import 'package:lucasbeatsfederacao/screens/chat/contextual_chat_screen.dart';
import 'package:lucasbeatsfederacao/screens/voip/contextual_voice_screen.dart';
// import 'package:lucasbeatsfederacao/screens/exploration/federation_explorer_screen.dart'; // Removido para dar lugar à nova experiência
import 'package:lucasbeatsfederacao/screens/settings_screen.dart';
import 'package:lucasbeatsfederacao/screens/invite_list_screen.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:lucasbeatsfederacao/screens/instaclan_feed_screen.dart';
import 'package:lucasbeatsfederacao/screens/clan_wars_list_screen.dart';
import 'package:lucasbeatsfederacao/screens/admin_panel_screen.dart';

// ==================== INÍCIO DA MODIFICAÇÃO ====================
import 'package:lucasbeatsfederacao/widgets/immersive/parallax_scaffold.dart';
import 'package:lucasbeatsfederacao/widgets/map_transition_button.dart';
// ===================== FIM DA MODIFICAÇÃO ======================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late AudioPlayer _audioPlayer;

  List<Widget> _widgetOptions = [];

  // A lista de imagens de fundo antigas não é mais necessária.
  // final List<String> _backgroundImages = [ ... ];

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        // ==================== INÍCIO DA MODIFICAÇÃO ====================
        // A lista de widgets agora inclui o botão de transição para o mapa.
        _widgetOptions = <Widget>[
          const HomeTab(),
          const MapTransitionButton(), // Substituindo a antiga tela de explorar.
          const ContextualChatScreen(chatContext: 'global'),
          const ContextualVoiceScreen(voiceContext: 'global'),
          const InstaClanFeedScreen(),
          const ClanWarsListScreen(),
          const SettingsScreen(),
        ];
        // ===================== FIM DA MODIFICAÇÃO ======================
      });
      _requestPermissions();
    });
  }

  Future<void> _requestPermissions() async {
    final transaction = Sentry.startTransaction(
      'requestPermissions',
      'permission_request',
      description: 'Requesting necessary permissions',
    );
    Logger.info("Requesting necessary permissions...");
    try {
      await Permission.notification.request();
      await Permission.storage.request();
      await Permission.microphone.request();
      transaction.finish(status: SpanStatus.ok());
    } catch (e, stackTrace) {
      transaction.finish(status: SpanStatus.internalError());
      Sentry.captureException(e, stackTrace: stackTrace);
      Logger.error("Error requesting permissions", error: e, stackTrace: stackTrace);
    }
  }

  void _showSettingsDialog(String permissionName) {
     if (!mounted) return;
     showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text("Permissão Necessária"),
          content: Text("A permissão de $permissionName foi negada permanentemente. Por favor, habilite-a nas configurações do aplicativo para usar todas as funcionalidades."),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Abrir Configurações"),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
  }

  Future<void> _initializeAudioPlayer() async {
    _audioPlayer = AudioPlayer();
    try {
      await _audioPlayer.setAsset('assets/audio/intro_music.mp3');
      _audioPlayer.play();
      Logger.info("Intro music started playing.");
    } catch (e, stackTrace) {
      Logger.error("Error loading or playing intro music", error: e, stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Logger.info("Switched to tab index: $index");
  }


  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final textTheme = Theme.of(context).textTheme;

    if (authProvider.authStatus == AuthStatus.unknown || authProvider.authService.isLoading) {
       // Usamos um ParallaxScaffold aqui também para uma transição suave.
       return const ParallaxScaffold(
         backgroundType: ParallaxBackground.sky,
         body: Center(
          child: CircularProgressIndicator(),
        ),
       );
    }

    if (currentUser == null) {
       Logger.warning("HomeScreen build: User is null after authentication check. This shouldn't happen.");
       return ParallaxScaffold(
         backgroundType: ParallaxBackground.sky,
         body: Center(child: Padding(
           padding: const EdgeInsets.all(16.0),
           child: Text("Erro crítico ao carregar dados do usuário. Por favor, tente reiniciar o aplicativo.", textAlign: TextAlign.center, style: textTheme.bodyMedium?.copyWith(color: Colors.white)),
         )),
       );
    }

    IconData displayIcon = Icons.person;
    String displayText = currentUser.username ?? 'Usuário';

    if (currentUser.role == Role.admMaster) {
      displayIcon = Icons.admin_panel_settings;
      displayText = "ADM MASTER: ${currentUser.username ?? 'N/A'}";
    } else if (currentUser.clanName != null && currentUser.clanTag != null) {
      displayIcon = Icons.flag;
      displayText = "${currentUser.clanName} [${currentUser.clanTag}] ${currentUser.username ?? 'N/A'}";
      if (currentUser.federationTag != null) {
        displayText += " (${currentUser.federationTag})";
      }
    } else if (currentUser.federationName != null && currentUser.federationTag != null) {
      displayIcon = Icons.account_tree;
      displayText = "${currentUser.federationName} (${currentUser.federationTag}) ${currentUser.username ?? 'N/A'}";
    }

    // ==================== INÍCIO DA MODIFICAÇÃO ====================
    // O Scaffold padrão é substituído pelo nosso ParallaxScaffold.
    return Scaffold(
      body: ParallaxScaffold(
        backgroundType: ParallaxBackground.sky,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.purple,
                  shape: BoxShape.circle,
                ),
                child: Icon(displayIcon, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayText,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, shadows: [Shadow(blurRadius: 4, color: Colors.black54)]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
             if (currentUser.role == Role.admMaster)
              IconButton(
                icon: const Icon(Icons.dashboard_customize),
                tooltip: 'Painel Administrativo',
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
                    );
                  }
                },
              ),
             IconButton(
              icon: const Icon(Icons.notifications_none),
              tooltip: 'Notificações',
              onPressed: () {
                Logger.info("Notifications button pressed.");
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const InviteListScreen()),
                );
              },
            ),
          ],
          leading: IconButton(
            icon: StreamBuilder<PlayerState>(
              stream: _audioPlayer.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final processingState = playerState?.processingState;
                if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering || !(_audioPlayer.playing)) {
                  return const Icon(Icons.play_arrow);
                } else if (playerState?.playing != true) {
                  return const Icon(Icons.play_arrow);
                } else {
                  return const Icon(Icons.pause);
                }
              },
            ),
            onPressed: () {
              if (_audioPlayer.playing) {
                _audioPlayer.pause();
              } else {
                _audioPlayer.play();
              }
            },
          ),
        ),
        body: IndexedStack(
           index: _selectedIndex,
           children: _widgetOptions,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.travel_explore_outlined), activeIcon: Icon(Icons.travel_explore), label: 'Explorar'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.call_outlined), activeIcon: Icon(Icons.call), label: 'Chamadas'),
          BottomNavigationBarItem(icon: Icon(Icons.photo_library_outlined), activeIcon: Icon(Icons.photo_library), label: 'InstaClã'),
          BottomNavigationBarItem(icon: Icon(Icons.military_tech_outlined), activeIcon: Icon(Icons.military_tech), label: 'Guerras'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Config'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        unselectedItemColor: Colors.grey,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        backgroundColor: Theme.of(context).primaryColor,
        type: BottomNavigationBarType.fixed,
      ),
    );
    // ===================== FIM DA MODIFICAÇÃO ======================
  }
}
