// lib/features/ui/home_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';

// Infra (rutas relativas correctas)
import '../../core/cache.dart';
import '../../core/http_client.dart';
import '../../core/sanitizer.dart';

// Datos
import '../data/models.dart';
import '../data/weather_api.dart';

// Widgets (IMPORTES RELATIVOS, sin show, para evitar errores de exportación)
import 'widgets/state_views.dart'; // LoadingView, ErrorView, EmptyView
import 'widgets/weather_card.dart' as wc; // alias para evitar conflictos
import 'widgets/map_card.dart';
import 'widgets/mx_data.dart';

// Ubicación / mapa
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Infraestructura
  final SafeHttpClient _client = SafeHttpClient();
  late final WeatherApi _api = WeatherApi(_client);
  final MemoryCache<Weather> _cache = MemoryCache<Weather>(
    ttl: const Duration(minutes: 5),
  );

  // Controles Autocomplete
  final _stateCtl = TextEditingController();
  final _muniCtl = TextEditingController();
  final _stateNode = FocusNode();
  final _muniNode = FocusNode();

  // Selecciones
  String? _selectedState;
  String? _selectedMuni;

  // Estado UI
  bool _loading = false;
  String? _error;
  Weather? _data;

  // Ubicación actual para el mapa
  LatLng? _myLatLng;

  @override
  void dispose() {
    _stateCtl.dispose();
    _muniCtl.dispose();
    _stateNode.dispose();
    _muniNode.dispose();
    super.dispose();
  }

  List<String> _munisForState(String? state) {
    if (state == null) return const [];
    return kMxMunicipios[state] ?? const [];
  }

  Future<void> _loadByCity() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Cache defensivo
      final cached = _cache.get();
      if (cached != null) {
        setState(() {
          _data = cached;
        });
        return;
      }

      if (_selectedState == null || _selectedMuni == null) {
        throw Exception('Elige Estado y Municipio de la lista.');
      }

      final q = '$_selectedMuni,MX';
      final w = await _api.fetchByCity(q);
      _cache.set(w);
      setState(() {
        _data = w;
        _myLatLng = null; // al buscar por ciudad, limpia pin de mapa
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _useMyLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Activa los servicios de ubicación en tu dispositivo.');
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw Exception('Permiso de ubicación denegado.');
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final w = await _api.fetchByCoords(pos.latitude, pos.longitude);
      _cache.set(w);
      setState(() {
        _data = w;
        _myLatLng = LatLng(pos.latitude, pos.longitude);
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    if (_myLatLng != null) {
      await _useMyLocation();
    } else {
      await _loadByCity();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Clima'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF74ABE2), Color(0xFF5563DE)],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 820; // breakpoint
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _StateMuniPicker(
                      stateCtl: _stateCtl,
                      muniCtl: _muniCtl,
                      stateNode: _stateNode,
                      muniNode: _muniNode,
                      estados: kEstadosOrden,
                      getMunis: _munisForState,
                      onSelectedState: (s) {
                        setState(() {
                          _selectedState = s;
                          _selectedMuni = null;
                          _muniCtl.clear();
                          _cache.clear();
                          _myLatLng = null;
                        });
                      },
                      onSelectedMuni: (m) {
                        setState(() {
                          _selectedMuni = m;
                          _cache.clear();
                          _myLatLng = null;
                        });
                      },
                      loading: _loading,
                      onSearch: _loadByCity,
                      onUseMyLocation: _useMyLocation,
                      optionsPopupBuilder: _optionsPopup,
                    ),
                    const SizedBox(height: 16),

                    // Dos tarjetas en una sola vista: Clima (izq) + Mapa (der)
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildWeatherCard()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildMapCard()),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildWeatherCard(),
                          const SizedBox(height: 16),
                          _buildMapCard(),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Cards ----------
  Widget _buildWeatherCard() {
    if (_loading) {
      return const LoadingView(message: 'Consultando clima…');
    }
    if (_error != null) {
      return ErrorView(_error!);
    }
    final w = _data;
    if (w == null) {
      return const EmptyView('Elige Estado y Municipio o usa tu ubicación.');
    }
    return wc.WeatherCard(
      city: sanitize(w.city),
      tempC: w.tempC,
      description: sanitize(w.description),
      onRefresh: _loading ? null : _refresh,
    );
  }

  Widget _buildMapCard() {
    if (_myLatLng != null) {
      return MapCard(center: _myLatLng!, title: 'Tu ubicación');
    }
    return const _MapaVacioHint();
  }

  // Popup semitransparente (glass) para opciones de Autocomplete
  Widget _optionsPopup(Iterable<String> options, ValueChanged<String> onTap) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 14,
                    spreadRadius: 1,
                    color: Colors.black.withValues(alpha: 0.18),
                  ),
                ],
              ),
              constraints: const BoxConstraints(maxHeight: 320, minWidth: 280),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                itemBuilder: (ctx, i) {
                  final s = options.elementAt(i);
                  return ListTile(
                    leading: Icon(
                      Icons.place_outlined,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                    title: Text(
                      s,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => onTap(s),
                    hoverColor: Colors.white.withValues(alpha: 0.08),
                    splashColor: Colors.white.withValues(alpha: 0.12),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- Widgets auxiliares ----------

class _MapaVacioHint extends StatelessWidget {
  const _MapaVacioHint();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.map_outlined),
        title: const Text('Mapa'),
        subtitle: const Text(
          'Aún no hay ubicación.\nToca “Usar mi ubicación”.',
        ),
      ),
    );
  }
}

/// Picker de Estado + Municipio con Autocomplete y popup glass
class _StateMuniPicker extends StatelessWidget {
  const _StateMuniPicker({
    required this.stateCtl,
    required this.muniCtl,
    required this.stateNode,
    required this.muniNode,
    required this.estados,
    required this.getMunis,
    required this.onSelectedState,
    required this.onSelectedMuni,
    required this.loading,
    required this.onSearch,
    required this.onUseMyLocation,
    required this.optionsPopupBuilder,
  });

  final TextEditingController stateCtl;
  final TextEditingController muniCtl;
  final FocusNode stateNode;
  final FocusNode muniNode;

  final List<String> estados;
  final List<String> Function(String? state) getMunis;
  final ValueChanged<String> onSelectedState;
  final ValueChanged<String> onSelectedMuni;

  final bool loading;
  final VoidCallback onSearch;
  final VoidCallback onUseMyLocation;

  final Widget Function(Iterable<String> options, ValueChanged<String> onTap)
  optionsPopupBuilder;

  @override
  Widget build(BuildContext context) {
    final muniEnabled = estados.contains(stateCtl.text);
    final munis = getMunis(muniEnabled ? stateCtl.text : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Estado
        RawAutocomplete<String>(
          textEditingController: stateCtl,
          focusNode: stateNode,
          optionsBuilder: (tev) {
            final p = tev.text.trim().toLowerCase();
            if (p.isEmpty) return estados;
            return estados.where((e) => e.toLowerCase().contains(p));
          },
          displayStringForOption: (s) => s,
          onSelected: (s) => onSelectedState(s),
          fieldViewBuilder: (ctx, ctl, node, _) {
            return TextField(
              controller: ctl,
              focusNode: node,
              decoration: InputDecoration(
                labelText: 'Estado',
                prefixIcon: const Icon(Icons.public),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ),
              onChanged: (_) => muniCtl.clear(),
            );
          },
          optionsViewBuilder: (ctx, onSelectedCb, options) =>
              optionsPopupBuilder(options, (v) => onSelectedCb(v)),
        ),
        const SizedBox(height: 10),
        // Municipio
        RawAutocomplete<String>(
          textEditingController: muniCtl,
          focusNode: muniNode,
          optionsBuilder: (tev) {
            final p = tev.text.trim().toLowerCase();
            final base = munis;
            if (p.isEmpty) return base;
            return base.where((m) => m.toLowerCase().contains(p));
          },
          displayStringForOption: (s) => s,
          onSelected: (s) => onSelectedMuni(s),
          fieldViewBuilder: (ctx, ctl, node, _) {
            return TextField(
              controller: ctl,
              focusNode: node,
              enabled: muniEnabled,
              decoration: InputDecoration(
                labelText: 'Municipio',
                prefixIcon: const Icon(Icons.location_city),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ),
            );
          },
          optionsViewBuilder: (ctx, onSelectedCb, options) =>
              optionsPopupBuilder(options, (v) => onSelectedCb(v)),
        ),
        const SizedBox(height: 10),
        // Botones
        Row(
          children: [
            FilledButton.icon(
              onPressed: loading ? null : onSearch,
              icon: const Icon(Icons.search),
              label: const Text('Buscar'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: loading ? null : onUseMyLocation,
              icon: const Icon(Icons.my_location),
              label: const Text('Usar mi ubicación'),
            ),
          ],
        ),
      ],
    );
  }
}
