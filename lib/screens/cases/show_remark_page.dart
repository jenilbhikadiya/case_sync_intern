import 'package:flutter/material.dart';
import 'task_item.dart';

class ShowRemarkPage extends StatefulWidget {
  final TaskItem taskItem;

  const ShowRemarkPage({Key? key, required this.taskItem}) : super(key: key);

  @override
  _RemarkPageState createState() => _RemarkPageState();
}

class _RemarkPageState extends State<ShowRemarkPage> {
  final _srNoController = TextEditingController();
  final _stageController = TextEditingController();
  final _remarkController = TextEditingController();
  DateTime _remarkDate = DateTime.now();
  DateTime _nextDate = DateTime.now();
  String _status = 'Pending';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        title: const Text('Show Remark'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField('SR. No.', _srNoController.text.isNotEmpty ? _srNoController.text : 'N/A'),
                const SizedBox(height: 16),
                _buildField('Stage', _stageController.text.isNotEmpty ? _stageController.text : 'N/A'),
                const SizedBox(height: 16),
                _buildField('Remark', _remarkController.text.isNotEmpty ? _remarkController.text : 'N/A'),
                const SizedBox(height: 16),
                _buildField(
                  'Remark Date',
                  '${_remarkDate.day.toString().padLeft(2, '0')}/${_remarkDate.month.toString().padLeft(2, '0')}/${_remarkDate.year}',
                ),
                const SizedBox(height: 16),
                _buildField(
                  'Next Date',
                  '${_nextDate.day.toString().padLeft(2, '0')}/${_nextDate.month.toString().padLeft(2, '0')}/${_nextDate.year}',
                ),
                const SizedBox(height: 16),
                _buildField('Status', _status),
                const SizedBox(height: 16),
                _buildButtonsRow(context),
              ],
            ),
          ),
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

  Widget _buildButtonsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: () {
            // Handle edit action
          },
          child: const Text('Edit'),
        ),
        const SizedBox(width: 8.0),
        ElevatedButton(
          onPressed: () {
            // Handle delete action
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
