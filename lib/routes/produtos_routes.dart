import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../database/db.dart';
import '../middleware/autenticar.dart';
import '../utils/func_global.dart';

class ProdutosRoutes {
  Router get router {
    final router = Router();

    router.post('/', _criarProduto);
    router.get('/', _listarProdutos);
    router.put('/<id>', _atualizarProduto);
    router.delete('/<id>', _deletarProduto);
    router.post('/search', _pesquisarProdutos);

    return router;
  }

  Future<Response> _criarProduto(Request request) async {
    // Verifica autenticação
    final authResult = await AutenticarMiddleware.autenticar(request);
    if (authResult != null) return authResult;

    final authHeader = request.headers['authorization']!;
    final userId = AutenticarMiddleware.getUserIdFromToken(authHeader);

    final body = await request.readAsString();
    final data = jsonDecode(body);

    final nome = data['nome'];
    final preco = data['preco'];
    final quantidade = data['quantidade'];

    await FuncGlobal.logEvent(
        '[${FuncGlobal.horaAtual()}][PRODUTO][CREATE][POST] - Usuário ID: $userId tentando criar produto');

    try {
      final conn = await Database.getConnection();
      await conn.query(
        'INSERT INTO produtos (user_id, nome, preco, quantidade) VALUES (?, ?, ?, ?)',
        [userId, nome, preco, quantidade],
      );
      // conn.close();

      await FuncGlobal.logEvent(
          '[${FuncGlobal.horaAtual()}][PRODUTO][CREATE][POST] - Produto criado com sucesso pelo usuário ID: $userId | Nome: $nome');

      return Response(
        201,
        body: jsonEncode({'msg': 'Produto criado'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (err) {
      await FuncGlobal.logEvent(
          '[${FuncGlobal.horaAtual()}][PRODUTO][CREATE][POST][ERROR] - Erro ao criar produto para usuário ID: $userId - $err');
      return Response(
        500,
        body: jsonEncode({'erro': err.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _listarProdutos(Request request) async {
    // Verifica autenticação
    final authResult = await AutenticarMiddleware.autenticar(request);
    if (authResult != null) return authResult;

    final authHeader = request.headers['authorization']!;
    final userId = AutenticarMiddleware.getUserIdFromToken(authHeader);

    await FuncGlobal.logEvent(
        '[${FuncGlobal.horaAtual()}][PRODUTO][LIST][GET] - Listando produtos do usuário ID: $userId');

    try {
      final conn = await Database.getConnection();
      final results = await conn
          .query('SELECT * FROM produtos WHERE user_id = ?', [userId]);
      // conn.close();

      final produtos = results
          .map((row) => {
                'id': row['id'],
                'user_id': row['user_id'],
                'nome': row['nome'],
                'preco': row['preco'],
                'quantidade': row['quantidade'],
              })
          .toList();

      await FuncGlobal.logEvent(
          '[${FuncGlobal.horaAtual()}][PRODUTO][LIST][GET] - Produtos listados com sucesso para usuário ID: $userId | Quantidade: ${produtos.length}');

      return Response.ok(
        jsonEncode(produtos),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (err) {
      await FuncGlobal.logEvent(
          '[${FuncGlobal.horaAtual()}][PRODUTO][LIST][GET][ERROR] - Erro ao listar produtos para usuário ID: $userId - $err');
      return Response(
        500,
        body: jsonEncode({'erro': err.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _atualizarProduto(Request request) async {
    // Verifica autenticação
    final authResult = await AutenticarMiddleware.autenticar(request);
    if (authResult != null) return authResult;

    final authHeader = request.headers['authorization']!;
    final userId = AutenticarMiddleware.getUserIdFromToken(authHeader);
    final id = request.params['id'];

    final body = await request.readAsString();
    final data = jsonDecode(body);

    final nome = data['nome'];
    final preco = data['preco'];
    final quantidade = data['quantidade'];

    await FuncGlobal.logEvent(
        '[${FuncGlobal.horaAtual()}][PRODUTO][UPDATE][PUT] - Usuário ID: $userId tentando atualizar produto ID: $id');
    await FuncGlobal.logEvent(
        'Dados recebidos do usuário: ${jsonEncode(data)}');

    try {
      final conn = await Database.getConnection();
      final result = await conn.query(
        'UPDATE produtos SET nome = ?, preco = ?, quantidade = ? WHERE id = ? AND user_id = ?',
        [nome, preco, quantidade, id, userId],
      );
      // conn.close();

      if (result.affectedRows == 0) {
        await FuncGlobal.logEvent(
            '[${FuncGlobal.horaAtual()}][PRODUTO][UPDATE][PUT] - Produto ID: $id não encontrado ou sem permissão para atualizar pelo usuário ID: $userId');
        return Response(
          404,
          body: jsonEncode({
            'erro': 'Produto não encontrado ou sem permissão para atualizar'
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      await FuncGlobal.logEvent(
          '[${FuncGlobal.horaAtual()}][PRODUTO][UPDATE][PUT] - Produto ID: $id atualizado com sucesso pelo usuário ID: $userId');

      return Response.ok(
        jsonEncode({'msg': 'Produto atualizado com sucesso'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (err) {
      await FuncGlobal.logEvent(
          '[${FuncGlobal.horaAtual()}][PRODUTO][UPDATE][PUT][ERROR] - Erro ao atualizar produto ID: $id para usuário ID: $userId - $err');
      return Response(
        500,
        body: jsonEncode({'erro': err.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _deletarProduto(Request request) async {
    // Verifica autenticação
    final authResult = await AutenticarMiddleware.autenticar(request);
    if (authResult != null) return authResult;

    final authHeader = request.headers['authorization']!;
    final userId = AutenticarMiddleware.getUserIdFromToken(authHeader);
    final id = request.params['id'];

    await FuncGlobal.logEvent(
        '[${FuncGlobal.horaAtual()}][PRODUTO][DELETE][DELETE] - Usuário ID: $userId tentando deletar produto ID: $id');

    try {
      final conn = await Database.getConnection();
      final result = await conn.query(
        'DELETE FROM produtos WHERE id = ? AND user_id = ?',
        [id, userId],
      );
      // conn.close();

      if (result.affectedRows == 0) {
        await FuncGlobal.logEvent(
            '[${FuncGlobal.horaAtual()}][PRODUTO][DELETE][DELETE] - Produto ID: $id não encontrado ou sem permissão para deletar pelo usuário ID: $userId');
        return Response(
          404,
          body: jsonEncode(
              {'erro': 'Produto não encontrado ou sem permissão para deletar'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      await FuncGlobal.logEvent(
          '[${FuncGlobal.horaAtual()}][PRODUTO][DELETE][DELETE] - Produto ID: $id deletado com sucesso pelo usuário ID: $userId');

      return Response.ok(
        jsonEncode({'msg': 'Produto deletado'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (err) {
      await FuncGlobal.logEvent(
          '[${FuncGlobal.horaAtual()}][PRODUTO][DELETE][DELETE][ERROR] - Erro ao deletar produto ID: $id para usuário ID: $userId - $err');
      return Response(
        500,
        body: jsonEncode({'erro': err.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _pesquisarProdutos(Request request) async {
    // Verifica autenticação
    final authResult = await AutenticarMiddleware.autenticar(request);
    if (authResult != null) return authResult;

    final authHeader = request.headers['authorization']!;
    final userId = AutenticarMiddleware.getUserIdFromToken(authHeader);

    final body = await request.readAsString();
    final data = jsonDecode(body);
    final query = data['query'];

    await FuncGlobal.logEvent(
        '[${FuncGlobal.horaAtual()}][PRODUTO][SEARCH][POST] - Usuário ID: $userId pesquisando produtos com query: "$query"');

    if (query == null || query.isEmpty) {
      await FuncGlobal.logEvent(
          '[${FuncGlobal.horaAtual()}][PRODUTO][SEARCH][POST] - Parâmetro de busca ausente para usuário ID: $userId');
      return Response(
        400,
        body: jsonEncode({'erro': 'Parâmetro de busca "query" é obrigatório.'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    try {
      final conn = await Database.getConnection();
      final results = await conn.query(
        'SELECT * FROM produtos WHERE user_id = ? AND nome LIKE ?',
        [userId, '%$query%'],
      );
      //conn.close();

      final produtos = results
          .map((row) => {
                'id': row['id'],
                'user_id': row['user_id'],
                'nome': row['nome'],
                'preco': row['preco'],
                'quantidade': row['quantidade'],
              })
          .toList();

      await FuncGlobal.logEvent(
          '[${FuncGlobal.horaAtual()}][PRODUTO][SEARCH][POST] - Pesquisa concluída para usuário ID: $userId | Resultados: ${produtos.length}');

      return Response.ok(
        jsonEncode({'produtos': produtos}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (err) {
      await FuncGlobal.logEvent(
          '[${FuncGlobal.horaAtual()}][PRODUTO][SEARCH][POST][ERROR] - Erro na pesquisa para usuário ID: $userId - $err');
      return Response(
        500,
        body: jsonEncode({'erro': err.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
