import 'dart:convert'; // Needed if you use jsonEncode with toJson()

class NotificationItem {
  final String id;
  final String typeId;
  final String type;
  final String senderId;
  final String receiverId;
  final String msg;
  final String status;
  final String playStatus; // Check JSON key consistency ('playstatus'?)
  final DateTime? dateTime; // Check JSON key consistency ('datetime'?)
  final String name;
  final String caseNo; // Check JSON key consistency ('case_no'?)
  final String instruction; // Derived from 'msg'
  final String allotedBy; // Derived from 'name'
  final String
      caseType; // Check JSON key consistency ('caseType' or 'case_type'?)
  final DateTime? date; // Check JSON key consistency ('datetime'?)

  NotificationItem({
    required this.id,
    required this.typeId,
    required this.type,
    required this.senderId,
    required this.receiverId,
    required this.msg,
    required this.status,
    required this.playStatus,
    this.dateTime, // Made optional to align with tryParse
    required this.name,
    required this.caseNo,
    required this.instruction,
    required this.allotedBy,
    required this.caseType,
    this.date,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse DateTime
    DateTime? tryParseDateTime(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    // Helper to safely get string, defaulting to empty string if null or not string
    String getString(dynamic value) => value?.toString() ?? '';

    return NotificationItem(
      // Use getString for safer parsing, especially if API might send non-strings
      id: getString(json['id']),
      typeId: getString(json['task_id']),
      type: getString(json['type']),
      senderId: getString(json['sender_id']),
      receiverId: getString(json['receiver_id']),
      msg: getString(json['msg']),
      status: getString(json['status']),
      playStatus: getString(json['playstatus']), // Check key 'playstatus'
      dateTime: tryParseDateTime(json['datetime']), // Check key 'datetime'
      name: getString(json['name']),
      caseNo: getString(json['case_no']), // Check key 'case_no'
      instruction: getString(json['msg']).trim(), // Still derived from msg
      allotedBy: getString(json['name']), // Still derived from name
      caseType: getString(json['caseType']), // Check key 'caseType'
      date: tryParseDateTime(json[
          'datetime']), // Simplified: Use helper, also check key 'datetime'
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, // No need for .toString() if already String
      'task_id': typeId,
      'type': type,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'msg': msg,
      'status': status,
      'playstatus':
          playStatus, // Check expected key 'playstatus' or 'playStatus'
      'datetime': dateTime
          ?.toIso8601String(), // Check expected key 'datetime' or 'dateTime'
      'name': name,
      // Added missing fields (check expected keys)
      'case_no': caseNo, // Check expected key 'case_no' or 'caseNo'
      'instruction':
          instruction, // This might be redundant if msg is already sent
      'alloted_by': allotedBy, // Check expected key 'alloted_by' or 'allotedBy'
      'caseType': caseType, // Check expected key 'caseType' or 'case_type'
      'date':
          date?.toIso8601String(), // Often same as 'datetime', check if needed
    };
  }

  // --- ADD THIS METHOD ---
  @override
  String toString() {
    return 'NotificationItem(id: $id, taskId: $typeId, type: $type, '
        'senderId: $senderId, receiverId: $receiverId, msg: "$msg", '
        'status: $status, playStatus: $playStatus, dateTime: $dateTime, '
        'name: $name, caseNo: $caseNo, instruction: "$instruction", '
        'allotedBy: $allotedBy, caseType: $caseType, date: $date)';
  }
// ----------------------
}
