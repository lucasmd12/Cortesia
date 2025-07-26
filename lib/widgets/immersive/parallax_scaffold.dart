import 'dart:math';
import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';

// Enum para definir os tipos de fundo disponíveis no nosso scaffold.
enum ParallaxBackground {
  space,
  sky,
  qrr, // Adicionado para as telas de QRR
}

/// Um Scaffold customizado que fornece um fundo animado com efeito de paralaxe.
/// Ele é projetado para ser um substituto direto do Scaffold padrão em telas
/// que requerem uma experiência visual mais imersiva.
class ParallaxScaffold extends StatelessWidget {
  final ParallaxBackground? backgroundType;
  final String? customAssetPath;
  final ParallaxBackground? fallbackType;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final FloatingActionButton? floatingActionButton;
  final Color? backgroundColor;

  const ParallaxScaffold({
    super.key,
    this.backgroundType,
    this.customAssetPath,
    this.fallbackType,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? Colors.black,
      appBar: appBar,
      body: Stack(
        children: [
          // A camada de fundo que contém a animação de paralaxe.
          Positioned.fill(
            child: _buildAnimatedBackground(),
          ),
          // O conteúdo principal da tela, renderizado sobre o fundo.
          Positioned.fill(
            child: body,
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  /// Seleciona qual fundo animado construir com base no [backgroundType].
  Widget _buildAnimatedBackground() {
    // Se há um asset customizado, usa ele
    if (customAssetPath != null && customAssetPath!.isNotEmpty) {
      return Image.network(
        customAssetPath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Se falhar ao carregar a imagem customizada, usa o fallback
          return _buildFallbackBackground();
        },
      );
    }

    // Se não há asset customizado, usa o tipo especificado
    final type = backgroundType ?? fallbackType ?? ParallaxBackground.space;
    
    switch (type) {
      case ParallaxBackground.space:
        return const _SpaceBackground();
      case ParallaxBackground.sky:
        return const _SkyBackground();
      case ParallaxBackground.qrr:
        return const _QRRBackground();
    }
  }

  Widget _buildFallbackBackground() {
    final type = fallbackType ?? ParallaxBackground.space;
    
    switch (type) {
      case ParallaxBackground.space:
        return const _SpaceBackground();
      case ParallaxBackground.sky:
        return const _SkyBackground();
      case ParallaxBackground.qrr:
        return const _QRRBackground();
    }
  }
}

// Widget interno que renderiza o fundo de QRR
class _QRRBackground extends StatelessWidget {
  const _QRRBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Imagem de fundo estática (QRR background).
        Positioned.fill(
          child: Image.asset(
            'assets/images/backgrounds/qrr_background.png',
            fit: BoxFit.cover,
          ),
        ),
        // Camada de overlay para melhor legibilidade
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Widget interno que renderiza o fundo de céu com nuvens em paralaxe.
class _SkyBackground extends StatelessWidget {
  const _SkyBackground();

  @override
  Widget build(BuildContext context) {
    final isDayTime = TimeOfDay.now().hour >= 6 && TimeOfDay.now().hour < 18;
    
    return Stack(
      children: [
        // Imagem de fundo estática (céu de dia ou de noite).
        Positioned.fill(
          child: Image.asset(
            isDayTime ? 'assets/images/backgrounds/sky_day.png' : 'assets/images/backgrounds/sky_night.png',
            fit: BoxFit.cover,
          ),
        ),
        // Camada de nuvens animadas.
        Positioned.fill(
          child: LoopAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 150), // Duração longa para um movimento lento.
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(value * -500, 0), // Move as nuvens horizontalmente.
                child: child,
              );
            },
            child: Image.asset(
              'assets/images/backgrounds/clouds_layer.png',
              fit: BoxFit.cover,
              repeat: ImageRepeat.repeatX, // Repete a imagem para um loop infinito.
            ),
          ),
        ),
      ],
    );
  }
}

// Widget interno que renderiza o fundo de espaço com estrelas animadas.
class _SpaceBackground extends StatelessWidget {
  const _SpaceBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Imagem de fundo estática (espaço).
        Positioned.fill(
          child: Image.asset(
            'assets/images/backgrounds/space_background.png',
            fit: BoxFit.cover,
          ),
        ),
        // Camada de partículas (estrelas) animadas.
        Positioned.fill(
          child: LoopAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 200),
            builder: (context, value, child) {
              return CustomPaint(
                painter: _StarfieldPainter(value),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Painter customizado para desenhar e animar um campo de estrelas.
class _StarfieldPainter extends CustomPainter {
  final double time;
  final List<_Star> stars = List.generate(300, (index) => _Star());

  _StarfieldPainter(this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    for (var star in stars) {
      final progress = (time + star.offset) % 1.0;
      final position = Offset(
        star.x * size.width,
        progress * size.height,
      );

      paint.color = Colors.white.withOpacity(star.opacity);
      canvas.drawCircle(position, star.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) {
    return time != oldDelegate.time;
  }
}

// Classe auxiliar para representar uma única estrela com propriedades aleatórias.
class _Star {
  final double x;
  final double size;
  final double opacity;
  final double offset;

  _Star()
      : x = Random().nextDouble(),
        size = Random().nextDouble() * 1.2 + 0.3,
        opacity = Random().nextDouble() * 0.7 + 0.1,
        offset = Random().nextDouble();
}
