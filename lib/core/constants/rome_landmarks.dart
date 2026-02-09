/// A well-known point of interest in Rome.
class Landmark {
  final String id;
  final String nameEn;
  final String nameIt;
  final double lat;
  final double lon;

  const Landmark({
    required this.id,
    required this.nameEn,
    required this.nameIt,
    required this.lat,
    required this.lon,
  });
}

/// Curated list of major Rome landmarks and transport hubs.
const romeLandmarks = <Landmark>[
  Landmark(
      id: 'lm_colosseo',
      nameEn: 'Colosseum',
      nameIt: 'Colosseo',
      lat: 41.8902,
      lon: 12.4922),
  Landmark(
      id: 'lm_termini',
      nameEn: 'Roma Termini',
      nameIt: 'Roma Termini',
      lat: 41.9013,
      lon: 12.5016),
  Landmark(
      id: 'lm_vaticano',
      nameEn: 'Vatican City',
      nameIt: 'Città del Vaticano',
      lat: 41.9029,
      lon: 12.4534),
  Landmark(
      id: 'lm_trevi',
      nameEn: 'Trevi Fountain',
      nameIt: 'Fontana di Trevi',
      lat: 41.9009,
      lon: 12.4833),
  Landmark(
      id: 'lm_piazza_spagna',
      nameEn: 'Spanish Steps',
      nameIt: 'Piazza di Spagna',
      lat: 41.9060,
      lon: 12.4828),
  Landmark(
      id: 'lm_pantheon',
      nameEn: 'Pantheon',
      nameIt: 'Pantheon',
      lat: 41.8986,
      lon: 12.4769),
  Landmark(
      id: 'lm_foro_romano',
      nameEn: 'Roman Forum',
      nameIt: 'Foro Romano',
      lat: 41.8925,
      lon: 12.4853),
  Landmark(
      id: 'lm_campidoglio',
      nameEn: 'Campidoglio',
      nameIt: 'Campidoglio',
      lat: 41.8933,
      lon: 12.4829),
  Landmark(
      id: 'lm_piazza_navona',
      nameEn: 'Piazza Navona',
      nameIt: 'Piazza Navona',
      lat: 41.8992,
      lon: 12.4731),
  Landmark(
      id: 'lm_trastevere',
      nameEn: 'Trastevere',
      nameIt: 'Trastevere',
      lat: 41.8867,
      lon: 12.4700),
  Landmark(
      id: 'lm_tiburtina',
      nameEn: 'Roma Tiburtina',
      nameIt: 'Roma Tiburtina',
      lat: 41.9103,
      lon: 12.5308),
  Landmark(
      id: 'lm_eur', nameEn: 'EUR', nameIt: 'EUR', lat: 41.8321, lon: 12.4725),
  Landmark(
      id: 'lm_san_giovanni',
      nameEn: 'San Giovanni',
      nameIt: 'San Giovanni',
      lat: 41.8857,
      lon: 12.5058),
  Landmark(
      id: 'lm_circo_massimo',
      nameEn: 'Circo Massimo',
      nameIt: 'Circo Massimo',
      lat: 41.8862,
      lon: 12.4853),
  Landmark(
      id: 'lm_piazza_venezia',
      nameEn: 'Piazza Venezia',
      nameIt: 'Piazza Venezia',
      lat: 41.8957,
      lon: 12.4823),
  Landmark(
      id: 'lm_castel_santangelo',
      nameEn: "Castel Sant'Angelo",
      nameIt: "Castel Sant'Angelo",
      lat: 41.9031,
      lon: 12.4663),
  Landmark(
      id: 'lm_villa_borghese',
      nameEn: 'Villa Borghese',
      nameIt: 'Villa Borghese',
      lat: 41.9142,
      lon: 12.4851),
  Landmark(
      id: 'lm_ostiense',
      nameEn: 'Roma Ostiense',
      nameIt: 'Roma Ostiense',
      lat: 41.8716,
      lon: 12.4878),
  Landmark(
      id: 'lm_piramide',
      nameEn: 'Piramide / Testaccio',
      nameIt: 'Piramide / Testaccio',
      lat: 41.8763,
      lon: 12.4815),
  Landmark(
      id: 'lm_san_pietro',
      nameEn: "St. Peter's Basilica",
      nameIt: 'Basilica di San Pietro',
      lat: 41.9022,
      lon: 12.4539),
  Landmark(
      id: 'lm_fiumicino',
      nameEn: 'Fiumicino Airport',
      nameIt: 'Aeroporto di Fiumicino',
      lat: 41.7999,
      lon: 12.2462),
  Landmark(
      id: 'lm_ciampino',
      nameEn: 'Ciampino Airport',
      nameIt: 'Aeroporto di Ciampino',
      lat: 41.7994,
      lon: 12.5949),
  Landmark(
      id: 'lm_bocca_verita',
      nameEn: 'Bocca della Verità',
      nameIt: 'Bocca della Verità',
      lat: 41.8882,
      lon: 12.4815),
  Landmark(
      id: 'lm_campo_fiori',
      nameEn: "Campo de' Fiori",
      nameIt: "Campo de' Fiori",
      lat: 41.8956,
      lon: 12.4722),
];
