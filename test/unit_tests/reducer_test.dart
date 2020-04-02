import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weight_tracker/logic/actions.dart';
import 'package:weight_tracker/logic/reducer.dart';
import 'package:weight_tracker/logic/redux_state.dart';
import 'package:weight_tracker/model/weight_entry.dart';

class FirebaseUserMock extends Mock implements FirebaseUser {}

class DatabaseReferenceMock extends Mock implements DatabaseReference {}

class EventMock extends Mock implements Event {}

class DataSnapshotMock extends Mock implements DataSnapshot {
  Map<String, dynamic> _data;

  DataSnapshotMock(WeightEntry weightEntry) {
    _data = {
      "key": weightEntry.key,
      "value": {
        "weight": weightEntry.weight,
        "date": weightEntry.dateTime.millisecondsSinceEpoch,
        "note": weightEntry.note
      }
    };
  }

  String get key => _data['key'];

  dynamic get value => _data['value'];
}

void main() {
  test('reducer UserLoadedAction sets firebase user', () {
    //given
    ReduxState initialState = ReduxState();
    FirebaseUser user = FirebaseUserMock();
    UserLoadedAction action = UserLoadedAction(user);
    //when
    ReduxState newState = reduce(initialState, action);
    //then
    expect(newState.firebaseState.firebaseUser, user);
  });

  test('reducer AddDatabaseReferenceAction sets database reference', () {
    //given
    ReduxState initialState = ReduxState();
    DatabaseReference databaseReference = DatabaseReferenceMock();
    AddDatabaseReferenceAction action = AddDatabaseReferenceAction(databaseReference);
    //when
    ReduxState newState = reduce(initialState, action);
    //then
    expect(newState.firebaseState.mainReference, databaseReference);
  });

  test('reducer AcceptEntryAddedAction sets flag to false', () {
    //given
    ReduxState initialState = ReduxState(mainPageState: MainPageReduxState(hasEntryBeenAdded: true));
    AcceptEntryAddedAction action = AcceptEntryAddedAction();
    //when
    ReduxState newState = reduce(initialState, action);
    //then
    expect(newState.mainPageState.hasEntryBeenAdded, false);
  });

  test('reducer AcceptEntryAddedAction flag false stays false', () {
    //given
    ReduxState initialState = ReduxState();
    AcceptEntryAddedAction action = AcceptEntryAddedAction();
    //when
    ReduxState newState = reduce(initialState, action);
    //then
    expect(newState.mainPageState.hasEntryBeenAdded, false);
  });

  test('reducer AcceptEntryRemovalAction sets flag to false', () {
    //given
    ReduxState initialState = ReduxState(removedEntryState: RemovedEntryState(hasEntryBeenRemoved: true));
    expect(initialState.removedEntryState.hasEntryBeenRemoved, true);
    AcceptEntryRemovalAction action = AcceptEntryRemovalAction();
    //when
    ReduxState newState = reduce(initialState, action);
    //then
    expect(newState.removedEntryState.hasEntryBeenRemoved, false);
  });

  test('reducer AcceptEntryRemovalAction flag false stays false', () {
    //given
    ReduxState initialState = ReduxState();
    AcceptEntryRemovalAction action = AcceptEntryRemovalAction();
    //when
    ReduxState newState = reduce(initialState, action);
    //then
    expect(newState.removedEntryState.hasEntryBeenRemoved, false);
  });

  test('reducer OnUnitChangedAction changes unit', () {
    //given
    ReduxState initialState = ReduxState(unit: 'initialUnit');
    OnUnitChangedAction action = OnUnitChangedAction("newUnit");
    //when
    ReduxState newState = reduce(initialState, action);
    //then
    expect(newState.unit, 'newUnit');
  });

  test('reducer UpdateActiveWeightEntry changes entry', () {
    //given
    ReduxState initialState = ReduxState();
    WeightEntry updatedEntry = WeightEntry(DateTime.now(), 60.0, "text", null);
    UpdateActiveWeightEntry action = UpdateActiveWeightEntry(updatedEntry);
    //when
    ReduxState newState = reduce(initialState, action);
    //then
    expect(newState.weightEntryDialogState.activeEntry, updatedEntry);
  });

  test('reducer OpenEditEntryDialog changes entry', () {
    //given
    ReduxState initialState = ReduxState();
    WeightEntry updatedEntry = WeightEntry(DateTime.now(), 60.0, "text", null);
    OpenEditEntryDialog action = OpenEditEntryDialog(updatedEntry);
    //when
    ReduxState newState = reduce(initialState, action);
    //then
    expect(newState.weightEntryDialogState.activeEntry, updatedEntry);
  });

  test('reducer OpenEditEntryDialog sets EditMode to true', () {
    //given
    ReduxState initialState = ReduxState();
    WeightEntry updatedEntry = WeightEntry(DateTime.now(), 60.0, "text", null);
    OpenEditEntryDialog action = OpenEditEntryDialog(updatedEntry);
    //when
    ReduxState newState = reduce(initialState, action);
    //then
    expect(newState.weightEntryDialogState.isEditMode, true);
  });

  test('reducer OpenAddEntryDialog sets EditMode to false', () {
    //given
    ReduxState initialState = ReduxState(weightEntryDialogState: WeightEntryDialogReduxState(isEditMode: true));
    OpenAddEntryDialog action = OpenAddEntryDialog();
    //when
    ReduxState newState = reduce(initialState, action);
    //then
    expect(newState.weightEntryDialogState.isEditMode, false);
  });

  test('reducer OpenAddEntryDialog creates entry with weight 160', () {
    //given
    ReduxState initialState = ReduxState();
    OpenAddEntryDialog action = OpenAddEntryDialog();
    //when
    ReduxState newState = reduce(initialState, action);
    //then
    expect(newState.weightEntryDialogState.activeEntry?.weight, 160);
  });

  test('reducer OpenAddEntryDialog creates entry with copied weight from first entry', () {
    //given
    ReduxState initialState = ReduxState(entries: [WeightEntry(DateTime.now(), 60.0, "Text", null)]);
    OpenAddEntryDialog action = OpenAddEntryDialog();
    //when
    ReduxState newState = reduce(initialState, action);
    //then
    expect(newState.weightEntryDialogState.activeEntry?.weight, 60);
    expect(newState.weightEntryDialogState.activeEntry?.note, null);
  });

  test('reducer OnAddedAction adds entry to list', () {
    //given
    WeightEntry entry = createEntry("key", DateTime.now(), 60.0, null);
    ReduxState initialState = ReduxState();
    OnAddedAction action = OnAddedAction(createEventMock(entry));
    //when
    ReduxState newState = reduce(initialState, action);
    //then
    expect(newState.entries, contains(entry));
  });

  test('reducer OnAddedAction sets hasEntryBeenAdded to true', () {
    //given
    WeightEntry entry = createEntry("key", DateTime.now(), 60.0, null);
    ReduxState initialState = ReduxState();
    OnAddedAction action = OnAddedAction(createEventMock(entry));
    //when
    ReduxState newState = reduce(initialState, action);
    //then
    expect(newState.mainPageState.hasEntryBeenAdded, true);
  });

  test('reducer OnRemovedAction sets hasEntryBeenRemoved to true', () {
    //given
    WeightEntry entry = createEntry("key", DateTime.now(), 60.0, null);
    ReduxState initialState = ReduxState(entries: [entry]);
    OnRemovedAction action = OnRemovedAction(createEventMock(entry));
    //when
    ReduxState newState = reduce(initialState, action);
    //then
    expect(newState.removedEntryState.hasEntryBeenRemoved, true);
  });

  test('reducer OnRemovedAction removes entry from list', () {
    //given
    WeightEntry entry = createEntry("key", DateTime.now(), 60.0, null);
    ReduxState initialState = ReduxState(entries: [entry]);
    OnRemovedAction action = OnRemovedAction(createEventMock(entry));
    //when
    ReduxState newState = reduce(initialState, action);
    //then
    expect(newState.entries, isEmpty);
  });

  test('reducer OnRemovedAction sets lastRemovedEntry', () {
    //given
    WeightEntry entry = createEntry("key", DateTime.now(), 60.0, null);
    ReduxState initialState = ReduxState(entries: [entry]);
    OnRemovedAction action = OnRemovedAction(createEventMock(entry));
    //when
    ReduxState newState = reduce(initialState, action);
    //then
    expect(newState.removedEntryState.lastRemovedEntry, entry);
  });

  test("ChangeDaysToShowOnChart changes daysToShow", () {
    //given
    int newValue = 10;
    ReduxState initialState = ReduxState();
    expect(initialState.progressChartState.daysToShow, isNot(newValue));
    ChangeDaysToShowOnChart action = ChangeDaysToShowOnChart(newValue);
    //when
    ReduxState newState = reduce(initialState, action);
    //then
    expect(newState.progressChartState.daysToShow, newValue);
  });

  test("SnapShotDaysToShow copies daysToShow to previousDaysToShow", () {
    //given
    ReduxState initialState =
        ReduxState(progressChartState: ProgressChartState(daysToShow: 10, previousDaysToShow: 20));
    SnapShotDaysToShow action = SnapShotDaysToShow();
    //when
    ReduxState newState = reduce(initialState, action);
    //then
    expect(newState.progressChartState.previousDaysToShow, 10);
  });

  test("EndGestureOnProgressChart updates lastFinishedDateTime", () {
    //given
    ReduxState initialState = ReduxState();
    expect(initialState.progressChartState.lastFinishedDateTime, isNull);
    EndGestureOnProgressChart action = EndGestureOnProgressChart();
    //when
    ReduxState newState = reduce(initialState, action);
    //then
    expect(newState.progressChartState.lastFinishedDateTime, isNotNull);
  });

  test("ChangeDaysToShow after endGesture doesnt change daysToShow", () {
    //given
    ReduxState initialState = ReduxState(progressChartState: ProgressChartState(daysToShow: 31));
    EndGestureOnProgressChart endAction = EndGestureOnProgressChart();
    SnapShotDaysToShow startAction = SnapShotDaysToShow();
    ChangeDaysToShowOnChart updateAction = ChangeDaysToShowOnChart(10);
    //when
    ReduxState state1 = reduce(initialState, endAction);
    ReduxState state2 = reduce(state1, startAction);
    ReduxState state3 = reduce(state2, updateAction);
    //then
    expect(state3.progressChartState.daysToShow, 31);
  });

  test("ChangeDaysToShow after 10ms after endGesture changes daysToShow", () {
    //given
    ReduxState initialState = ReduxState(progressChartState: ProgressChartState(daysToShow: 31));
    EndGestureOnProgressChart endAction = EndGestureOnProgressChart();
    SnapShotDaysToShow startAction = SnapShotDaysToShow();
    ChangeDaysToShowOnChart updateAction = ChangeDaysToShowOnChart(10);
    //when
    ReduxState state1 = reduce(initialState, endAction);
    ReduxState state2 = reduce(state1, startAction);
    sleep(const Duration(milliseconds: 10));
    ReduxState state3 = reduce(state2, updateAction);
    //then
    expect(state3.progressChartState.daysToShow, 10);
  });
}

WeightEntry createEntry(String key, DateTime dateTime, double weight, String note) {
  WeightEntry entry = WeightEntry(dateTime, weight, note, null);
  entry.key = key;
  return entry;
}

Event createEventMock(WeightEntry weightEntry) {
  EventMock eventMock = EventMock();
  DataSnapshotMock snapshotMock = DataSnapshotMock(weightEntry);
  when(eventMock.snapshot).thenReturn(snapshotMock);
  return eventMock;
}
