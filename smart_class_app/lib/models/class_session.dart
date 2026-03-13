enum SessionStatus { checkedIn, completed }

class ClassSession {
  final String id;
  final String studentId;
  final DateTime checkInTime;
  final double checkInLat;
  final double checkInLng;
  final String checkInQr;
  final String previousTopic;
  final String expectedTopic;
  final int mood; // mood before class, 1–5
  SessionStatus status;

  // Filled in at finish
  DateTime? finishTime;
  double? finishLat;
  double? finishLng;
  String? finishQr;
  String? learnedToday;
  String? feedback;

  ClassSession({
    required this.id,
    required this.studentId,
    required this.checkInTime,
    required this.checkInLat,
    required this.checkInLng,
    required this.checkInQr,
    required this.previousTopic,
    required this.expectedTopic,
    required this.mood,
    this.status = SessionStatus.checkedIn,
    this.finishTime,
    this.finishLat,
    this.finishLng,
    this.finishQr,
    this.learnedToday,
    this.feedback,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'studentId': studentId,
        'checkInTime': checkInTime.toIso8601String(),
        'checkInLat': checkInLat,
        'checkInLng': checkInLng,
        'checkInQr': checkInQr,
        'previousTopic': previousTopic,
        'expectedTopic': expectedTopic,
        'mood': mood,
        'status': status.name,
        'finishTime': finishTime?.toIso8601String(),
        'finishLat': finishLat,
        'finishLng': finishLng,
        'finishQr': finishQr,
        'learnedToday': learnedToday,
        'feedback': feedback,
      };

  factory ClassSession.fromMap(Map<String, dynamic> map) => ClassSession(
        id: map['id'] as String,
        studentId: map['studentId'] as String,
        checkInTime: DateTime.parse(map['checkInTime'] as String),
        checkInLat: (map['checkInLat'] as num).toDouble(),
        checkInLng: (map['checkInLng'] as num).toDouble(),
        checkInQr: map['checkInQr'] as String,
        previousTopic: map['previousTopic'] as String,
        expectedTopic: map['expectedTopic'] as String,
        mood: map['mood'] as int,
        status: SessionStatus.values.byName(
            (map['status'] as String?) ?? 'checkedIn'),
        finishTime: map['finishTime'] != null
            ? DateTime.parse(map['finishTime'] as String)
            : null,
        finishLat: (map['finishLat'] as num?)?.toDouble(),
        finishLng: (map['finishLng'] as num?)?.toDouble(),
        finishQr: map['finishQr'] as String?,
        learnedToday: map['learnedToday'] as String?,
        feedback: map['feedback'] as String?,
      );
}
