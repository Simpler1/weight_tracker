import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class DecimalNumberTextInputFormatter extends TextInputFormatter {
  int decimalPlaces;

  DecimalNumberTextInputFormatter({this.decimalPlaces = 2});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Check for no change
    if (newValue.text.compareTo(oldValue.text) == 0) {
      return oldValue;
    }

    final String stripped = newValue.text.replaceAll(RegExp('\\D'), '');

    // Check for zero
    if (double.parse(stripped) == 0.0) {
      return TextEditingValue(text: '');
    }

    final int intNum = int.tryParse(stripped);

    // Check for blank field
    if (intNum == null) {
      return oldValue;
    }

    final double dblNum = intNum / pow(10, decimalPlaces);

    final String places = List.filled(decimalPlaces, '0').join();
    final currencyFormat = NumberFormat('#,##0.' + places, 'en_US');
    final String newString = currencyFormat.format(dblNum);

    var cursorLocationFromEnd;
    if (oldValue.selection.end < 0) {
      cursorLocationFromEnd = 0;
    } else {
      cursorLocationFromEnd = oldValue.text.length - oldValue.selection.end;
    }
    final int cursorLocation = newString.length - cursorLocationFromEnd;

    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(
        offset: cursorLocation,
      ),
    );
  }
}
