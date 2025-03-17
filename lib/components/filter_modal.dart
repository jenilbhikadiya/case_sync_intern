import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FilterModal {
  static void showFilterModal(
    BuildContext context, {
    required String? selectedCity,
    required String? selectedCourt,
    required DateTime? selectedNextDate,
    required List<String> cities,
    required List<String> courts,
    required Function(String?) onCitySelected,
    required Function(String?) onCourtSelected,
    required Function(DateTime?) onDateSelected,
    required Function() onApply,
    required Function() onReset,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 300),
      ),
      builder: (BuildContext context) {
        return _FilterModalContent(
          initialCity: selectedCity,
          initialCourt: selectedCourt,
          initialNextDate: selectedNextDate,
          cities: cities,
          courts: courts,
          onCitySelected: onCitySelected,
          onCourtSelected: onCourtSelected,
          onDateSelected: onDateSelected,
          onApply: onApply,
          onReset: onReset,
        );
      },
    );
  }
}

class _FilterModalContent extends StatefulWidget {
  final String? initialCity;
  final String? initialCourt;
  final DateTime? initialNextDate;
  final List<String> cities;
  final List<String> courts;
  final Function(String?) onCitySelected;
  final Function(String?) onCourtSelected;
  final Function(DateTime?) onDateSelected;
  final Function() onApply;
  final Function() onReset;

  const _FilterModalContent({
    required this.initialCity,
    required this.initialCourt,
    required this.initialNextDate,
    required this.cities,
    required this.courts,
    required this.onCitySelected,
    required this.onCourtSelected,
    required this.onDateSelected,
    required this.onApply,
    required this.onReset,
  });

  @override
  _FilterModalContentState createState() => _FilterModalContentState();
}

class _FilterModalContentState extends State<_FilterModalContent> {
  late String? selectedCity;
  late String? selectedCourt;
  late DateTime? selectedNextDate = DateTime.now();
  late TextEditingController dateController;

  @override
  void initState() {
    super.initState();
    selectedCity = widget.initialCity ?? "All";
    selectedCourt = widget.initialCourt ?? "All";
    selectedNextDate = widget.initialNextDate;
    dateController = TextEditingController(
      text: selectedNextDate != null
          ? DateFormat('dd-MM-yyyy').format(selectedNextDate!)
          : DateFormat('dd-MM-yyyy').format(DateTime.now()),
    );
  }

  @override
  void dispose() {
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F3),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[500],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            _buildDropdown("Court", selectedCourt, ["All", ...widget.courts],
                (value) {
              setState(() => selectedCourt = value);
              widget.onCourtSelected(value);
            }),
            _buildDropdown("City", selectedCity, ["All", ...widget.cities],
                (value) {
              setState(() => selectedCity = value);
              widget.onCitySelected(value);
            }),
            _buildDatePicker(),
            const SizedBox(height: 30),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items,
      Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Next Date", style: _labelStyle),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: selectedNextDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (pickedDate != null) {
              setState(() {
                selectedNextDate = pickedDate;
                dateController.text =
                    DateFormat('dd-MM-yyyy').format(pickedDate);
              });
              widget.onDateSelected(pickedDate);
            }
          },
          child: AbsorbPointer(
            child: TextFormField(
              controller: dateController,
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon:
                    const Icon(Icons.calendar_today, color: Colors.black54),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                selectedCity = "All";
                selectedCourt = "All";
                selectedNextDate = DateTime.now();
                dateController.text =
                    DateFormat("dd-MM-yyyy").format(DateTime.now());
              });
              widget.onReset();
            },
            child: const Text("Reset",
                style: TextStyle(color: Colors.red, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  static const TextStyle _labelStyle =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w500);
}
