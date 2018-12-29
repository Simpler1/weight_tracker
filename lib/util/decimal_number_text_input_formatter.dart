import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class DecimalNumberTextInputFormatter extends TextInputFormatter {
  DecimalNumberTextInputFormatter({this.decimalPlaces = 2});

  final int decimalPlaces;

  String defaultFormat(String textIn) {
    if (textIn == null) textIn = '';
    String textOut = formattedNewValue(TextEditingValue(), TextEditingValue(text: textIn));
    return textOut;
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Check for no change
    if (oldValue != null && newValue.text.compareTo(oldValue.text) == 0) {
      return oldValue;
    }

    String newString = formattedNewValue(oldValue, newValue);

    int cursorLocationFromEnd;
    if (oldValue == null || oldValue.selection.end < 0) {
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

  String formattedNewValue(TextEditingValue oldValue, TextEditingValue newValue) {
    String _digitsAndDots = newValue.text.replaceAll(RegExp('((?!\d|\.).)*'), '');
    if (_digitsAndDots == '') {
      return '';
    }

    final int _lastDot = _digitsAndDots.lastIndexOf('.');
    if (oldValue.text == '') { // Starting from blank
      // Pad or truncate to desired number of decimalPlaces
      if (_lastDot >= 0) {
        final int _currentDecimalPlaces = newValue.text.length - 1 - _lastDot;
        if (_currentDecimalPlaces < decimalPlaces) {
          _digitsAndDots = _digitsAndDots + List.filled(decimalPlaces - _currentDecimalPlaces, '0').join();
        } else if (_currentDecimalPlaces > decimalPlaces) {
          _digitsAndDots = _digitsAndDots.substring(0, _digitsAndDots.length - (_currentDecimalPlaces - decimalPlaces));
        }
      } else {
        _digitsAndDots = _digitsAndDots + List.filled(decimalPlaces, '0').join();
      }
    }

    // Remove all non-digits
    final String stripped = _digitsAndDots.replaceAll(RegExp('\\D'), '');

    // Check for zero
    if (double.tryParse(stripped) == 0.0) {
      return '0';
    }

    final int intNum = int.tryParse(stripped);

    // Check for blank field
    if (intNum == null) {
      return '';
    }

    final double dblNum = intNum / pow(10, decimalPlaces);

    String showDecimal = this.decimalPlaces == 0 ? '' : '.';

    final String places = List.filled(decimalPlaces, '0').join();
    final currencyFormat = NumberFormat('#,##0' + showDecimal + places, 'en_US');
    final String newString = currencyFormat.format(dblNum);

    return newString;
  }
}
