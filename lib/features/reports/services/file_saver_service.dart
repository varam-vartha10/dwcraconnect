import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';

class FileSaverService {
  static Future<String> saveAndOpenFile({
    required List<int> bytes,
    required String filename,
    required String fileType, // 'pdf' or 'excel'
  }) async {
    final uint8Bytes = Uint8List.fromList(bytes);

    // Web handling
    if (kIsWeb) {
      if (fileType == 'pdf') {
        await Printing.sharePdf(bytes: uint8Bytes, filename: filename);
      } else {
        await Printing.sharePdf(bytes: uint8Bytes, filename: filename);
      }
      return 'Web Download Initialized';
    }

    // Android / iOS / Desktop handling
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$filename';
    final file = File(filePath);

    await file.writeAsBytes(uint8Bytes, flush: true);

    if (kDebugMode) {
      print('Report saved successfully to: $filePath');
    }

    // Open file using open_filex
    try {
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        // Fallback to share_plus if no direct viewer is registered
        await Share.shareXFiles([XFile(filePath)], text: 'DWCRA Connect $filename');
      }
    } catch (_) {
      await Share.shareXFiles([XFile(filePath)], text: 'DWCRA Connect $filename');
    }

    return filePath;
  }

  static Future<void> shareFile({
    required String filePath,
    required String title,
  }) async {
    if (kIsWeb) return;
    final file = File(filePath);
    if (await file.exists()) {
      await Share.shareXFiles([XFile(filePath)], text: title);
    }
  }
}
