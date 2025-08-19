import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dotenv/dotenv.dart';

import '../database/mongo.dart';
import '../utils/func_global.dart';

class AutenticarMiddleware {
  static Future<Response?> autenticar(Request request) async {
    try {
      final authHeader = request.headers['authorization'];
      final userIp = request.headers['userip'];
      
      if (authHeader == null) {
        return Response(401, body: jsonEncode({'erro': 'Token ausente'}));
      }
      
      if (userIp == null) {
        return Response(400, body: jsonEncode({'erro': 'IP do usuário ausente'}));
      }
      
      final token = authHeader.split(' ').length > 1 ? authHeader.split(' ')[1] : null;
      if (token == null) {
        return Response(401, body: jsonEncode({'erro': 'Token ausente'}));
      }
      
      // Verifica validade JWT
      final decoded = _verificarTokenJWT(token);
      if (decoded == null) {
        return Response(403, body: jsonEncode({'erro': 'Token inválido ou expirado'}));
      }
      
      // Verifica se token já foi usado
      final usado = await MongoDatabase.tokenJaUsado(token);
      if (usado) {
        return Response(403, body: jsonEncode({'erro': 'Token já usado ou inválido'}));
      }
      
      await FuncGlobal.logEvent('[${FuncGlobal.horaAtual()}] verify token in mongodb: $usado');
      
      if (userIp != decoded['ip']) {
        return Response(403, body: jsonEncode({'erro': 'IP do usuário não corresponde ao token'}));
      }
      
      await FuncGlobal.logEvent('[${FuncGlobal.horaAtual()}] IP do usuário corresponde ao token: $userIp');
      
      // Adiciona userId ao request context
      return null; // Continua para o próximo handler
    } catch (err) {
      return Response(403, body: jsonEncode({'erro': 'Token inválido ou expirado'}));
    }
  }
  
  static Map<String, dynamic>? _verificarTokenJWT(String token) {
    try {
      var env = DotEnv(includePlatformEnvironment: true)..load();
      final jwt = JWT.verify(token, SecretKey(env['JWT_SECRET'] ?? 'secret'));
      return jwt.payload;
    } catch (e) {
      return null;
    }
  }
  
  static int? getUserIdFromToken(String authHeader) {
    final token = authHeader.split(' ').length > 1 ? authHeader.split(' ')[1] : null;
    if (token == null) return null;
    
    final decoded = _verificarTokenJWT(token);
    return decoded?['id'];
  }
}
