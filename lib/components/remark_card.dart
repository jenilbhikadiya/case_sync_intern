import 'package:flutter/material.dart';

class RemarkCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> remark;

  const RemarkCard({Key? key, required this.index, required this.remark})
      : super(key: key);

  String _formatDate(String? dateString) {
    try {
      if (dateString == null ||
          dateString.isEmpty ||
          dateString == "0000-00-00" ||
          dateString.startsWith("0000")) {
        return 'N/A';
      }
      final parsedDate = DateTime.parse(dateString);
      return '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildField('SR. No.', (index + 1).toString()),
            const SizedBox(height: 16),
            _buildField('Stage', remark['stage'] ?? 'N/A'),
            const SizedBox(height: 16),
            _buildField('Remark', remark['remarks'] ?? 'N/A'),
            const SizedBox(height: 16),
            _buildField('Remark Date', _formatDate(remark['dos'])),
            const SizedBox(height: 16),
            _buildField('Status', remark['status'] ?? 'Pending'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16.0,
            ),
          ),
        ),
      ],
    );
  }
}
