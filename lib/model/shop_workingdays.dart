// shop_workingdays.dart
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class WorkingDay {
  final int weekday;
  final bool isOpen;
  final TimeOfDay? openTime;
  final TimeOfDay? closeTime;
  final List<BreakTime> breaks;

  WorkingDay({
    required this.weekday,
    required this.isOpen,
    this.openTime,
    this.closeTime,
    required this.breaks,
  });

  factory WorkingDay.fromJson(Map<String, dynamic> json) {
    return WorkingDay(
      weekday: json['weekday'],
      isOpen: json['is_open'],
      openTime: json['open_time'] != null
          ? _parseTimeString(json['open_time'])
          : null,
      closeTime: json['close_time'] != null
          ? _parseTimeString(json['close_time'])
          : null,
      breaks: (json['breaks'] as List)
          .map((b) => BreakTime.fromJson(b))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekday': weekday,
      'is_open': isOpen,
      'open_time': openTime != null ? _formatTimeForApi(openTime!) : null,
      'close_time': closeTime != null ? _formatTimeForApi(closeTime!) : null,
      'breaks': breaks.map((b) => b.toJson()).toList(),
    };
  }

  WorkingDay copyWith({
    int? weekday,
    bool? isOpen,
    TimeOfDay? openTime,
    TimeOfDay? closeTime,
    List<BreakTime>? breaks,
  }) {
    return WorkingDay(
      weekday: weekday ?? this.weekday,
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      breaks: breaks ?? this.breaks,
    );
  }
}

class BreakTime {
  final TimeOfDay start;
  final TimeOfDay end;
  final int? id;

  BreakTime({required this.start, required this.end, this.id});

  factory BreakTime.fromJson(Map<String, dynamic> json) {
    return BreakTime(
      id: json['id'],
      start: _parseTimeString(json['start_time']),
      end: _parseTimeString(json['end_time']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'start_time': _formatTimeForApi(start),
      'end_time': _formatTimeForApi(end),
    };
  }
}

class SpecialDay {
  final int? id;
  final DateTime date;
  final bool isOpen;
  final TimeOfDay? openTime;
  final TimeOfDay? closeTime;
  final List<BreakTime> breaks;

  SpecialDay({
    this.id,
    required this.date,
    required this.isOpen,
    this.openTime,
    this.closeTime,
    required this.breaks,
  });

  factory SpecialDay.fromJson(Map<String, dynamic> json) {
    return SpecialDay(
       id: json['id'], 
      date: DateTime.parse(json['date']),
      isOpen: json['is_open'],
      openTime: json['open_time'] != null
          ? _parseTimeString(json['open_time'])
          : null,
      closeTime: json['close_time'] != null
          ? _parseTimeString(json['close_time'])
          : null,
      breaks: (json['breaks'] as List)
          .map((b) => BreakTime.fromJson(b))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id, 
      'date': DateFormat('yyyy-MM-dd').format(date),
      'is_open': isOpen,
      'open_time': openTime != null ? _formatTimeForApi(openTime!) : null,
      'close_time': closeTime != null ? _formatTimeForApi(closeTime!) : null,
      'breaks': breaks.map((b) => b.toJson()).toList(),
    };
  }

  SpecialDay copyWith({
     int? id,
    DateTime? date,
    bool? isOpen,
    TimeOfDay? openTime,
    TimeOfDay? closeTime,
    List<BreakTime>? breaks,
  }) {
    return SpecialDay(
      id: id ?? this.id,
      date: date ?? this.date,
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      breaks: breaks ?? this.breaks,
    );
  }
}

// Helper functions
TimeOfDay _parseTimeString(String timeString) {
  final parts = timeString.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

String _formatTimeForApi(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
}
