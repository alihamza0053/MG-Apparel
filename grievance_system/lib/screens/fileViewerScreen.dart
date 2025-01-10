import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class FileViewerScreen extends StatefulWidget {
  final String fileUrl;

  const FileViewerScreen({Key? key, required this.fileUrl}) : super(key: key);

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: InAppWebView(

          initialUrlRequest: URLRequest(url: WebUri("https://groundup.pk/gms/"+widget.fileUrl)),
        ),
      ),
    );






    // if (kIsWeb) {
    //   // Web fallback: Open in a new browser tab
    //   return Scaffold(
    //     appBar: AppBar(title: const Text("File Viewer")),
    //     body: Center(
    //       child: ElevatedButton(
    //         onPressed: () async {
    //           if (await canLaunch("https://gms.alihamza.me/gms/"+widget.fileUrl)) {
    //             await launch("https://gms.alihamza.me/gms/"+widget.fileUrl);
    //           } else {
    //             throw 'Could not launch ${widget.fileUrl}';
    //           }
    //         },
    //         child: const Text("Open File in Browser"),
    //       ),
    //     ),
    //   );
    // } else {
    //   // Mobile platforms: Use WebView
    //   final controller = WebViewController()
    //     ..setJavaScriptMode(JavaScriptMode.unrestricted)
    //     ..loadRequest(Uri.parse("https://gms.alihamza.me/gms/"+widget.fileUrl));
    //
    //   return Scaffold(
    //     appBar: AppBar(title: const Text("File Viewer")),
    //     body: WebViewWidget(controller: controller),
    //   );
    // }
  }
}
