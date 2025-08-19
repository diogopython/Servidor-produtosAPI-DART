import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:dotenv/dotenv.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

import 'package:api_produtos/routes/auth_routes.dart';
import 'package:api_produtos/routes/produtos_routes.dart';
import 'package:api_produtos/utils/func_global.dart';

void main() async {
  // Carrega variáveis de ambiente
  var env = DotEnv(includePlatformEnvironment: true)..load();

  final router = Router();

  // Middleware CORS
  final corsMiddleware = corsHeaders(
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, userip',
    },
  );

  // Rotas de autenticação
  final authRoutes = AuthRoutes();
  router.mount('/auth/', authRoutes.router);

  // Rotas de produtos
  final produtoRoutes = ProdutosRoutes();
  router.mount('/produtos/', produtoRoutes.router);

  // Rota de validação
  router.get('/valid', (Request request) {
    return Response.ok('{"valid": true}',
        headers: {'Content-Type': 'application/json'});
  });

  // Pipeline de middlewares
  final handler = Pipeline()
      .addMiddleware(corsMiddleware)
      .addMiddleware(logRequests())
      .addHandler(router);

  // Inicia o servidor
  var port = int.tryParse(env['PORT'] ?? '3000') ?? 3000;
  final server = await serve(handler, InternetAddress.anyIPv4, port);
  await FuncGlobal.logEvent(
      '[${FuncGlobal.horaAtual()}] API rodando em http://0.0.0.0:${port}');

  print('Servidor rodando na porta ${server.port} de todas as interfaçes');
}
