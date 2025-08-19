import 'package:mongo_dart/mongo_dart.dart';
import '../utils/func_global.dart';
import 'package:dotenv/dotenv.dart';

class MongoDatabase {
  static late final Db _db;

  static Future<void> init() async {
    final env = DotEnv(includePlatformEnvironment: true)..load();
    _db = Db(env['MONGO_URL']!);
    await _db.open();
  }

  static Future<void> close() async {
    await _db.close();
  }

  static Future<bool> registrarTokenUsado(String token) async {
    try {
      final colecao = _db.collection('tokens_usados');
      await colecao.insertOne({
        'token': token,
        'usado_em': DateTime.now(),
      });
      return true;
    } catch (erro) {
      await FuncGlobal.logEvent('[${FuncGlobal.horaAtual()}] Erro ao registrar token: $erro');
      return false;
    }
  }

  static Future<bool> tokenJaUsado(String token) async {
    try {
      final colecao = _db.collection('tokens_usados');
      final resultado = await colecao.findOne(where.eq('token', token));
      return resultado != null;
    } catch (erro) {
      await FuncGlobal.logEvent('[${FuncGlobal.horaAtual()}] Erro em tokenJaUsado: $erro');
      return false;
    }
  }
}