import 'package:flutter/material.dart';
import 'package:pansy/basic/app_screen_data.dart';
import 'package:pansy/screens/search_title_screen.dart';
import 'package:pansy/screens/discovery_screen.dart';
import 'package:pansy/screens/hots_screen.dart';
import 'package:pansy/screens/settings_screen.dart';
import 'package:pansy/states/pixiv_login.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AppScreen extends StatefulWidget {
  const AppScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _pageViewController.dispose();
    super.dispose();
  }

  late final _screens = [
    AppScreenData(
      const SearchTitleScreen(),
      AppLocalizations.of(context)!.search,
      Icons.widgets_outlined,
      Icons.widgets,
    ),
    AppScreenData(
      const DiscoveryScreen(),
      AppLocalizations.of(context)!.discovery,
      Icons.web_outlined,
      Icons.web,
    ),
    AppScreenData(
      const HotsScreen(),
      AppLocalizations.of(context)!.hots,
      Icons.local_fire_department_outlined,
      Icons.local_fire_department_rounded,
    ),
  ];

  var _selectedIndex = 1;
  final _pageViewController = PageController(initialPage: 1);

  Future _onPage(int index) async {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onItemTapped(int index) {
    _pageViewController.animateToPage(
      index,
      duration: const Duration(milliseconds: 1),
      curve: Curves.ease,
    );
  }

  late final _pageView = PageView(
    children: _screens.map((e) => e.screen).toList(),
    controller: _pageViewController,
    onPageChanged: _onPage,
  );

  Widget _actionButton(AppScreenData data) {
    var active = _screens[_selectedIndex] == data;
    var icon = active ? data.activeIcon : data.icon;
    Color color = Colors.black.withAlpha(active ? 255 : 180);
    return Column(
      children: [
        Expanded(child: Container()),
        MaterialButton(
          minWidth: 50,
          textColor: color,
          onPressed: () {
            _onItemTapped(_screens.indexOf(data));
          },
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
              ),
              Text(
                data.title,
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
        Expanded(child: Container()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Watch((context) {
      final loggedIn = pixivLoginSignal.value;
      if (!loggedIn) {
        return Scaffold(
          body: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Image.asset(
                  'lib/assets/startup_bg.png',
                  fit: BoxFit.contain,
                ),
              ),
              Column(
                children: [
                  Expanded(child: Container()),
                  Container(height: 30),
                  Container(height: 30),
                  MaterialButton(
                    color: Colors.grey.shade50,
                    onPressed: () async {
                      pixivLoginAction(context);
                    },
                    child: Text(AppLocalizations.of(context)!.login),
                  ),
                  Container(height: 30),
                  Expanded(child: Container()),
                ],
              ),
            ],
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(
          elevation: 1,
          title: _leading(),
          actions: _screens.map(_actionButton).toList(),
        ),
        body: _pageView,
      );
    });
  }

  Widget _leading() {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.menu),
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem(
            value: 1,
            child: Row(
              children: [
                Icon(Icons.settings, color: Colors.grey.shade600),
                Container(width: 10),
                Text(AppLocalizations.of(context)!.settings),
              ],
            ),
          ),
        ];
      },
      onSelected: (value) {
        if (value == 1) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const SettingsScreen(),
          ));
        }
      },
    );
  }
}
