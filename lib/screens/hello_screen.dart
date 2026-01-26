import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pansy/screens/ranking_screen.dart';
import 'package:pansy/screens/recommend_screen.dart';
import 'package:pansy/screens/new_search_screen.dart';
import 'package:pansy/screens/settings_screen.dart';
import 'package:pansy/states/pixiv_login.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io';

/// 主界面 - 仿照pixez的底部导航栏设计
class HelloScreen extends StatefulWidget {
  const HelloScreen({Key? key}) : super(key: key);

  @override
  State<HelloScreen> createState() => _HelloScreenState();
}

class _HelloScreenState extends State<HelloScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _pages = [
      const RecommendScreen(), // 推荐
      const RankingScreen(),   // 排行
      const SearchScreen(),    // 搜索
      const SettingsScreen(),  // 设置
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final loggedIn = pixivLoginSignal.value;
      
      if (!loggedIn) {
        return _buildLoginScreen(context);
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > constraints.maxHeight;
          return Scaffold(
            body: Row(
              children: [
                if (isWide) _buildNavigationRail(context),
                Expanded(child: _buildPageView()),
              ],
            ),
            bottomNavigationBar: isWide ? null : _buildBottomNavigationBar(context),
          );
        },
      );
    });
  }

  Widget _buildLoginScreen(BuildContext context) {
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
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Text(
                  AppLocalizations.of(context)!.appName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 40),
                ..._buildLoginButtons(context),
                const Spacer(),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.only(
                top: Platform.isWindows || Platform.isLinux || Platform.isMacOS ? 0 : 40,
                left: 8
              ),
              child: IconButton(
                tooltip: AppLocalizations.of(context)!.settings,
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLoginButtons(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final buttons = <Widget>[];
    void addButton(Widget button) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(height: 12));
      }
      buttons.add(button);
    }

    if (Platform.isAndroid || Platform.isIOS || Platform.isWindows || Platform.isMacOS) {
      addButton(_LoginActionButton(
        label: i18n.loginWithInAppWebView,
        onPressed: () => pixivLoginAction(
          context,
          method: PixivLoginMethod.inAppWebView,
        ),
      ));
    }

    if (Platform.isAndroid || Platform.isIOS) {
      addButton(_LoginActionButton(
        label: i18n.loginWithExternalBrowser,
        onPressed: () => pixivLoginAction(
          context,
          method: PixivLoginMethod.externalBrowser,
        ),
      ));
    }

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      addButton(_LoginActionButton(
        label: i18n.loginWithManualCode,
        onPressed: () => pixivLoginAction(
          context,
          method: PixivLoginMethod.manualCode,
        ),
      ));
    }

    return buttons;
  }

  Widget _buildNavigationRail(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    return NavigationRail(
      selectedIndex: _currentIndex,
      labelType: NavigationRailLabelType.all,
      onDestinationSelected: (index) {
        setState(() {
          _currentIndex = index;
        });
        _pageController.jumpToPage(index);
      },
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.explore_outlined),
          selectedIcon: const Icon(Icons.explore),
          label: Text(i18n.discover),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.leaderboard_outlined),
          selectedIcon: const Icon(Icons.leaderboard),
          label: Text(i18n.ranking),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.search_outlined),
          selectedIcon: const Icon(Icons.search),
          label: Text(i18n.search),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: Text(i18n.settings),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: NavigationBar(
          height: 68,
          backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.9),
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
            _pageController.jumpToPage(index);
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.explore_outlined),
              selectedIcon: const Icon(Icons.explore),
              label: i18n.discover,
            ),
            NavigationDestination(
              icon: const Icon(Icons.leaderboard_outlined),
              selectedIcon: const Icon(Icons.leaderboard),
              label: i18n.ranking,
            ),
            NavigationDestination(
              icon: const Icon(Icons.search_outlined),
              selectedIcon: const Icon(Icons.search),
              label: i18n.search,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: i18n.settings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageView() {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      children: _pages,
    );
  }
}

class _LoginActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _LoginActionButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}
