import 'package:test_api/test_api.dart';
import 'package:weight_tracker/model/weight_entry.dart';
import 'package:weight_tracker/widgets/progress_chart_utils.dart' as utils;

void main() {
  test('general filtring list test', () {
    //given
    DateTime now = DateTime.utc(2017, 1, 1, 8, 0);
    WeightEntry entry1 = WeightEntry(now, 160.0, null, null);
    WeightEntry entry2 = WeightEntry(now.subtract(Duration(days: 6)), 160.0, null, null);
    WeightEntry entry3 = WeightEntry(now.subtract(Duration(days: 7)), 160.0, null, null);
    WeightEntry entry4 = WeightEntry(now.subtract(Duration(days: 8)), 160.0, null, null);
    int daysToShow = 7;
    List<WeightEntry> entries = [entry1, entry2, entry3, entry4];
    //when
    List<WeightEntry> newEntries = utils.prepareEntryList(entries, now, daysToShow);
    //then
    expect(newEntries, contains(entry1));
    expect(newEntries, contains(entry2));
    expect(newEntries, isNot(contains(entry3)));
    expect(newEntries, isNot(contains(entry4)));
  });

  test('adds fake weight entry', () {
    //given
    int daysToShow = 2;
    DateTime now = DateTime.utc(2017, 10, 10, 8, 0);
    WeightEntry firstEntryAfterBorder = WeightEntry(now, 160.0, null, null);
    WeightEntry lastEntryBeforeBorder = WeightEntry(now.subtract(Duration(days: 2)), 180.0, null, null);
    List<WeightEntry> entries = [firstEntryAfterBorder, lastEntryBeforeBorder];
    //when
    List<WeightEntry> newEntries = utils.prepareEntryList(entries, now, daysToShow);
    //then
    expect(newEntries, contains(firstEntryAfterBorder));
    expect(newEntries, isNot(contains(lastEntryBeforeBorder)));
    expect(newEntries, anyElement((WeightEntry entry) => entry.weight == 170.0 && entry.dateTime.day == now.day - 1));
  });
}
