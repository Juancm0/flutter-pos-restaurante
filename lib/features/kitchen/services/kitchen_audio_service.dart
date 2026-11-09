import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';

/// Servicio para reproducir sonidos en el módulo de cocina
class KitchenAudioService {
  static final KitchenAudioService _instance = KitchenAudioService._internal();
  factory KitchenAudioService() => _instance;
  KitchenAudioService._internal();

  final AudioPlayer _newOrderPlayer = AudioPlayer();
  final AudioPlayer _urgentAlertPlayer = AudioPlayer();

  bool _isInitialized = false;

  /// Inicializar el servicio de audio
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configurar los players para que se puedan reproducir múltiples veces
      await _newOrderPlayer.setVolume(0.8);
      await _urgentAlertPlayer.setVolume(1.0);

      _isInitialized = true;
    } catch (e) {
      // Silenciar error de audio
    }
  }

  /// Reproducir sonido de nueva orden
  /// Usa vibración háptica + beep del sistema
  Future<void> playNewOrderSound() async {
    try {
      // Vibración háptica fuerte
      await HapticFeedback.heavyImpact();

      // Esperar un poco y vibrar de nuevo (doble vibración)
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();

      // Generar beep de sistema (tono simple)
      // Nota: En Android esto reproduce el sonido de notificación por defecto
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      // Silenciar error
    }
  }

  /// Reproducir sonido de alerta urgente (orden >15 min)
  /// Vibración más intensa + sonido de alerta
  Future<void> playUrgentAlertSound() async {
    try {
      // Triple vibración háptica (patrón urgente)
      for (int i = 0; i < 3; i++) {
        await HapticFeedback.vibrate();
        await Future.delayed(const Duration(milliseconds: 150));
      }

      // Sonido de alerta del sistema
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      // Silenciar error
    }
  }

  /// Reproducir beep de confirmación
  Future<void> playConfirmationSound() async {
    try {
      await HapticFeedback.mediumImpact();
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      // Silenciar error
    }
  }

  /// Limpiar recursos
  Future<void> dispose() async {
    await _newOrderPlayer.dispose();
    await _urgentAlertPlayer.dispose();
  }
}
