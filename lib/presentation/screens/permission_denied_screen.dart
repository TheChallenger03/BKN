import 'package:flutter/material.dart';
import '../../core/utils/permission_handler.dart';

class PermissionDeniedScreen extends StatelessWidget {
  final PermissionStatus status;

  const PermissionDeniedScreen({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIcon(),
                size: 120,
                color: Colors.orange,
              ),
              const SizedBox(height: 32),
              Text(
                _getTitle(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _getMessage(),
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => _handleAction(context),
                icon: const Icon(Icons.settings),
                label: Text(_getButtonText()),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _retryPermissions(context),
                child: const Text('Riprova'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (status) {
      case PermissionStatus.serviceDisabled:
        return Icons.location_off;
      case PermissionStatus.denied:
      case PermissionStatus.permanentlyDenied:
        return Icons.location_disabled;
      default:
        return Icons.error;
    }
  }

  String _getTitle() {
    switch (status) {
      case PermissionStatus.serviceDisabled:
        return 'Servizi di Localizzazione Disabilitati';
      case PermissionStatus.denied:
        return 'Permesso di Localizzazione Negato';
      case PermissionStatus.permanentlyDenied:
        return 'Permesso di Localizzazione Negato Permanentemente';
      default:
        return 'Errore nei Permessi di Localizzazione';
    }
  }

  String _getMessage() {
    switch (status) {
      case PermissionStatus.serviceDisabled:
        return 'I servizi di localizzazione sono disabilitati. '
            'Per favore, abilitali nelle impostazioni del dispositivo.';
      case PermissionStatus.denied:
        return 'Il permesso di localizzazione è stato negato. '
            'Per favore, concedilo per continuare.';
      case PermissionStatus.permanentlyDenied:
        return 'Il permesso di localizzazione è stato negato permanentemente. '
            'Per favore, concedilo dalle impostazioni del dispositivo.';
      default:
        return 'Si è verificato un errore con i permessi di localizzazione.';
    }
  }

  String _getButtonText() {
    switch (status) {
      case PermissionStatus.serviceDisabled:
        return 'Apri Impostazioni Localizzazione';
      case PermissionStatus.denied:
      case PermissionStatus.permanentlyDenied:
        return 'Apri Impostazioni App';
      default:
        return 'Apri Impostazioni';
    }
  }

  Future<void> _handleAction(BuildContext context) async {
    if(status == PermissionStatus.serviceDisabled) {
      await PermissionHandler.openLocationSettings();
    } else {
      await PermissionHandler.openAppSettings();
    }
  }

  Future<void> _retryPermissions(BuildContext context) async {
    final newStatus = await PermissionHandler.checkLocationPermission();
    
    if(newStatus == PermissionStatus.granted && context.mounted) {
      ///Restart app or navigate to main screen
      ///For simplicity, well just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permessi concessi! Riavvia l\'app.'),
          backgroundColor: Colors.green,),
      );
    }
  }
}