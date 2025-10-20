import 'activity.dart'; // Import Activity model

class TravelDay {
  final int day;
  final String date;
  final int tabIndex; // Chỉ số tab (0 đến 6)
  final List<Activity> activities;

  TravelDay({
    required this.day,
    required this.date,
    required this.tabIndex,
    required this.activities,
  });

  // Chuyển từ JSON (Map)
  factory TravelDay.fromJson(Map<String, dynamic> json) {
    return TravelDay(
      day: json['day'] as int,
      date: json['date'] as String,
      tabIndex: json['tabIndex'] as int,
      activities: (json['activities'] as List)
          .map((item) => Activity.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  // Chuyển sang JSON (Map)
  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'date': date,
      'tabIndex': tabIndex,
      'activities': activities.map((e) => e.toJson()).toList(),
    };
  }
}