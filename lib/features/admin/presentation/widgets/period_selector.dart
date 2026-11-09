import 'package:flutter/material.dart';
import 'package:pos_restaurante/core/utils/business_day.dart';

/// Período de tiempo para reportes
enum ReportPeriod { today, week, month, custom }

/// Rango de fechas para filtrar reportes
/// IMPORTANTE: Usa día laboral (inicia a las 7am, no a medianoche)
/// Esto es necesario para negocios nocturnos
class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});

  /// Reportes del día laboral actual (desde las 7am de hoy o ayer si es antes de las 7am)
  factory DateRange.today() {
    return DateRange(start: getBusinessDayStart(), end: getBusinessDayEnd());
  }

  /// Últimos 7 días laborales
  factory DateRange.week() {
    return DateRange(
      start: getBusinessDayStartDaysAgo(6),
      end: getBusinessDayEnd(),
    );
  }

  /// Mes actual (desde el día 1 a las 7am)
  factory DateRange.month() {
    return DateRange(start: getBusinessMonthStart(), end: getBusinessDayEnd());
  }

  bool get isToday {
    final todayStart = getBusinessDayStart();
    return start.year == todayStart.year &&
        start.month == todayStart.month &&
        start.day == todayStart.day &&
        start.hour == todayStart.hour;
  }

  bool get isThisWeek {
    final weekStart = getBusinessDayStartDaysAgo(6);
    return start.year == weekStart.year &&
        start.month == weekStart.month &&
        start.day == weekStart.day;
  }

  bool get isThisMonth {
    final monthStart = getBusinessMonthStart();
    return start.year == monthStart.year &&
        start.month == monthStart.month &&
        start.day == monthStart.day;
  }

  int get daysDifference => end.difference(start).inDays + 1;

  String get displayText {
    if (isToday) return 'Hoy';
    if (isThisWeek) return 'Esta Semana';
    if (isThisMonth) return 'Este Mes';

    return '${_formatDate(start)} - ${_formatDate(end)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Selector de período para reportes
class PeriodSelector extends StatelessWidget {
  final ReportPeriod selectedPeriod;
  final Function(ReportPeriod) onPeriodChanged;
  final Function(DateRange)? onCustomRange;

  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    this.onCustomRange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildPeriodButton(
            context,
            label: 'Hoy',
            period: ReportPeriod.today,
            icon: Icons.today,
          ),
          const SizedBox(width: 8),
          _buildPeriodButton(
            context,
            label: 'Semana',
            period: ReportPeriod.week,
            icon: Icons.date_range,
          ),
          const SizedBox(width: 8),
          _buildPeriodButton(
            context,
            label: 'Mes',
            period: ReportPeriod.month,
            icon: Icons.calendar_month,
          ),
          const SizedBox(width: 8),
          _buildPeriodButton(
            context,
            label: 'Otro',
            period: ReportPeriod.custom,
            icon: Icons.tune,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(
    BuildContext context, {
    required String label,
    required ReportPeriod period,
    required IconData icon,
  }) {
    final isSelected = selectedPeriod == period;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (period == ReportPeriod.custom && onCustomRange != null) {
              final range = await _selectCustomRange(context);
              if (range != null) {
                onCustomRange!(range);
              }
            } else {
              onPeriodChanged(period);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFF6B35).withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFF6B35)
                    : Colors.grey.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected ? const Color(0xFFFF6B35) : Colors.grey,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFFF6B35) : Colors.grey,
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<DateRange?> _selectCustomRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(data: ThemeData.dark(), child: child!);
      },
    );

    if (picked != null) {
      return DateRange(
        start: picked.start,
        end: DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        ),
      );
    }
    return null;
  }
}
