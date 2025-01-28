import 'package:flutter/material.dart';

class FilterModal {
  static void showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Center(
            child: Text(
              'Filter options here',
              style: TextStyle(fontSize: 20),
            ),
          ),
        );
      },
    );
  }
}
