import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weight_tracker/model/weight_entry.dart';
import 'package:weight_tracker/widgets/weight_list_item.dart';

//materialapp and scaffold are needed for formatting date
void main() {
  testWidgets('Displays weight and difference in lbs', (WidgetTester tester) async {
    WeightEntry entry = new WeightEntry(new DateTime.now(), 150.0, null, null);
    await tester.pumpWidget(new MaterialApp(home: new Scaffold(body: new WeightListItem(entry, 10.0, 'lbs'))));

    expect(find.text('150.0'), findsOneWidget);
    expect(find.text('+10.0'), findsOneWidget);
  });

  testWidgets('Displays weight and difference in kg', (WidgetTester tester) async {
    WeightEntry entry = new WeightEntry(new DateTime.now(), 150.0, null, null);
    await tester.pumpWidget(new MaterialApp(home: new Scaffold(body: new WeightListItem(entry, 10.0, 'kg'))));

    expect(find.text('68.0'), findsOneWidget);
    expect(find.text('+4.5'), findsOneWidget);
  });
}
