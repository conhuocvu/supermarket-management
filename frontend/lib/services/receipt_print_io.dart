import 'dart:io';

Future<void> printReceipt(String receiptText) async {
  final directory = await Directory.systemTemp.createTemp('sms_receipt_');
  final file = File('${directory.path}${Platform.pathSeparator}receipt.txt');
  await file.writeAsString(receiptText);

  ProcessResult result;
  if (Platform.isWindows) {
    result = await Process.run('notepad.exe', ['/p', file.path]);
  } else {
    result = await Process.run('lp', [file.path]);
  }
  if (result.exitCode != 0) {
    throw Exception('The operating system could not print the receipt.');
  }
}
