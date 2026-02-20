class SeasonOption {
  final String id;
  final String name;
  final int? number;
  final int? finalWeek;

  const SeasonOption({
    required this.id,
    required this.name,
    this.number,
    this.finalWeek,
  });

  factory SeasonOption.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['_id'];
    final name = json['season_name'] as String? ?? '';
    final dynamicNumber = json['season_number'];
    final dynamicFinalWeek = json['final_week'] ?? json['finalWeek'];
    int? parsedNumber;
    int? parsedFinalWeek;
    if (dynamicNumber is int) {
      parsedNumber = dynamicNumber;
    } else if (dynamicNumber is num) {
      parsedNumber = dynamicNumber.toInt();
    } else if (dynamicNumber is String) {
      parsedNumber = int.tryParse(dynamicNumber);
    }
    if (dynamicFinalWeek is int) {
      parsedFinalWeek = dynamicFinalWeek;
    } else if (dynamicFinalWeek is num) {
      parsedFinalWeek = dynamicFinalWeek.toInt();
    } else if (dynamicFinalWeek is String) {
      parsedFinalWeek = int.tryParse(dynamicFinalWeek);
    }

    return SeasonOption(
      id: (rawId as String?) ?? '',
      name: name,
      number: parsedNumber,
      finalWeek: parsedFinalWeek,
    );
  }

  String get label {
    if (number != null && number! > 0) {
      return 'Season $number';
    }
    return name.isNotEmpty ? name : 'Unknown season';
  }
}
