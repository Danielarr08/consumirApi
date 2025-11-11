import 'package:api/core/http_client.dart';
import 'package:api/core/env.dart';
import 'package:api/features/data/models.dart';

class WeatherApi {
  final SafeHttpClient _http;
  WeatherApi(this._http);

  Future<Weather> fetchByCity(
    String q, {
    String units = 'metric',
    String lang = 'es',
  }) async {
    final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
      'q': q,
      'appid': Env.owmApiKey,
      'units': units,
      'lang': lang,
    });
    final json = await _http.getJson(uri);
    return _parse(json, fallbackCity: q);
  }

  // NUEVO: por coordenadas
  Future<Weather> fetchByCoords(
    double lat,
    double lon, {
    String units = 'metric',
    String lang = 'es',
  }) async {
    final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
      'lat': '$lat',
      'lon': '$lon',
      'appid': Env.owmApiKey,
      'units': units,
      'lang': lang,
    });
    final json = await _http.getJson(uri);
    return _parse(
      json,
      fallbackCity: '${lat.toStringAsFixed(3)},${lon.toStringAsFixed(3)}',
    );
  }

  Weather _parse(Map<String, dynamic> json, {required String fallbackCity}) {
    final name = (json['name'] as String?)?.trim();
    final main = (json['main'] as Map?) ?? {};
    final temp = (main['temp'] as num?)?.toDouble() ?? 0;
    final weatherList = (json['weather'] as List?) ?? const [];
    String desc = '—';
    if (weatherList.isNotEmpty &&
        weatherList.first is Map &&
        (weatherList.first as Map)['description'] is String) {
      desc = (weatherList.first as Map)['description'] as String;
    }
    return Weather(
      city: (name == null || name.isEmpty) ? fallbackCity : name,
      tempC: temp,
      description: desc,
    );
  }
}
