import 'dart:io';
import 'package:intl/intl.dart';

class FuncGlobal {
  static String horaAtual() {
    final agora = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(agora);
  }
  
  static Future<void> logEvent(String message) async {
    final logLine = '$message\n';
    
    // Imprime no console
    print(logLine.trim());
    
    try {
      // Escreve no arquivo de log
      final file = File('./log-server.log');
      await file.writeAsString(logLine, mode: FileMode.append);
    } catch (err) {
      print('Erro ao escrever no log: $err');
    }
  }
}
