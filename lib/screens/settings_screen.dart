import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:meta/meta.dart';
import 'package:weight_tracker/logic/actions.dart';
import 'package:weight_tracker/logic/redux_state.dart';

@immutable
class SettingsPageViewModel {
  final String unit;
  final Function(String) onUnitChanged;

  SettingsPageViewModel({this.unit, this.onUnitChanged});
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StoreConnector<ReduxState, SettingsPageViewModel>(converter: (store) {
      return SettingsPageViewModel(
        unit: store.state.unit,
        onUnitChanged: (newUnit) => store.dispatch(SetUnitAction(newUnit)),
      );
    }, builder: (context, viewModel) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Settings"),
        ),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: <Widget>[
              Expanded(
                  child: Text(
                "Unit",
                style: Theme.of(context).textTheme.headline5,
              )),
              DropdownButton<String>(
                key: const Key('UnitDropdown'),
                value: viewModel.unit,
                items: <String>["lbs", "kg"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newUnit) => viewModel.onUnitChanged(newUnit),
              ),
            ],
          ),
        ),
      );
    });
  }
}
