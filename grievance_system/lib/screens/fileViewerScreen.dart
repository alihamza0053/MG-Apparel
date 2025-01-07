import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class FileViewerScreen extends StatelessWidget {
  final String fileUrl;

  const FileViewerScreen({Key? key, required this.fileUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Web fallback: Open in a new browser tab
      return Scaffold(
        appBar: AppBar(title: const Text("File Viewer")),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              if (await canLaunch("https://gms.alihamza.me/gms/"+fileUrl)) {
                await launch("https://gms.alihamza.me/gms/"+fileUrl);
              } else {
                throw 'Could not launch $fileUrl';
              }
            },
            child: const Text("Open File in Browser"),
          ),
        ),
      );
    } else {
      // Mobile platforms: Use WebView
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse("https://gms.alihamza.me/gms/"+fileUrl));

      return Scaffold(
        appBar: AppBar(title: const Text("File Viewer")),
        body: WebViewWidget(controller: controller),
      );
    }
  }
}
