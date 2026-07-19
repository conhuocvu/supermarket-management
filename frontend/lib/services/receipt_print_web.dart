import 'dart:convert';
// ignore: deprecated_member_use
import 'dart:html' as html;

Future<void> printReceipt(String receiptText) async {
  final escaped = const HtmlEscape().convert(receiptText);
  final document = '''
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>Supermarket Receipt</title>
  <style>
    body { font-family: monospace; margin: 24px; }
    pre { white-space: pre-wrap; font-size: 13px; line-height: 1.45; }
    @media print { body { margin: 0; } }
  </style>
</head>
<body>
  <pre>$escaped</pre>
  <script>window.onload = function () { window.print(); };</script>
</body>
</html>
''';
  final uri = Uri.dataFromString(
    document,
    mimeType: 'text/html',
    encoding: utf8,
  );
  html.window.open(uri.toString(), '_blank');
}
