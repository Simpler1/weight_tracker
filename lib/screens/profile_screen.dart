import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:weight_tracker/logic/redux_state.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StoreConnector<ReduxState, _ViewModel>(
      converter: (store) {
        return _ViewModel(
          user: store.state.firebaseState.firebaseUser,
        );
      },
      builder: (BuildContext context, _ViewModel vm) {
        return Scaffold(
          appBar: AppBar(
            title: Text("Profile"),
          ),
          body: SingleChildScrollView(
            child: Center(
              child: Column(
                children: <Widget>[
                  _getUserIcon(vm),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _getUserIcon(_ViewModel vm) {
    if (vm.user.isAnonymous) {
      return CircleAvatar(
        backgroundImage: AssetImage("assets/user_icon.png"),
        radius: 36.0,
      );
    } else {
      return CircleAvatar(
        backgroundImage: NetworkImage(vm.user.photoUrl),
        radius: 36.0,
      );
    }
  }
}

class _ViewModel {
  final FirebaseUser user;

  _ViewModel({@required this.user});
}
