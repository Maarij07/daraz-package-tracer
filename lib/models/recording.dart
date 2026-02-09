class Recording {
  final int? id;
  final String orderNumber;
  final String date;
  final String time;
  final String videoPath;
  final String photoPath;

  Recording({
    this.id,
    required this.orderNumber,
    required this.date,
    required this.time,
    required this.videoPath,
    required this.photoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'date': date,
      'time': time,
      'videoPath': videoPath,
      'photoPath': photoPath,
    };
  }

  factory Recording.fromMap(Map<String, dynamic> map) {
    return Recording(
      id: map['id'] as int?,
      orderNumber: map['orderNumber'] as String,
      date: map['date'] as String,
      time: map['time'] as String,
      videoPath: map['videoPath'] as String,
      photoPath: map['photoPath'] as String,
    );
  }
}
