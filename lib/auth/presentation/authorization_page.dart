import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:repo_viewer/auth/infrastructure/github_authenticator.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

@RoutePage()
class AuthorizationPage extends StatefulWidget {
  final Uri authorizationUrl;
  final void Function(Uri redirectUrl) onAuthorizationCodeRedirectAttemp;

  const AuthorizationPage({
    super.key,
    required this.authorizationUrl,
    required this.onAuthorizationCodeRedirectAttemp,
  });

  @override
  State<AuthorizationPage> createState() => _AuthorizationPageState();
}

class _AuthorizationPageState extends State<AuthorizationPage> {
  late final WebViewController _controller;
  // final WebViewController _controller = WebViewController();

  @override
  void initState() {
    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      // ..clearCache()
      // ..clearLocalStorage()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(widget.authorizationUrl)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            // controller
            //   ..clearCache()
            //   ..clearLocalStorage();
            // WebViewCookieManager().clearCookies();
            debugPrint('Page started loading: $url');
          },
          onProgress: (int progress) {
            controller
              ..clearCache()
              ..clearLocalStorage();
            WebViewCookieManager().clearCookies();
            debugPrint('WebView is loading (progress : $progress%)');
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''Page resource 
                      error:code: ${error.errorCode}
                      description: ${error.description}
                      errorType: ${error.errorType}
                      isForMainFrame: ${error.isForMainFrame}''');
          },
          onNavigationRequest: (navReq) {
            if (navReq.url
                .startsWith(GithubAuthenticator.redirectUrl.toString())) {
              widget.onAuthorizationCodeRedirectAttemp(
                Uri.parse(navReq.url),
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WebViewWidget(
          controller: _controller,
        ),
      ),
    );
  }
}
