class MxPlace {
  final String state;
  final String muni;
  const MxPlace(this.state, this.muni);
  String get display => '$state — $muni';
  String get query => '$muni,MX';
}

/// Mapa: Estado -> lista de municipios (EJEMPLO, agrega más según necesites)
final Map<String, List<String>> kMxMunicipios = {
  'Ciudad de México': [
    'Ciudad de México', // CDMX tiene alcaldías; usamos ciudad para OWM
  ],
  'Jalisco': [
    'Guadalajara',
    'Zapopan',
    'Tlaquepaque',
    'Tonalá',
    'Tlajomulco de Zúñiga',
    'Puerto Vallarta',
    'Tepatitlán de Morelos',
  ],
  'Nuevo León': [
    'Monterrey',
    'Guadalupe',
    'San Nicolás de los Garza',
    'San Pedro Garza García',
    'Apodaca',
    'Santa Catarina',
  ],
  'Puebla': [
    'Puebla',
    'Tehuacán',
    'Atlixco',
    'San Martín Texmelucan',
    'Cholula',
  ],
  'Querétaro': [
    'Santiago de Querétaro',
    'Corregidora',
    'El Marqués',
    'San Juan del Río',
  ],
  'Yucatán': ['Mérida', 'Valladolid', 'Tizimín', 'Progreso', 'Kanasín'],
};

const List<String> kEstadosOrden = [
  'Ciudad de México',
  'Jalisco',
  'Nuevo León',
  'Puebla',
  'Querétaro',
  'Yucatán',
  // ➕ Agrega el resto: Aguascalientes, Oaxaca, etc...
];

Iterable<MxPlace> filterPlaces(String pattern) sync* {
  final p = pattern.trim().toLowerCase();
  for (final st in kEstadosOrden) {
    final list = kMxMunicipios[st] ?? const [];
    for (final m in list) {
      final item = MxPlace(st, m);
      if (p.isEmpty) {
        yield item;
      } else {
        if (st.toLowerCase().contains(p) || m.toLowerCase().contains(p)) {
          yield item;
        }
      }
    }
  }
}
