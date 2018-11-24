import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:weight_tracker/logic/actions.dart';
import 'package:weight_tracker/logic/constants.dart';
import 'package:weight_tracker/logic/redux_state.dart';
import 'package:weight_tracker/model/weight_entry.dart';
import '../util/decimal_number_text_input_formatter.dart';

class DialogViewModel {
  final WeightEntry weightEntry;
  final String unit;
  final bool isEditMode;
  final double weightToDisplay;
  final double percentFatToDisplay;
  final Function(WeightEntry) onEntryChanged;
  final Function() onDeletePressed;
  final Function() onSavePressed;

  DialogViewModel({
    this.weightEntry,
    this.unit,
    this.isEditMode,
    this.weightToDisplay,
    this.percentFatToDisplay,
    this.onEntryChanged,
    this.onDeletePressed,
    this.onSavePressed,
  });
}

class WeightEntryDialog extends StatefulWidget {
  @override
  State<WeightEntryDialog> createState() {
    return new WeightEntryDialogState();
  }
}

class WeightEntryDialogState extends State<WeightEntryDialog> {
  bool wasBuiltOnce = false;
  final _weightController = TextEditingController();
  final _fatController = TextEditingController();
  final _noteController = TextEditingController();
  final _weightFocusNode = FocusNode();
  final _fatFocusNode = FocusNode();
  final _keyboardType = TextInputType.numberWithOptions(decimal: true);
  final _decimalFormatter = DecimalNumberTextInputFormatter(decimalPlaces: 1);

  @override
  void initState() {
    super.initState();
    _weightFocusNode.addListener(() {
      int _baseOffset = _weightController.text.length > 3 ? _weightController.text.length - 3 : 0;
      if (_weightFocusNode.hasFocus) {
        Timer(const Duration(milliseconds: 1200), () =>  // This is a hack to get the prehighlighting to work
          _weightController.selection = TextSelection(
            baseOffset: _baseOffset,
            extentOffset: _weightController.text.length,
          )
        );
      }
    });
    _fatFocusNode.addListener(() {
      int _baseOffset = _fatController.text.length > 3 ? _fatController.text.length - 3 : 0;
      if (_fatFocusNode.hasFocus) {
        Timer(const Duration(milliseconds: 400), () =>  // This is a hack to get the prehighlighting to work
          _fatController.selection = TextSelection(
            baseOffset: _baseOffset,
            extentOffset: _fatController.text.length,
          )
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return new StoreConnector<ReduxState, DialogViewModel>(
      converter: (store) {
        WeightEntry activeEntry = store.state.weightEntryDialogState.activeEntry;
        return new DialogViewModel(
            weightEntry: activeEntry,
            unit: store.state.unit,
            isEditMode: store.state.weightEntryDialogState.isEditMode,
            weightToDisplay: store.state.unit == "lbs"
                ? activeEntry.weight
                : double.parse((activeEntry.weight * LB_KG_RATIO).toStringAsFixed(1)),
            percentFatToDisplay: activeEntry.percentBodyFat == null ? 24.3 : activeEntry.percentBodyFat,
            onEntryChanged: (entry) => store.dispatch(new UpdateActiveWeightEntry(entry)),
            onDeletePressed: () {
              store.dispatch(new RemoveEntryAction(activeEntry));
              Navigator.of(context).pop();
            },
            onSavePressed: () {
              if (store.state.weightEntryDialogState.isEditMode) {
                store.dispatch(new EditEntryAction(activeEntry));
              } else {
                store.dispatch(new AddEntryAction(activeEntry));
              }
              Navigator.of(context).pop();
            });
      },
      builder: (context, viewModel) {
        if (!wasBuiltOnce) {
          wasBuiltOnce = true;
          _noteController.text = viewModel.weightEntry.note;
        }
        return new Scaffold(
          appBar: _createAppBar(context, viewModel),
          body: new Column(
            children: [
              new ListTile(
                leading: new Icon(Icons.today, color: Colors.grey[500]),
                title: new DateTimeItem(
                  dateTime: viewModel.weightEntry.dateTime,
                  onChanged: (dateTime) => viewModel.onEntryChanged(viewModel.weightEntry..dateTime = dateTime),
                ),
              ),
              new ListTile(
                leading: Text('Weight in ${viewModel.unit}'),
                title: weightTextFormField(
                  viewModel.weightToDisplay.toStringAsFixed(1),
                ),
              ),
              new ListTile(
                leading: Text('% Body Fat'),
                title: fatTextFormField(
                  viewModel.percentFatToDisplay.toStringAsFixed(1),
                ),
              ),
              new ListTile(
                leading: new Icon(Icons.speaker_notes, color: Colors.grey[500]),
                title: new TextField(
                    decoration: new InputDecoration(
                      hintText: 'Optional note',
                    ),
                    controller: _noteController,
                    onChanged: (value) {
                      viewModel.onEntryChanged(viewModel.weightEntry..note = value);
                    },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget weightTextFormField(String _value) {
    _weightController.text = _value;
    return TextFormField(
      autofocus: false,  // If this is set to true, the preselected text doesn't work
      focusNode: _weightFocusNode,
      controller: _weightController,
      keyboardType: _keyboardType,
      inputFormatters: [
        _decimalFormatter,
      ],
      // textInputAction: TextInputAction.next,
    );
  }

  Widget fatTextFormField(String _value) {
    _fatController.text = _value;
    return TextFormField(
      autofocus: false,
      focusNode: _fatFocusNode,
      controller: _fatController,
      keyboardType: _keyboardType,
      inputFormatters: [
        _decimalFormatter,
      ],
      // textInputAction: TextInputAction.next,
    );
  }

  @override
  void dispose() {
    // Clean up the controller when the Widget is disposed
    _weightController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Widget _createAppBar(BuildContext context, DialogViewModel viewModel) {
    TextStyle actionStyle = Theme.of(context).textTheme.subhead.copyWith(color: Colors.white);
    Text title = viewModel.isEditMode ? const Text("Edit entry") : const Text("New entry");
    List<Widget> actions = [];
    if (viewModel.isEditMode) {
      actions.add(
        new FlatButton(
          onPressed: viewModel.onDeletePressed,
          child: new Text(
            'DELETE',
            style: actionStyle,
          ),
        ),
      );
    }
    actions.add(new FlatButton(
      onPressed: viewModel.onSavePressed,
      child: new Text(
        'SAVE',
        style: actionStyle,
      ),
    ));

    return new AppBar(
      title: title,
      actions: actions,
    );
  }
}

class DateTimeItem extends StatelessWidget {
  DateTimeItem({Key key, DateTime dateTime, @required this.onChanged})
      : assert(onChanged != null),
        date = dateTime == null ? new DateTime.now() : new DateTime(dateTime.year, dateTime.month, dateTime.day),
        time = dateTime == null ? new DateTime.now() : new TimeOfDay(hour: dateTime.hour, minute: dateTime.minute),
        super(key: key);

  final DateTime date;
  final TimeOfDay time;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return new Row(
      children: <Widget>[
        new Expanded(
          child: new InkWell(
            key: new Key('CalendarItem'),
            onTap: (() => _showDatePicker(context)),
            child: new Padding(
              padding: new EdgeInsets.symmetric(vertical: 8.0),
              child: new Text(new DateFormat('EEEE, MMMM d').format(date)),
            ),
          ),
        ),
        new InkWell(
          key: new Key('TimeItem'),
          onTap: (() => _showTimePicker(context)),
          child: new Padding(
            padding: new EdgeInsets.symmetric(vertical: 8.0),
            child: new Text(time.format(context)),
          ),
        ),
      ],
    );
  }

  Future _showDatePicker(BuildContext context) async {
    DateTime dateTimePicked = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: date.subtract(const Duration(days: 365)),
        lastDate: new DateTime.now());

    if (dateTimePicked != null) {
      onChanged(new DateTime(dateTimePicked.year, dateTimePicked.month, dateTimePicked.day, time.hour, time.minute));
    }
  }

  Future _showTimePicker(BuildContext context) async {
    TimeOfDay timeOfDay = await showTimePicker(context: context, initialTime: time);

    if (timeOfDay != null) {
      onChanged(new DateTime(date.year, date.month, date.day, timeOfDay.hour, timeOfDay.minute));
    }
  }
}
