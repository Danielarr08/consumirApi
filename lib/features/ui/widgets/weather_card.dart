import 'dart:ui';
import 'package:flutter/material.dart';

IconData _iconFor(String desc) {
  final d = desc.toLowerCase();
  if (d.contains('tormenta') || d.contains('storm') || d.contains('thunder')) {
    return Icons.thunderstorm;
  }
  if (d.contains('lluv') || d.contains('rain') || d.contains('drizzle')) {
    return Icons.umbrella;
  }
  if (d.contains('nieve') || d.contains('snow')) {
    return Icons.ac_unit;
  }
  if (d.contains('nube') || d.contains('cloud')) {
    return Icons.cloud;
  }
  if (d.contains('niebla') || d.contains('mist') || d.contains('fog')) {
    return Icons.water_drop;
  }
  return Icons.wb_sunny; // default soleado
}

String _tempString(double c) => '${c.toStringAsFixed(0)}°';

class WeatherCard extends StatelessWidget {
  const WeatherCard({
    super.key,
    required this.city,
    required this.tempC,
    required this.description,
    this.onRefresh,
  });

  final String city;
  final double tempC;
  final String description;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final icon = _iconFor(description);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(icon, size: 40, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      city,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Actualizar',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _tempString(tempC),
                style: const TextStyle(
                  fontSize: 72,
                  height: 1.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description[0].toUpperCase() + description.substring(1),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.95),
                ),
              ),
              const SizedBox(height: 16),
              // Mini “chips” de demo (futuros extras: humedad, viento, etc.)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(
                    Icons.thermostat,
                    'Sensación',
                    '${tempC.toStringAsFixed(1)}°C',
                  ),
                  _chip(Icons.language, 'Fuente', 'OpenWeather'),
                  _chip(Icons.lock, 'HTTPS', 'OK'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData i, String k, String v) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(i, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            '$k: ',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(v, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
