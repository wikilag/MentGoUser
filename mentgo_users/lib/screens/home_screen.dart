import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  final String? userEmail;

  const HomeScreen({super.key, this.userEmail});

  Future<void> _handleLogout(BuildContext context) async {
    final authService = AuthService();
    await authService.signOut();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MentalGoTheme.pureWhite,
      appBar: AppBar(
        title: RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
            children: [
              TextSpan(
                text: 'Mental ',
                style: TextStyle(color: MentalGoTheme.darkNavy),
              ),
              TextSpan(
                text: 'Go',
                style: TextStyle(color: MentalGoTheme.primaryTeal),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Salir',
            icon: const Icon(
              Icons.logout_rounded,
              color: MentalGoTheme.darkNavy,
            ),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo oficial de Mental Go
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        MentalGoTheme.logoAsset,
                        height: 220,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tarjeta destacada con el mensaje de bienestar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    decoration: BoxDecoration(
                      color: MentalGoTheme.softMint,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: MentalGoTheme.primaryTeal.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          color: MentalGoTheme.primaryTeal,
                          size: 40,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Estamos construyendo ayudas para tu bienestar',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: MentalGoTheme.darkNavy,
                            height: 1.35,
                          ),
                        ),
                        if (userEmail != null && userEmail!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Sesión activa: $userEmail',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: MentalGoTheme.subtitleGray,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Botón de salida para salir de la página principal
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _handleLogout(context),
                      icon: const Icon(Icons.exit_to_app_rounded),
                      label: const Text(
                        'Salir',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MentalGoTheme.darkNavy,
                        side: const BorderSide(
                          color: MentalGoTheme.primaryTeal,
                          width: 1.8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
