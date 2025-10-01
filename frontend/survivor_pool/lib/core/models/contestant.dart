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

class ContestantDetail {
  final String id;
  final String name;
  final int? age;
  final String? occupation;
  final String? hometown;
  final String? tribeName;
  final String? tribeColor;

  const ContestantDetail({
    required this.id,
    required this.name,
    this.age,
    this.occupation,
    this.hometown,
    this.tribeName,
    this.tribeColor,
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
