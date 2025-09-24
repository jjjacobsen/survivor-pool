class SeasonOption {
  final String id;
  final String name;
  final int? number;

  const SeasonOption({required this.id, required this.name, this.number});

  factory SeasonOption.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['_id'];
    final name = json['season_name'] as String? ?? '';
    final dynamicNumber = json['season_number'];
    int? parsedNumber;
    if (dynamicNumber is int) {
      parsedNumber = dynamicNumber;
    } else if (dynamicNumber is num) {
      parsedNumber = dynamicNumber.toInt();
    } else if (dynamicNumber is String) {
      parsedNumber = int.tryParse(dynamicNumber);
    }

    return SeasonOption(
      id: (rawId as String?) ?? '',
      name: name,
      number: parsedNumber,
    );
  }

  String get label {
    if (number != null && number! > 0) {
      return 'Season $number - $name';
    }
    return name.isNotEmpty ? name : 'Unknown season';
  }
}
