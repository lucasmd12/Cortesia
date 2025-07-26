import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/auth_service.dart';
import '../services/keep_alive_service.dart';
import '../utils/logger.dart';
import '../widgets/custom_snackbar.dart';

// ==================== INÍCIO DA MODIFICAÇÃO ====================
import '../widgets/immersive/parallax_scaffold.dart';
import 'home_screen.dart'; // Precisamos do import para a transição customizada
// ===================== FIM DA MODIFICAÇÃO ======================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isWakingServer = false;
  final KeepAliveService _keepAliveService = KeepAliveService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _keepAliveService.startKeepAlive();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _ensureServerIsAwake() async {
    setState(() {
      _isWakingServer = true;
    });

    try {
      Logger.info('Checking if server is awake...');
      bool isAwake = await _keepAliveService.ensureServerAwake();
      
      if (!isAwake) {
        if (mounted) {
          CustomSnackbar.showInfo(context, 'Servidor iniciando... Isso pode levar até 1 minuto.');
        }
        await Future.delayed(const Duration(seconds: 5));
        await _keepAliveService.ensureServerAwake();
      }
    } catch (e) {
      Logger.warning('Failed to ensure server is awake: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isWakingServer = false;
        });
      }
    }
  }

  // ==================== INÍCIO DA MODIFICAÇÃO ====================
  /// Navega para a HomeScreen com uma animação de zoom e fade.
  void _navigateToHomeWithTransition() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 1200), // Duração da animação
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Animação de escala (zoom in)
          final scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
          );
          // Animação de fade (aparecer suavemente)
          final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: const Interval(0.5, 1.0)), // Fade in na segunda metade
          );

          return FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          );
        },
      ),
    );
  }
  // ===================== FIM DA MODIFICAÇÃO ======================

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _ensureServerIsAwake();

      final authService = Provider.of<AuthService>(context, listen: false);
      Logger.info('Attempting login for: ${_usernameController.text}');

      bool success = await authService.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (success) {
        Logger.info('Login successful via AuthService for user: ${authService.currentUser?.username}');
        await _audioPlayer.play(AssetSource('audio/intro_music.mp3'));
        
        // ==================== INÍCIO DA MODIFICAÇÃO ====================
        // Chama a nova função de navegação com a transição imersiva
        _navigateToHomeWithTransition();
        // ===================== FIM DA MODIFICAÇÃO ======================

      } else {
        if (mounted) {
           final errorMsg = authService.errorMessage ?? 'Falha no login. Verifique suas credenciais.';
           CustomSnackbar.showError(context, errorMsg);
        }
      }
    } catch (e) {
      Logger.error('Login Screen Error', error: e);
      if (mounted) {
        String errorMessage = e.toString().replaceFirst("Exception: ", "");
        
        if (errorMessage.contains('TimeoutException')) {
          errorMessage = 'Servidor demorou para responder. Tente novamente em alguns segundos.';
        } else if (errorMessage.contains('SocketException')) {
          errorMessage = 'Problema de conexão. Verifique sua internet e tente novamente.';
        }
        
        CustomSnackbar.showError(context, 'Erro no login: $errorMessage');
      }
    }
    finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handlePasswordReset() async {
     final username = _usernameController.text.trim();
     if (username.isEmpty) {
       CustomSnackbar.showError(context, 'Digite seu nome de usuário para solicitar a redefinição.');
       return;
     }
     Logger.warning("Password Reset functionality not implemented yet.");
     CustomSnackbar.showInfo(context, 'Funcionalidade de redefinição de senha ainda não implementada.');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // ==================== INÍCIO DA MODIFICAÇÃO ====================
    // Substituímos o Scaffold padrão pelo nosso ParallaxScaffold
    return ParallaxScaffold(
      backgroundType: ParallaxBackground.space,
      // Usamos um backgroundColor semi-transparente para escurecer um pouco o fundo
      // e melhorar a legibilidade do formulário.
      backgroundColor: Colors.black.withOpacity(0.4),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset(
                        'assets/images_png/app_icon_login_splash.png',
                        height: 100,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.shield_moon,
                          size: 80,
                          color: Color(0xFF9147FF),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'FEDERACAOMAD',
                        textAlign: TextAlign.center,
                        style: textTheme.displayLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Faça login para continuar',
                        textAlign: TextAlign.center,
                        style: textTheme.displayMedium,
                      ),
                      const SizedBox(height: 48),

                      TextFormField(
                        controller: _usernameController,
                        keyboardType: TextInputType.text,
                        style: const TextStyle(color: Colors.white, fontFamily: 'Gothic'),
                        decoration: const InputDecoration(
                          labelText: 'Usuário',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira seu nome de usuário';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white, fontFamily: 'Gothic'),
                        decoration: const InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira sua senha';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: (_isLoading || _isWakingServer) ? null : _handleLogin,
                        child: (_isLoading || _isWakingServer)
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(_isWakingServer ? 'INICIANDO SERVIDOR...' : 'ENTRANDO...'),
                                ],
                              )
                            : const Text('ENTRAR'),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: (_isLoading || _isWakingServer) ? null : _handlePasswordReset,
                            child: const Text('Esqueceu a senha?'),
                          ),
                          TextButton(
                            onPressed: (_isLoading || _isWakingServer) ? null : () {
                              Navigator.pushNamed(context, '/register');
                            },
                            child: const Text('Criar conta'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // ===================== FIM DA MODIFICAÇÃO ======================
  }
}
