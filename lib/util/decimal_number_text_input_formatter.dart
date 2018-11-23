import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class DecimalNumberTextInputFormatter extends TextInputFormatter {
  int _decimalPlaces;
  String _prefix = '';
  String _suffix = '';

  DecimalNumberTextInputFormatter({
    int decimalPlaces,
    String prefix,
    String suffix,
  }) {
    this._decimalPlaces = decimalPlaces == null ? 2 : decimalPlaces;
    this._prefix = prefix == null ? '' : '$prefix ';
    this._suffix = suffix == null ? '' : ' $suffix';
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // print('');
    // print('oldValue:  ${oldValue.text}  selected: ${oldValue.selection.start.toString()} to ${oldValue.selection.end.toString()}');
    // print('newValue:  ${newValue.text}  selected: ${newValue.selection.start.toString()} to ${newValue.selection.end.toString()}');

    // Check for no change
    if (newValue.text.compareTo(oldValue.text) == 0) {
      // print('old and new are identical, returning oldValue');
      return oldValue;
    } 
    
    final String stripped = newValue.text
      .replaceAll(RegExp('\\D'), '');

    // Check for zero
    if (double.parse(stripped) == 0.0) {
      // print('Field was zero, returning empty string');
      return TextEditingValue(text: '');
    }

    final int intNum = int.tryParse(stripped);

    // Check for blank field
    if (intNum == null) {
      // print('Field was blank, returning oldValue');
      return oldValue;
    }

    final double dblNum = intNum / pow(10, _decimalPlaces);

    // Attempt 1: This doesn't take into account the comma separator
    // final String newString = dblNum.toStringAsFixed(_decimalPlaces);

    // Attempt 2: This doesn't take into account a suffix such as lbs or percent
    // final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: _decimalPlaces);
    // final String newString = currencyFormat.format(dblNum);

    // Attempt 3: With a prefix
    final String places = List.filled(_decimalPlaces, '0').join();
    final currencyFormat = NumberFormat('#,##0.' + places, 'en_US');
    // final String newString = '$_prefix${currencyFormat.format(dblNum)}';
    // Attempt 4: With a prefix and a suffix
    final String newString = '$_prefix${currencyFormat.format(dblNum)}$_suffix';

    var cursorLocationFromEnd;
    if (oldValue.selection.end < 0) {
      cursorLocationFromEnd = 0;
    } else {
      cursorLocationFromEnd = oldValue.text.length - oldValue.selection.end;
    }
    final int cursorLocation = newString.length - cursorLocationFromEnd;
    
    // print('newString: $newString  selected: $cursorLocation');
    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(
        offset: cursorLocation,
      ),
    );
  }
}
