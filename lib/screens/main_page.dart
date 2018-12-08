import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:weight_tracker/logic/actions.dart';
import 'package:weight_tracker/logic/redux_state.dart';
import 'package:weight_tracker/screens/history_page.dart';
import 'package:weight_tracker/screens/profile_screen.dart';
import 'package:weight_tracker/screens/settings_screen.dart';
import 'package:weight_tracker/screens/statistics_page.dart';
import 'package:weight_tracker/screens/weight_entry_dialog.dart';

class MainPageViewModel {
  final double defaultWeight;
  final bool hasEntryBeenAdded;
  final String unit;
  final Function() openAddEntryDialog;
  final Function() acceptEntryAddedCallback;

  MainPageViewModel({
    this.openAddEntryDialog,
    this.defaultWeight,
    this.hasEntryBeenAdded,
    this.acceptEntryAddedCallback,
    this.unit,
  });
}

class MainPage extends StatefulWidget {
  MainPage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  ScrollController _scrollViewController;
  TabController _tabController;

  @override
  void initState() {
    super.initState();
    _scrollViewController = ScrollController();
    _tabController = TabController(vsync: this, length: 2);
  }

  @override
  void dispose() {
    _scrollViewController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<ReduxState, MainPageViewModel>(
      converter: (store) {
        return MainPageViewModel(
          defaultWeight: store.state.entries.isEmpty ? 60.0 : store.state.entries.first.weight,
          hasEntryBeenAdded: store.state.mainPageState.hasEntryBeenAdded,
          acceptEntryAddedCallback: () => store.dispatch(AcceptEntryAddedAction()),
          openAddEntryDialog: () {
            store.dispatch(OpenAddEntryDialog());
            Navigator.of(context).push(MaterialPageRoute(
              builder: (BuildContext context) {
                return WeightEntryDialog();
              },
              fullscreenDialog: true,
            ));
          },
          unit: store.state.unit,
        );
      },
      onInit: (store) {
        store.dispatch(GetSavedWeightNote());
      },
      builder: (context, viewModel) {
        if (viewModel.hasEntryBeenAdded) {
          _scrollToTop();
          viewModel.acceptEntryAddedCallback();
        }
        return Scaffold(
          body: NestedScrollView(
            controller: _scrollViewController,
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverAppBar(
                  title: Text(widget.title),
                  // pinned: true,
                  floating: true,
                  forceElevated: innerBoxIsScrolled,
                  bottom: TabBar(
                    tabs: <Tab>[
                      Tab(
                        key: Key('StatisticsTab'),
                        text: "STATISTICS",
                        icon: Icon(Icons.show_chart),
                      ),
                      Tab(
                        key: Key('HistoryTab'),
                        text: "HISTORY",
                        icon: Icon(Icons.history),
                      ),
                    ],
                    controller: _tabController,
                  ),
                  actions: _buildMenuActions(context),
                ),
              ];
            },
            body: TabBarView(
              children: <Widget>[
                StatisticsPage(),
                HistoryPage(),
              ],
              controller: _tabController,
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => viewModel.openAddEntryDialog(),
            tooltip: 'Add weight entry',
            child: Icon(Icons.add),
          ),
        );
      },
    );
  }

  List<Widget> _buildMenuActions(BuildContext context) {
    List<Widget> actions = [
      IconButton(icon: Icon(Icons.settings), onPressed: () => _openSettingsPage(context)),
    ];
    bool showProfile = false;
    if (showProfile) {
      actions.add(PopupMenuButton<String>(
        onSelected: (val) {
          if (val == "Profile") {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ProfileScreen(),
            ));
          }
        },
        itemBuilder: (context) {
          return [
            PopupMenuItem<String>(
              value: "Profile",
              child: Text("Profile"),
            ),
          ];
        },
      ));
    }
    return actions;
  }

  _scrollToTop() {
    _scrollViewController.animateTo(
      0.0,
      duration: const Duration(microseconds: 1),
      curve: ElasticInCurve(0.01),
    );
  }

  _openSettingsPage(BuildContext context) async {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (BuildContext context) {
        return SettingsPage();
      },
    ));
  }
}
