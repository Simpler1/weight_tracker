import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redux/redux.dart';
import 'package:weight_tracker/logic/actions.dart';
import 'package:weight_tracker/logic/redux_state.dart';
import 'package:weight_tracker/main.dart';
import 'package:weight_tracker/screens/main_page.dart';
import 'package:weight_tracker/screens/statistics_page.dart';

void main() {
  testWidgets('App name in header', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    expect(find.widgetWithText(AppBar, 'Weight Tracker'), findsOneWidget);
  });

  testWidgets('Main screen has two tabs', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    expect(find.byType(Tab), findsNWidgets(2));
  });

  testWidgets('Main screen has statistics tab in bar', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    expect(
        find.byWidgetPredicate((widget) =>
            widget is Tab &&
            widget.key == Key('StatisticsTab') &&
            widget.text == 'STATISTICS' &&
            (widget.icon as Icon).icon == Icons.show_chart),
        findsOneWidget);
  });

  testWidgets('Main screen has statistics tab in tabview ', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    expect(find.byType(StatisticsPage), findsOneWidget);
  });

  testWidgets('Main screen has history tab in bar', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    expect(
        find.byWidgetPredicate((widget) =>
            widget is Tab &&
            widget.key == Key('HistoryTab') &&
            widget.text == 'HISTORY' &&
            (widget.icon as Icon).icon == Icons.history),
        findsOneWidget);
  });

  testWidgets("Main screen calls GetSaveNote", (WidgetTester tester) async {
    bool wasGetSavedNoteCalled = false;
    var reduce = (ReduxState state, action) {
      if (action is GetSavedWeightNote) {
        wasGetSavedNoteCalled = true;
      }
      return state;
    };
    Store<ReduxState> store = Store(reduce, initialState: ReduxState());
    await tester.pumpWidget(StoreProvider(
      store: store,
      child: MaterialApp(
        home: MainPage(title: "Weight Tracker"),
      ),
    ));
    expect(wasGetSavedNoteCalled, true);
  });
}
