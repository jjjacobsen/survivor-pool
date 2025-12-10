import 'pick.dart';

class AvailableContestant {
  final String id;
  final String name;
  final String? subtitle;
  final String? tribeName;
  final String? tribeColor;

  const AvailableContestant({
    required this.id,
    required this.name,
    this.subtitle,
    this.tribeName,
    this.tribeColor,
  });

  factory AvailableContestant.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final name = json['name'] as String? ?? '';
    final subtitle = json['subtitle'];
    final tribeName = json['tribe_name'];
    final tribeColor = json['tribe_color'];
    return AvailableContestant(
      id: id,
      name: name.isEmpty ? id : name,
      subtitle: subtitle is String && subtitle.isNotEmpty ? subtitle : null,
      tribeName: tribeName is String ? tribeName : null,
      tribeColor: tribeColor is String ? tribeColor : null,
    );
  }
}

class ContestantAdvantage {
  final String id;
  final String label;
  final String value;
  final String? acquisitionNotes;
  final String? endNotes;
  final int? endWeek;

  const ContestantAdvantage({
    required this.id,
    required this.label,
    required this.value,
    this.acquisitionNotes,
    this.endNotes,
    this.endWeek,
  });

  factory ContestantAdvantage.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final label = json['label'] as String? ?? 'Advantage';
    final value = json['value'] as String? ?? label;
    final acquisitionNotes = json['acquisition_notes'] as String?;
    final endNotes = json['end_notes'] as String?;
    final endWeek = json['end_week'] as int?;
    return ContestantAdvantage(
      id: id.isEmpty ? label : id,
      label: label.isEmpty ? 'Advantage' : label,
      value: value.isEmpty ? label : value,
      acquisitionNotes: acquisitionNotes,
      endNotes: endNotes,
      endWeek: endWeek,
    );
  }
}

class ContestantDetail {
  final String id;
  final String name;
  final int? age;
  final String? occupation;
  final String? hometown;
  final String? tribeName;
  final String? tribeColor;
  final List<ContestantAdvantage> advantages;

  const ContestantDetail({
    required this.id,
    required this.name,
    this.age,
    this.occupation,
    this.hometown,
    this.tribeName,
    this.tribeColor,
    this.advantages = const [],
  });

  factory ContestantDetail.fromJson(Map<String, dynamic> json) {
    final rawAge = json['age'];
    int? parsedAge;
    if (rawAge is int) {
      parsedAge = rawAge;
    } else if (rawAge is num) {
      parsedAge = rawAge.toInt();
    } else if (rawAge is String) {
      parsedAge = int.tryParse(rawAge);
    }

    final advantagesData = json['advantages'];
    final advantages = <ContestantAdvantage>[];
    if (advantagesData is List) {
      for (final entry in advantagesData) {
        if (entry is Map<String, dynamic>) {
          advantages.add(ContestantAdvantage.fromJson(entry));
        }
      }
    }

    return ContestantDetail(
      id: json['id'] as String? ?? '',
      name: (json['name'] is String && (json['name'] as String).isNotEmpty)
          ? json['name'] as String
          : (json['id'] as String? ?? ''),
      age: parsedAge,
      occupation: json['occupation'] as String?,
      hometown: json['hometown'] as String?,
      tribeName: json['tribe_name'] as String?,
      tribeColor: json['tribe_color'] as String?,
      advantages: advantages,
    );
  }
}

class ContestantDetailResponse {
  final ContestantDetail contestant;
  final bool isAvailable;
  final int? eliminatedWeek;
  final int? alreadyPickedWeek;
  final CurrentPickSummary? currentPick;

  const ContestantDetailResponse({
    required this.contestant,
    required this.isAvailable,
    this.eliminatedWeek,
    this.alreadyPickedWeek,
    this.currentPick,
  });

  factory ContestantDetailResponse.fromJson(Map<String, dynamic> json) {
    final contestantJson = json['contestant'] as Map<String, dynamic>?;
    final currentPickJson = json['current_pick'] as Map<String, dynamic>?;
    return ContestantDetailResponse(
      contestant: contestantJson != null
          ? ContestantDetail.fromJson(contestantJson)
          : const ContestantDetail(id: '', name: ''),
      isAvailable: json['is_available'] as bool? ?? false,
      eliminatedWeek: json['eliminated_week'] is int
          ? json['eliminated_week'] as int
          : int.tryParse('${json['eliminated_week']}'),
      alreadyPickedWeek: json['already_picked_week'] is int
          ? json['already_picked_week'] as int
          : int.tryParse('${json['already_picked_week']}'),
      currentPick: currentPickJson != null
          ? CurrentPickSummary.fromJson(currentPickJson)
          : null,
    );
  }
}
