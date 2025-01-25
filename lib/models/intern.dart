class Intern {
  final String id;
  final String name;
  final String contact;
  final String email;
  final String status;
  final String password;
  final String dateTime;

  Intern({
    required this.id,
    required this.name,
    required this.contact,
    required this.email,
    required this.status,
    required this.password,
    required this.dateTime,
  });

  // Factory method to create an Advocate from a JSON response
  factory Intern.fromJson(Map<String, dynamic> json) {
    return Intern(
      id: json['id'],
      name: json['name'],
      contact: json['contact'],
      email: json['email'],
      status: json['status'],
      password: json['password'],
      dateTime: json['date_time'],
    );
  }

  String? get role => null;

  // Method to convert Advocate to JSON for SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contact': contact,
      'email': email,
      'status': status,
      'password': password,
      'date_time': dateTime,
    };
  }
}
