class FocusSoundOption {
  final String id;
  final String label;
  final String description;

  const FocusSoundOption({
    required this.id,
    required this.label,
    required this.description,
  });

  static const String defaultFocusSoundId = 'clear_chime';
  static const String defaultBreakSoundId = 'soft_chime';

  static const List<FocusSoundOption> all = [
    FocusSoundOption(
      id: 'clear_chime',
      label: 'Clear chime',
      description: 'Bright, crisp completion tone',
    ),
    FocusSoundOption(
      id: 'soft_chime',
      label: 'Soft chime',
      description: 'Gentle, low-volume chime',
    ),
    FocusSoundOption(
      id: 'gentle_bell',
      label: 'Gentle bell',
      description: 'Warm bell with a soft tail',
    ),
    FocusSoundOption(
      id: 'digital_beep',
      label: 'Digital beep',
      description: 'Short electronic beep',
    ),
    FocusSoundOption(
      id: 'classic_alarm',
      label: 'Classic alarm',
      description: 'Traditional alarm-style alert',
    ),
  ];

  static FocusSoundOption byId(String id) {
    return all.firstWhere(
      (option) => option.id == id,
      orElse: () => all.first,
    );
  }

  static String labelFor(String id) => byId(id).label;

  static String assetPath(String id) => 'sounds/${byId(id).id}.wav';

  static String androidRawName(String id) => byId(id).id;
}
