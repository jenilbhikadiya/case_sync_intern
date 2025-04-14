class Notifications {
  final String id;
  final String taskId;
  final String type;
  final String senderId;
  final String receiverId;
  final String msg;
  final String status;
  final String playStatus;
  final DateTime? dateTime;
  final String name;

  Notifications({
    required this.id,
    required this.taskId,
    required this.type,
    required this.senderId,
    required this.receiverId,
    required this.msg,
    required this.status,
    required this.playStatus,
    required this.dateTime,
    required this.name,
  });

  factory Notifications.fromJson(Map<String, dynamic> json) {
    return Notifications(
      id: json['id'].toString(),
      taskId: json['task_id'].toString(),
      type: json['type']?.toString() ?? '',
      senderId: json['sender_id'].toString(),
      receiverId: json['receiver_id'].toString(),
      msg: json['msg']?.toString() ?? '',
      status: json['status'].toString(),
      playStatus: json['playstatus'].toString(),
      dateTime: DateTime.tryParse(json['datetime']?.toString() ?? ''),
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'task_id': taskId.toString(),
      'type': type.toString(),
      'sender_id': senderId.toString(),
      'receiver_id': receiverId.toString(),
      'msg': msg.toString(),
      'status': status.toString(),
      'playstatus': playStatus.toString(),
      'datetime': dateTime?.toIso8601String(),
      'name': name,
    };
  }
}
