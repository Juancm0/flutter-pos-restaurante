/// Utilidades para el día laboral del negocio
/// El día laboral comienza a las 7:00 AM (no a medianoche)
/// Esto es necesario para negocios nocturnos donde las ventas de
/// la noche del viernes (10pm) y la madrugada del sábado (2am)
/// deben contarse como el mismo día laboral.
library;

/// Hora de corte del día laboral (7:00 AM)
const int businessDayStartHour = 7;

/// Obtiene el inicio del día laboral actual
/// Si son las 2am del sábado, devuelve el viernes a las 7am
/// Si son las 10am del sábado, devuelve el sábado a las 7am
DateTime getBusinessDayStart([DateTime? now]) {
  final current = now ?? DateTime.now();

  // Si la hora actual es antes de las 7am, el día laboral empezó ayer
  if (current.hour < businessDayStartHour) {
    return DateTime(
      current.year,
      current.month,
      current.day - 1,
      businessDayStartHour,
    );
  }

  // Si la hora actual es 7am o después, el día laboral empezó hoy
  return DateTime(
    current.year,
    current.month,
    current.day,
    businessDayStartHour,
  );
}

/// Obtiene el fin del día laboral actual (7am del día siguiente)
DateTime getBusinessDayEnd([DateTime? now]) {
  final start = getBusinessDayStart(now);
  return start.add(const Duration(hours: 24));
}

/// Obtiene el inicio del día laboral hace N días
DateTime getBusinessDayStartDaysAgo(int days) {
  final todayStart = getBusinessDayStart();
  return todayStart.subtract(Duration(days: days));
}

/// Obtiene el inicio de la semana laboral (lunes a las 7am)
DateTime getBusinessWeekStart([DateTime? now]) {
  final dayStart = getBusinessDayStart(now);
  final weekday = dayStart.weekday; // 1 = Lunes, 7 = Domingo
  final daysToSubtract =
      weekday - 1; // Cuántos días restar para llegar al lunes
  return dayStart.subtract(Duration(days: daysToSubtract));
}

/// Obtiene el inicio del mes laboral (día 1 a las 7am)
DateTime getBusinessMonthStart([DateTime? now]) {
  final current = now ?? DateTime.now();
  final dayStart = getBusinessDayStart(current);
  return DateTime(dayStart.year, dayStart.month, 1, businessDayStartHour);
}
