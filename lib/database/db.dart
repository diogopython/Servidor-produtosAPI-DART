import 'package:mysql1/mysql1.dart';
import 'package:dotenv/dotenv.dart';

class Database {
  static MySqlConnection? _connection;

  static Future<MySqlConnection> get pool async {
    if (_connection == null) {
      var env = DotEnv(includePlatformEnvironment: true)..load();

      final settings = ConnectionSettings(
        host: env['DB_HOST'] ?? 'localhost',
        port: int.parse(env['DB_PORT'] ?? '3306'),
        user: env['DB_USER'] ?? 'root',
        password: env['DB_PASSWORD'] ?? '',
        db: env['DB_DATABASE'] ?? 'produtosAPI',
      );

      _connection = await MySqlConnection.connect(settings);
    }

    return _connection!;
  }

  static Future<MySqlConnection> getConnection() async {
    return await pool;
  }
}