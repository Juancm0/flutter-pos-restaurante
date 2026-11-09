import 'package:flutter/material.dart';

/// Badge que muestra el tiempo transcurrido con colores según urgencia
class TimerBadge extends StatelessWidget {
  final Duration elapsed;
  final bool isLarge;

  const TimerBadge({super.key, required this.elapsed, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    final minutes = elapsed.inMinutes;
    final color = _getColorForTime(minutes);
    final isUrgent = minutes >= 20;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 12 : 8,
        vertical: isLarge ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(isLarge ? 12 : 8),
        border: Border.all(color: color, width: isUrgent ? 2 : 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: isLarge ? 20 : 16, color: color),
          SizedBox(width: isLarge ? 6 : 4),
          Text(
            _formatTime(elapsed),
            style: TextStyle(
              fontSize: isLarge ? 16 : 14,
              fontWeight: isUrgent ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
          if (isUrgent) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.warning_amber_rounded,
              size: isLarge ? 20 : 16,
              color: color,
            ),
          ],
        ],
      ),
    );
  }

  Color _getColorForTime(int minutes) {
    if (minutes < 10) {
      return const Color(0xFF4CAF50); // Verde - Normal
    } else if (minutes < 20) {
      return const Color(0xFFFF9800); // Naranja - Atención
    } else {
      return const Color(0xFFF44336); // Rojo - Urgente/Retraso
    }
  }

  String _formatTime(Duration elapsed) {
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes % 60;

    if (hours > 0) {
      return '$hours h $minutes min';
    } else {
      return '$minutes min';
    }
  }
}

/// Badge pulsante para órdenes urgentes
class UrgentTimerBadge extends StatefulWidget {
  final Duration elapsed;

  const UrgentTimerBadge({super.key, required this.elapsed});

  @override
  State<UrgentTimerBadge> createState() => _UrgentTimerBadgeState();
}

class _UrgentTimerBadgeState extends State<UrgentTimerBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = widget.elapsed.inMinutes;

    if (minutes < 20) {
      return TimerBadge(elapsed: widget.elapsed, isLarge: true);
    }

    return ScaleTransition(
      scale: _animation,
      child: TimerBadge(elapsed: widget.elapsed, isLarge: true),
    );
  }
}
