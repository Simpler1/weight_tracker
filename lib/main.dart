import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:weight_tracker/logic/actions.dart';
import 'package:weight_tracker/logic/middleware.dart';
import 'package:weight_tracker/logic/reducer.dart';
import 'package:weight_tracker/logic/redux_state.dart';
import 'package:weight_tracker/screens/main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final Store<ReduxState> store = Store<ReduxState>(reduce,
      initialState: ReduxState(
          entries: [],
          unit: 'lbs',
          removedEntryState: RemovedEntryState(hasEntryBeenRemoved: false),
          firebaseState: FirebaseState(),
          mainPageState: MainPageReduxState(hasEntryBeenAdded: false),
          weightEntryDialogState: WeightEntryDialogReduxState()),
      middleware: [middleware].toList());

  @override
  Widget build(BuildContext context) {
    store.dispatch(InitAction());
    return StoreProvider(
      store: store,
      child: MaterialApp(
        title: 'Weight Tracker',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
        ),
        home: MainPage(title: "Weight Tracker"),
      ),
    );
  }
}
