// lib/widgets/map_transition_button.dart

import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:lucasbeatsfederacao/screens/maps/immersive_map_screen.dart'; // Importaremos a tela que vamos criar a seguir

/// Um botão que usa uma transição suave para abrir a tela do mapa.
/// Ele é projetado para ser colocado na HomeScreen ou em uma aba de "Explorar".
class MapTransitionButton extends StatelessWidget {
  const MapTransitionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: const Duration(milliseconds: 800), // Duração da animação de "mergulho"
      openBuilder: (context, _) => const ImmersiveMapScreen(), // A tela que será aberta
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      closedElevation: 6.0,
      closedColor: Theme.of(context).colorScheme.surface, // Cor do botão fechado
      closedBuilder: (context, openContainer) {
        // A aparência do botão quando está "fechado"
        return InkWell(
          onTap: openContainer, // Ação de abrir
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.8)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 48, color: Colors.white),
                SizedBox(height: 12),
                Text(
                  'Mapa de Guerra',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Explore os territórios',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
