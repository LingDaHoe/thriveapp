class Medication {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final List<String> times;
  final DateTime startDate;
  final DateTime? endDate;
  final String instructions;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.times,
    required this.startDate,
    this.endDate,
    required this.instructions,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'times': times,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'instructions': instructions,
      'isActive': isActive,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    // Handle nullable or missing fields gracefully
    final timesData = json['times'];
    final times = timesData != null
        ? (timesData is List
            ? List<String>.from(timesData)
            : [timesData.toString()])
        : ['09:00']; // Default to morning if missing
    
    final startDateStr = json['startDate'];
    final startDate = startDateStr != null
        ? (startDateStr is String
            ? DateTime.parse(startDateStr)
            : (startDateStr is DateTime
                ? startDateStr
                : DateTime.now()))
        : DateTime.now();
    
    final createdAtStr = json['createdAt'];
    final createdAt = createdAtStr != null
        ? (createdAtStr is String
            ? DateTime.parse(createdAtStr)
            : (createdAtStr is DateTime
                ? createdAtStr
                : DateTime.now()))
        : DateTime.now();
    
    final updatedAtStr = json['updatedAt'];
    final updatedAt = updatedAtStr != null
        ? (updatedAtStr is String
            ? DateTime.parse(updatedAtStr)
            : (updatedAtStr is DateTime
                ? updatedAtStr
                : DateTime.now()))
        : DateTime.now();
    
    return Medication(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      dosage: json['dosage']?.toString() ?? '',
      frequency: json['frequency']?.toString() ?? 'Once daily',
      times: times,
      startDate: startDate,
      endDate: json['endDate'] != null
          ? (json['endDate'] is String
              ? DateTime.parse(json['endDate'] as String)
              : (json['endDate'] is DateTime
                  ? json['endDate'] as DateTime
                  : null))
          : null,
      instructions: json['instructions']?.toString() ?? 'Take as prescribed',
      isActive: json['isActive'] as bool? ?? true,
      notes: json['notes']?.toString(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    String? frequency,
    List<String>? times,
    DateTime? startDate,
    DateTime? endDate,
    String? instructions,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      times: times ?? this.times,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      instructions: instructions ?? this.instructions,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 