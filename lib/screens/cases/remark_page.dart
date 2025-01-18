import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'task_item.dart';

class RemarkPage extends StatefulWidget {
  final TaskItem taskItem;

  const RemarkPage({Key? key, required this.taskItem}) : super(key: key);

  @override
  _RemarkPageState createState() => _RemarkPageState();
}

class _RemarkPageState extends State<RemarkPage> {
  final _formKey = GlobalKey<FormState>();
  final _remarkController = TextEditingController();
  final _currentStageController = TextEditingController();
  final _nextStageController = TextEditingController();
  String _documentPath = '';
  DateTime _remarkDate = DateTime.now();
  DateTime _nextDate = DateTime.now();
  String _status = 'Pending';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        title: const Text('Remark'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFieldTitle('Current Stage'),
              _buildTextField(
                controller: _currentStageController,
                inputType: TextInputType.text, label: '',
              ),
              _buildFieldTitle('Remark'),
              _buildTextField(
                controller: _remarkController,
                inputType: TextInputType.text, label: '',
              ),
              _buildFieldTitle('Remark Date'),
              _buildRemarkBoxField(),
              _buildFieldTitle('Document'),
              _buildDocumentBoxField(),
              _buildFieldTitle('Next Stage'),
              _buildTextField(
                controller: _nextStageController,
                inputType: TextInputType.text, label: '',
              ),
              _buildFieldTitle('Next Date'),
              _buildNextDateBoxField(),
              _buildFieldTitle('Status'),
              _buildStatusRadioButtons(),
              const SizedBox(height: 30),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required TextInputType inputType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        keyboardType: inputType,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildRemarkBoxField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _buildOutlinedBoxField(
        child: ListTile(
          title: Text(
            '${_remarkDate.day.toString().padLeft(2, '0')}/${_remarkDate.month.toString().padLeft(2, '0')}/${_remarkDate.year}',
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () => _selectDate(_remarkDate),
        ),
      ),
    );
  }

  Widget _buildDocumentBoxField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _buildOutlinedBoxField(
        child: Row(
          children: [
            Expanded(
              child: Text(
                _documentPath.isEmpty
                    ? 'Upload Document'
                    : 'Document: ${_documentPath.split('/').last}',
              ),
            ),
            GestureDetector(
              onTap: _uploadDocument,
              child: const Icon(Icons.upload_file),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextDateBoxField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _buildOutlinedBoxField(
        child: ListTile(
          title: Text(
            '${_nextDate.day.toString().padLeft(2, '0')}/${_nextDate.month.toString().padLeft(2, '0')}/${_nextDate.year}',
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () => _selectDate(_nextDate),
        ),
      ),
    );
  }

  Widget _buildOutlinedBoxField({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: child,
    );
  }

  Future<void> _selectDate(DateTime date) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2021),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != date) {
      setState(() {
        if (date == _remarkDate) {
          _remarkDate = picked;
        } else if (date == _nextDate) {
          _nextDate = picked;
        }
      });
    }
  }

  Widget _buildStatusRadioButtons() {
    return Column(
      children: [
        RadioListTile(
          title: const Text('Pending'),
          activeColor: Colors.black,
          value: 'Pending',
          groupValue: _status,
          onChanged: (value) {
            setState(() {
              _status = value!;
            });
          },
        ),
        RadioListTile(
          title: const Text('Completed'),
          activeColor: Colors.black,
          value: 'Completed',
          groupValue: _status,
          onChanged: (value) {
            setState(() {
              _status = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: ElevatedButton(
        onPressed: _submitForm,
        child: const Text('Submit'),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  Future<void> _uploadDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        setState(() {
          _documentPath = result.files.single.path ?? 'No path available';
        });
      } else {
        print('No file selected');
      }
    } catch (e) {
      print("Error while picking file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      print('Form Submitted');
    }
  }
}
