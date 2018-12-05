import 'package:firebase_database/firebase_database.dart';
import 'package:weight_tracker/logic/actions.dart';
import 'package:weight_tracker/logic/redux_state.dart';
import 'package:weight_tracker/model/weight_entry.dart';

ReduxState reduce(ReduxState state, action) {
  List<WeightEntry> entries = _reduceEntries(state, action);
  String unit = _reduceUnit(state, action);
  RemovedEntryState removedEntryState = _reduceRemovedEntryState(state, action);
  WeightEntryDialogReduxState weightEntryDialogState = _reduceWeightEntryDialogState(state, action);
  FirebaseState firebaseState = _reduceFirebaseState(state, action);
  MainPageReduxState mainPageState = _reduceMainPageState(state, action);
  ProgressChartState progressChartState = _reduceChartState(state, action);
  double weightFromNotes = _reduceWeightFromNotes(state, action);

  return ReduxState(
    entries: entries,
    unit: unit,
    removedEntryState: removedEntryState,
    weightEntryDialogState: weightEntryDialogState,
    firebaseState: firebaseState,
    mainPageState: mainPageState,
    progressChartState: progressChartState,
    weightFromNotes: weightFromNotes,
  );
}

double _reduceWeightFromNotes(ReduxState state, action) {
  double weight = state.weightFromNotes;

  if (action is AddWeightFromNotes) {
    return action.weight;
  }
  if (action is ConsumeWeightFromNotes) {
    return null;
  }
  return weight;
}

String _reduceUnit(ReduxState reduxState, action) {
  String unit = reduxState.unit;

  if (action is OnUnitChangedAction) {
    return action.unit;
  }
  return unit;
}

MainPageReduxState _reduceMainPageState(ReduxState reduxState, action) {
  MainPageReduxState newMainPageState = reduxState.mainPageState;

  if (action is AcceptEntryAddedAction) {
    return newMainPageState.copyWith(hasEntryBeenAdded: false);
  }
  if (action is OnAddedAction) {
    return newMainPageState.copyWith(hasEntryBeenAdded: true);
  }
  return newMainPageState;
}

FirebaseState _reduceFirebaseState(ReduxState reduxState, action) {
  FirebaseState newState = reduxState.firebaseState;

  if (action is InitAction) {
    FirebaseDatabase.instance.setPersistenceEnabled(true);
  }
  if (action is UserLoadedAction) {
    return newState.copyWith(firebaseUser: action.firebaseUser);
  }
  if (action is AddDatabaseReferenceAction) {
    return newState.copyWith(mainReference: action.databaseReference);
  }
  return newState;
}

RemovedEntryState _reduceRemovedEntryState(ReduxState reduxState, action) {
  RemovedEntryState newState = reduxState.removedEntryState;

  if (action is AcceptEntryRemovalAction) {
    return newState.copyWith(hasEntryBeenRemoved: false);
  }
  if (action is OnRemovedAction) {
    return newState.copyWith(
        hasEntryBeenRemoved: true, lastRemovedEntry: WeightEntry.fromSnapshot(action.event.snapshot));
  }
  return newState;
}

WeightEntryDialogReduxState _reduceWeightEntryDialogState(ReduxState reduxState, action) {
  WeightEntryDialogReduxState newState = reduxState.weightEntryDialogState;

  if (action is UpdateActiveWeightEntry) {
    return newState.copyWith(activeEntry: WeightEntry.copy(action.weightEntry));
  }
  if (action is OpenAddEntryDialog) {
    return newState.copyWith(
        activeEntry: WeightEntry(
          DateTime.now(),
          reduxState.entries.isEmpty ? 160.0 : reduxState.entries.first.weight,
          null,
          reduxState.entries.isEmpty ? 20.0 : reduxState.entries.first.percentBodyFat,
        ),
        isEditMode: false);
  }
  if (action is OpenEditEntryDialog) {
    return newState.copyWith(activeEntry: action.weightEntry, isEditMode: true);
  }
  return newState;
}

List<WeightEntry> _reduceEntries(ReduxState state, action) {
  List<WeightEntry> entries = List.from(state.entries);

  if (action is OnAddedAction) {
    entries
      ..add(WeightEntry.fromSnapshot(action.event.snapshot))
      ..sort((we1, we2) => we2.dateTime.compareTo(we1.dateTime));
  } else if (action is OnChangedAction) {
    WeightEntry newValue = WeightEntry.fromSnapshot(action.event.snapshot);
    WeightEntry oldValue = entries.singleWhere((entry) => entry.key == newValue.key);
    entries
      ..[entries.indexOf(oldValue)] = newValue
      ..sort((we1, we2) => we2.dateTime.compareTo(we1.dateTime));
  } else if (action is OnRemovedAction) {
    WeightEntry removedEntry = state.entries.singleWhere((entry) => entry.key == action.event.snapshot.key);
    entries
      ..remove(removedEntry)
      ..sort((we1, we2) => we2.dateTime.compareTo(we1.dateTime));
  }
  return entries;
}

/// I don't check if values have sense (e.g. if they are greater than 0) - let it be ;)
ProgressChartState _reduceChartState(ReduxState state, action) {
  ProgressChartState newState = state.progressChartState;

  if (action is ChangeDaysToShowOnChart) {
    if (newState.lastFinishedDateTime == null ||
        newState.lastFinishedDateTime.isBefore(DateTime.now().subtract(const Duration(milliseconds: 10)))) {
      return newState.copyWith(daysToShow: action.daysToShow);
    }
  }
  if (action is SnapShotDaysToShow) {
    return newState.copyWith(previousDaysToShow: newState.daysToShow);
  }
  if (action is EndGestureOnProgressChart) {
    return newState.copyWith(previousDaysToShow: newState.daysToShow, lastFinishedDateTime: DateTime.now());
  }
  return newState;
}
