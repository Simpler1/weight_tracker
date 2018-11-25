import 'dart:async';

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
    return WeightEntryDialogState();
  }
}

class WeightEntryDialogState extends State<WeightEntryDialog> {
  bool wasBuiltOnce = false;
  final _weightController = TextEditingController();
  final _fatController = TextEditingController();
  final _noteController = TextEditingController();
  final _weightFocusNode = FocusNode();
  final _fatFocusNode = FocusNode();
  final _decimalFormatter = DecimalNumberTextInputFormatter(decimalPlaces: 1);

  @override
  void initState() {
    super.initState();
    _weightFocusNode.addListener(() {
      int _baseOffset = _weightController.text.length > 3 ? _weightController.text.length - 3 : 0;
      if (_weightFocusNode.hasFocus) {
        Timer(
            const Duration(milliseconds: 1200),
            () => // This is a hack to get the prehighlighting to work
                _weightController.selection = TextSelection(
                  baseOffset: _baseOffset,
                  extentOffset: _weightController.text.length,
                ));
      }
    });
    _fatFocusNode.addListener(() {
      int _baseOffset = _fatController.text.length > 3 ? _fatController.text.length - 3 : 0;
      if (_fatFocusNode.hasFocus) {
        Timer(
            const Duration(milliseconds: 400),
            () => // This is a hack to get the prehighlighting to work
                _fatController.selection = TextSelection(
                  baseOffset: _baseOffset,
                  extentOffset: _fatController.text.length,
                ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<ReduxState, DialogViewModel>(
      converter: (store) {
        WeightEntry activeEntry = store.state.weightEntryDialogState.activeEntry;
        return DialogViewModel(
            weightEntry: activeEntry,
            unit: store.state.unit,
            isEditMode: store.state.weightEntryDialogState.isEditMode,
            weightToDisplay: store.state.unit == "lbs"
                ? activeEntry.weight
                : double.parse((activeEntry.weight * LB_KG_RATIO).toStringAsFixed(1)),
            percentFatToDisplay: activeEntry.percentBodyFat == null ? 24.3 : activeEntry.percentBodyFat,
            onEntryChanged: (entry) => store.dispatch(UpdateActiveWeightEntry(entry)),
            onDeletePressed: () {
              store.dispatch(RemoveEntryAction(activeEntry));
              Navigator.of(context).pop();
            },
            onSavePressed: () {
              store.dispatch(UpdateActiveWeightEntry(
                  activeEntry..weight = double.tryParse(_weightController.text.replaceAll(',', ''))));
              store.dispatch(UpdateActiveWeightEntry(
                  activeEntry..percentBodyFat = double.tryParse(_fatController.text.replaceAll(',', ''))));

              if (store.state.weightEntryDialogState.isEditMode) {
                store.dispatch(EditEntryAction(activeEntry));
              } else {
                store.dispatch(AddEntryAction(activeEntry));
              }
              Navigator.of(context).pop();
            });
      },
      builder: (context, viewModel) {
        if (!wasBuiltOnce) {
          wasBuiltOnce = true;
          _noteController.text = viewModel.weightEntry.note;
        }
        return Scaffold(
          appBar: _createAppBar(context, viewModel),
          body: Column(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.today, color: Colors.grey[500]),
                title: DateTimeItem(
                  dateTime: viewModel.weightEntry.dateTime,
                  onChanged: (dateTime) => viewModel.onEntryChanged(viewModel.weightEntry..dateTime = dateTime),
                ),
              ),
              weightTextFormField(
                viewModel.weightToDisplay,
                viewModel,
              ),
              fatTextFormField(
                viewModel.percentFatToDisplay,
                viewModel,
              ),
              TextField(
                decoration: InputDecoration(
                  border: UnderlineInputBorder(),
                  filled: true,
                  icon: Icon(Icons.speaker_notes, color: Colors.grey[500]),
                  labelText: 'Note',
                  hintText: 'Did anything special happen yesterday?',
                ),
                controller: _noteController,
                onChanged: (value) {
                  viewModel.onEntryChanged(viewModel.weightEntry..note = value);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget weightTextFormField(double _value, DialogViewModel viewModel) {
    _weightController.text = _value.toStringAsFixed(1);
    return TextFormField(
      autofocus: false, // If this is set to true, the preselected text doesn't work
      focusNode: _weightFocusNode,
      controller: _weightController,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        _decimalFormatter,
      ],
      decoration: InputDecoration(
        suffixText: ' ' + viewModel.unit,
        icon: Icon(Icons.dialpad, color: Colors.grey[500]),
        border: UnderlineInputBorder(),
        filled: true,
        hintText: 'What is your weight today?',
        labelText: 'Weight',
      ),
      onFieldSubmitted: (String value) {
        print('Weight onFieldSubmitted ...');
        FocusScope.of(context).requestFocus(_fatFocusNode);
      },
      // onEditingComplete: () {
      //   print('Weight onEditingComplete ...');
      //   viewModel.weightEntry..weight = double.tryParse(_weightController.text);
      // },
      textInputAction: TextInputAction.next,
    );
  }

  Widget fatTextFormField(double _value, DialogViewModel viewModel) {
    _fatController.text = _value.toStringAsFixed(1);
    return TextFormField(
      autofocus: false,
      focusNode: _fatFocusNode,
      controller: _fatController,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        _decimalFormatter,
      ],
      decoration: InputDecoration(
        suffixText: ' %',
        icon: Icon(Icons.pin_drop, color: Colors.grey[500]),
        border: UnderlineInputBorder(),
        filled: true,
        hintText: 'What is your percent body fat today?',
        labelText: '% Body Fat',
      ),
      onFieldSubmitted: (String value) {
        print('Fat onFieldSubmitted ...');
        viewModel.onSavePressed();
      },
      // onEditingComplete: () {
      //   print('Fat onEditingComplete ...');
      //   viewModel.weightEntry..percentBodyFat = double.tryParse(_fatController.text);
      // },
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
        FlatButton(
          onPressed: viewModel.onDeletePressed,
          child: Text(
            'DELETE',
            style: actionStyle,
          ),
        ),
      );
    }
    actions.add(FlatButton(
      onPressed: viewModel.onSavePressed,
      child: Text(
        'SAVE',
        style: actionStyle,
      ),
    ));

    return AppBar(
      title: title,
      actions: actions,
    );
  }
}

class DateTimeItem extends StatelessWidget {
  DateTimeItem({Key key, DateTime dateTime, @required this.onChanged})
      : assert(onChanged != null),
        date = dateTime == null ? DateTime.now() : DateTime(dateTime.year, dateTime.month, dateTime.day),
        time = dateTime == null ? DateTime.now() : TimeOfDay(hour: dateTime.hour, minute: dateTime.minute),
        super(key: key);

  final DateTime date;
  final TimeOfDay time;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: InkWell(
            key: Key('CalendarItem'),
            onTap: (() => _showDatePicker(context)),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(DateFormat('EEEE, MMMM d').format(date)),
            ),
          ),
        ),
        InkWell(
          key: Key('TimeItem'),
          onTap: (() => _showTimePicker(context)),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(time.format(context)),
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
        lastDate: DateTime.now());

    if (dateTimePicked != null) {
      onChanged(DateTime(dateTimePicked.year, dateTimePicked.month, dateTimePicked.day, time.hour, time.minute));
    }
  }

  Future _showTimePicker(BuildContext context) async {
    TimeOfDay timeOfDay = await showTimePicker(context: context, initialTime: time);

    if (timeOfDay != null) {
      onChanged(DateTime(date.year, date.month, date.day, timeOfDay.hour, timeOfDay.minute));
    }
  }
}
