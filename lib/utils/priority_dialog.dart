import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PriorityDialog extends StatefulWidget {
  final Function(int?, String) onPrioritySelected;
  final String? caseNumber;

  const PriorityDialog(
      {super.key, required this.onPrioritySelected, this.caseNumber});

  @override
  State<PriorityDialog> createState() => _PriorityDialogState();
}

class _PriorityDialogState extends State<PriorityDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _priorityController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();

  late AnimationController _buttonController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _priorityController.dispose();
    _remarkController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _animateButtonTap() {
    _buttonController.forward().then((_) => _buttonController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    final textColor = Colors.black87;
    final hintColor = Colors.grey.shade600;
    final dividerColor = Colors.grey.shade300;
    final actionButtonTextColor = Colors.black87;
    final destructiveColor = Colors.redAccent;
    final blackBorder = Border.all(color: Colors.black, width: 1.0);

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(16.0),
        border: blackBorder, // Added black border here
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.0,
            offset: Offset(0.0, 5.0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: [
              const Icon(Icons.settings_outlined,
                  color: Colors.black87, size: 28), // Changed the icon
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Set Priority & Remarks",
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    if (widget.caseNumber != null &&
                        widget.caseNumber!.isNotEmpty)
                      Text(
                        "Case No: ${widget.caseNumber}",
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey.shade700,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20.0),
          TextField(
            controller: _priorityController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: 'Priority',
              labelStyle: TextStyle(color: hintColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.black87),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
          ),
          const SizedBox(height: 12.0),
          TextField(
            controller: _remarkController,
            keyboardType: TextInputType.text,
            maxLines: 3,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: 'Remarks (Optional)',
              labelStyle: TextStyle(color: hintColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.black87),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
          ),
          const SizedBox(height: 24.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: actionButtonTextColor,
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
              const SizedBox(width: 8.0),
              ScaleTransition(
                scale: _buttonScaleAnimation,
                child: ElevatedButton(
                  onPressed: () {
                    _animateButtonTap();
                    int? priority = int.tryParse(_priorityController.text);
                    String remark = _remarkController.text.trim();
                    widget.onPrioritySelected(priority, remark);
                    Future.delayed(const Duration(milliseconds: 100), () {
                      Navigator.of(context).pop();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (_priorityController.text.isNotEmpty ||
                  _remarkController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _priorityController.clear();
                        _remarkController.clear();
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: destructiveColor,
                    ),
                    child: Text(
                      'Clear',
                      style: TextStyle(color: destructiveColor, fontSize: 16.0),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
