import 'dart:io';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:redux/redux.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weight_tracker/logic/actions.dart';
import 'package:weight_tracker/logic/constants.dart';
import 'package:weight_tracker/logic/redux_state.dart';
import 'package:weight_tracker/model/weight_entry.dart';
import 'package:google_sign_in/google_sign_in.dart';

middleware(Store<ReduxState> store, action, NextDispatcher next) {
  print(action.runtimeType);
  if (action is InitAction) {
    _handleInitAction(store);
  } else if (action is AddEntryAction) {
    _handleAddEntryAction(store, action);
  } else if (action is EditEntryAction) {
    _handleEditEntryAction(store, action);
  } else if (action is RemoveEntryAction) {
    _handleRemoveEntryAction(store, action);
  } else if (action is UndoRemovalAction) {
    _handleUndoRemovalAction(store);
  } else if (action is SetUnitAction) {
    _handleSetUnitAction(action, store);
  } else if (action is GetSavedWeightNote) {
    _handleGetSavedWeightNote(store);
  } else if (action is AddWeightFromNotes) {
    _handleAddWeightFromNotes(store, action);
  }
  next(action);
  if (action is UserLoadedAction) {
    _handleUserLoadedAction(store);
  } else if (action is AddDatabaseReferenceAction) {
    _handleAddedDatabaseReference(store);
  }
}

_handleAddWeightFromNotes(Store<ReduxState> store, AddWeightFromNotes action) {
  if (store.state.firebaseState?.mainReference != null) {
    WeightEntry weightEntry = WeightEntry(DateTime.now(), action.weight, null, null);
    store.dispatch(AddEntryAction(weightEntry));
    action = AddWeightFromNotes(null);
  }
}

_handleGetSavedWeightNote(Store<ReduxState> store) async {
  double savedWeight = await _getSavedWeightNote();
  if (savedWeight != null) {
    store.dispatch(AddWeightFromNotes(savedWeight));
  }
}

Future<double> _getSavedWeightNote() async {
  String sharedData = await const MethodChannel('app.channel.shared.data').invokeMethod("getSavedNote");
  if (sharedData != null) {
    int firstIndex = sharedData.indexOf(RegExp("[0-9]"));
    int lastIndex = sharedData.lastIndexOf(RegExp("[0-9]"));
    if (firstIndex != -1) {
      String number = sharedData.substring(firstIndex, lastIndex + 1);
      double num = double.tryParse(number);
      return num;
    }
  }
  return null;
}

_handleAddedDatabaseReference(Store<ReduxState> store) {
  double weight = store.state.weightFromNotes;
  if (weight != null) {
    if (store.state.unit == 'kg') {
      weight = weight / LB_KG_RATIO;
    }
    if (weight >= MIN_LB_VALUE && weight <= MAX_LB_VALUE) {
      WeightEntry weightEntry = WeightEntry(DateTime.now(), weight, null, null);
      store.dispatch(AddEntryAction(weightEntry));
      store.dispatch(ConsumeWeightFromNotes());
    }
  }
}

_handleUserLoadedAction(Store<ReduxState> store) {
  store.dispatch(AddDatabaseReferenceAction(
      FirebaseDatabase.instance.reference().child(store.state.firebaseState.firebaseUser.uid).child("entries")
        ..onChildAdded.listen((event) => store.dispatch(OnAddedAction(event)))
        ..onChildChanged.listen((event) => store.dispatch(OnChangedAction(event)))
        ..onChildRemoved.listen((event) => store.dispatch(OnRemovedAction(event)))));
}

_handleSetUnitAction(SetUnitAction action, Store<ReduxState> store) {
  _setUnit(action.unit).then((nil) => store.dispatch(OnUnitChangedAction(action.unit)));
}

_handleUndoRemovalAction(Store<ReduxState> store) {
  WeightEntry lastRemovedEntry = store.state.removedEntryState.lastRemovedEntry;
  store.state.firebaseState.mainReference.child(lastRemovedEntry.key).set(lastRemovedEntry.toJson());
}

_handleRemoveEntryAction(Store<ReduxState> store, RemoveEntryAction action) {
  store.state.firebaseState.mainReference.child(action.weightEntry.key).remove();
}

_handleEditEntryAction(Store<ReduxState> store, EditEntryAction action) {
  store.state.firebaseState.mainReference.child(action.weightEntry.key).set(action.weightEntry.toJson());
}

_handleAddEntryAction(Store<ReduxState> store, AddEntryAction action) {
  store.state.firebaseState.mainReference.push().set(action.weightEntry.toJson());
}

_handleInitAction(Store<ReduxState> store) {
  _loadUnit().then((unit) => store.dispatch(OnUnitChangedAction(unit)));
  if (store.state.firebaseState.firebaseUser == null) {
    User user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      store.dispatch(UserLoadedAction(user));
    } else {
      _handleSignIn().then((User user) => store.dispatch(UserLoadedAction(user))).catchError((e) {
        print('--- Exiting.  Login Error: $e');
        exit(0);
      });
    }
  }
}

Future<User> _handleSignIn() async {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
    ],
  );
  GoogleSignInAccount googleUser = await _googleSignIn.signIn();
  if (googleUser == null) throw ('User not logged in');
  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
  final AuthCredential credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  final User user = (await _auth.signInWithCredential(credential)).user;
  print("Signed in as " + user.displayName);
  return user;
}

Future _setUnit(String unit) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('unit', unit);
}

Future<String> _loadUnit() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('unit') ?? 'lbs';
}
