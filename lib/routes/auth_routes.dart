import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dotenv/dotenv.dart';

import '../database/db.dart';
import '../database/mongo.dart';
import '../middleware/autenticar.dart';
import '../utils/func_global.dart';

class AuthRoutes {
  Router get router {
    final router = Router();
    
    router.post('/register', _register);
    router.post('/login', _login);
    router.post('/logout', _logout);
    
    return router;
  }
  
  Future<Response> _register(Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    
    final nome = data['nome'];
    final email = data['email'];
    final senha = data['senha'];
    
    await FuncGlobal.logEvent('[${FuncGlobal.horaAtual()}][REGISTER][POST] - Tentativa de registro do usuário: $email');
    
    try {
      // Hash da senha
      final bytes = utf8.encode(senha);
      final digest = sha256.convert(bytes);
      final hashedSenha = digest.toString();
      
      final conn = await Database.getConnection();
      await conn.query(
        'INSERT INTO users (nome, email, senha) VALUES (?, ?, ?)',
        [nome, email, hashedSenha],
      );
      // conn.close();
      
      await FuncGlobal.logEvent('[${FuncGlobal.horaAtual()}][REGISTER][POST] - Usuário registrado com sucesso: $email');
      
      return Response(201, 
        body: jsonEncode({'msg': 'Usuário registrado com sucesso'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (err) {
      await FuncGlobal.logEvent('[${FuncGlobal.horaAtual()}][REGISTER][POST][ERROR] - Erro ao registrar usuário: $email - $err');
      return Response(500, 
        body: jsonEncode({'erro': err.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
  
  Future<Response> _login(Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    
    final email = data['email'];
    final senha = data['senha'];
    final userIp = request.headers['userip'];
    
    await FuncGlobal.logEvent('[${FuncGlobal.horaAtual()}][LOGIN][POST] - Tentativa de login: $email');
    
    try {
      final conn = await Database.getConnection();
      final results = await conn.query('SELECT * FROM users WHERE email = ?', [email]);
      // conn.close();
      
      if (results.isEmpty) {
        await FuncGlobal.logEvent('[${FuncGlobal.horaAtual()}][LOGIN][POST] - Usuário não encontrado: $email');
        return Response(401, 
          body: jsonEncode({'erro': 'Usuário não encontrado'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      final user = results.first;
      
      // Verifica senha
      final bytes = utf8.encode(senha);
      final digest = sha256.convert(bytes);
      final hashedSenha = digest.toString();
      
      if (hashedSenha != user['senha']) {
        await FuncGlobal.logEvent('[${FuncGlobal.horaAtual()}][LOGIN][POST] - Senha incorreta para usuário: $email');
        return Response(401, 
          body: jsonEncode({'erro': 'Senha incorreta'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      // Gera token JWT
      var env = DotEnv(includePlatformEnvironment: true)..load();
      final jwt = JWT({
        'id': user['id'],
        'ip': userIp,
      });
      
      final token = jwt.sign(SecretKey(env['JWT_SECRET'] ?? 'secret'), 
        expiresIn: Duration(hours: int.parse(env['JWT_EXPIRES_IN_HOURS'] ?? '24')));
      
      await FuncGlobal.logEvent('[${FuncGlobal.horaAtual()}][LOGIN][POST] - Login bem sucedido: $email');
      
      return Response.ok(
        jsonEncode({
          'tokenUS': token,
          'username': user['nome'],
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (err) {
      await FuncGlobal.logEvent('[${FuncGlobal.horaAtual()}][LOGIN][POST][ERROR] - Erro no login do usuário $email - $err');
      return Response(500, 
        body: jsonEncode({'erro': err.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
  
  Future<Response> _logout(Request request) async {
    // Verifica autenticação primeiro
    final authResult = await AutenticarMiddleware.autenticar(request);
    if (authResult != null) return authResult;
    
    final authHeader = request.headers['authorization'];
    final userId = AutenticarMiddleware.getUserIdFromToken(authHeader!);
    
    await FuncGlobal.logEvent('[${FuncGlobal.horaAtual()}][LOGOUT][POST] - Logout solicitado pelo usuário ID: $userId');
    
    final token = authHeader.split(' ')[1];
    
    try {
      final sucesso = await MongoDatabase.registrarTokenUsado(token);
      
      if (!sucesso) {
        await FuncGlobal.logEvent('[${FuncGlobal.horaAtual()}][LOGOUT][POST][ERROR] - Erro ao registrar token usado no logout do usuário ID: $userId');
        return Response(500, 
          body: jsonEncode({'erro': 'Erro ao registrar token usado'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      await FuncGlobal.logEvent('[${FuncGlobal.horaAtual()}][LOGOUT][POST] - Logout realizado com sucesso para usuário ID: $userId');
      
      return Response.ok(
        jsonEncode({'mensagem': 'Logout realizado com sucesso.'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (error) {
      await FuncGlobal.logEvent('[${FuncGlobal.horaAtual()}][LOGOUT][POST][ERROR] - Erro inesperado no logout do usuário ID: $userId - $error');
      return Response(500, 
        body: jsonEncode({'erro': 'Erro inesperado no logout.'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
