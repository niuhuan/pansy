import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pansy/screens/login_screen.dart';
import 'package:pansy/states/pixiv_login.dart';
import 'dart:io' as io;
import '../src/rust/pixirust/entities.dart';

class InAppWebViewLoginScreen extends StatefulWidget {
  final LoginUrl loginUrl;

  const InAppWebViewLoginScreen({Key? key, required this.loginUrl})
      : super(key: key);

  @override
  State<InAppWebViewLoginScreen> createState() =>
      _InAppWebViewLoginScreenState();
}

class _InAppWebViewLoginScreenState extends State<InAppWebViewLoginScreen> {
  PullToRefreshController? _refreshController;
  bool _handledCode = false;

  @override
  void initState() {
    super.initState();
    if (io.Platform.isAndroid || io.Platform.isIOS) {
      _refreshController = PullToRefreshController(
        settings: PullToRefreshSettings(),
        onRefresh: () async {
          await _controller?.reload();
        },
      );
    }
  }

  InAppWebViewController? _controller;

  Future<NavigationActionPolicy> _maybeHandlePixiv(Uri? uri) async {
    if (uri == null) return NavigationActionPolicy.ALLOW;
    final code = extractPixivLoginCode(uri);
    if (code == null) return NavigationActionPolicy.ALLOW;
    if (_handledCode) return NavigationActionPolicy.CANCEL;
    _handledCode = true;

    await clearPendingPixivLogin();
    if (!mounted) return NavigationActionPolicy.CANCEL;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          verify: widget.loginUrl.verify,
          code: code,
        ),
      ),
    );
    return NavigationActionPolicy.CANCEL;
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.loginWithInAppWebView),
        actions: [
          if (!(io.Platform.isAndroid || io.Platform.isIOS))
            IconButton(
              tooltip: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller?.reload(),
            ),
        ],
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.loginUrl.url)),
        initialSettings: InAppWebViewSettings(
          useShouldOverrideUrlLoading: true,
        ),
        pullToRefreshController: _refreshController,
        onWebViewCreated: (controller) {
          _controller = controller;
        },
        onLoadStart: (controller, url) async {
          await _maybeHandlePixiv(url);
        },
        onLoadStop: (controller, url) async {
          _refreshController?.endRefreshing();
          await _maybeHandlePixiv(url);
        },
        onLoadError: (controller, url, code, message) {
          _refreshController?.endRefreshing();
        },
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          final url = navigationAction.request.url;
          final policy = await _maybeHandlePixiv(url);
          if (policy == NavigationActionPolicy.CANCEL) {
            return policy;
          }
          return NavigationActionPolicy.ALLOW;
        },
      ),
    );
  }

  @override
  void dispose() {
    _refreshController?.dispose();
    super.dispose();
  }
}
