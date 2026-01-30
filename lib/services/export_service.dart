import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ExportService {
  static Future<void> exportToFile() async {
    // Mock data collection
    final data = {
      'timestamp': DateTime.now().toIso8601String(),
      'transactions': [], // In real app, fetch from Hive
    };

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/backup.json');
    await file.writeAsString(jsonEncode(data));
  }
}
