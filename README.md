# API de Produtos

Uma **API RESTful** para gerenciamento de produtos, construída com **Dart**, **MongoDB** e **MariaDB**. Permite realizar operações de **CRUD** (Criar, Ler, Atualizar e Deletar) produtos, com autenticação de usuários e registro de logs.

---

## Tecnologias Utilizadas

* **Dart**: Linguagem de programação utilizada no servidor
* **Shelf**: Framework para criação de APIs RESTful em Dart
* **MongoDB**: Banco de dados NoSQL para armazenamento de dados não estruturados
* **MariaDB**: Banco de dados relacional para informações estruturadas

---

## Funcionalidades

* CRUD completo de produtos:

  * Criar novos produtos
  * Listar produtos
  * Atualizar produtos existentes
  * Deletar produtos
  * Pesquisar produtos
* Autenticação básica de usuários
* Registro de logs de operações
* Suporte a múltiplos bancos de dados (**MongoDB** e **MariaDB**)

---

## Instalação e Configuração

### 1. Clone o repositório

```bash
git clone https://github.com/diogopython/Servidor-produtosAPI-DART.git
cd Servidor-produtosAPI-DART
```

### 2. Instale as dependências

```bash
dart pub get
```

### 3. Configure variáveis de ambiente

Crie um arquivo `.env` na raiz do projeto com as seguintes informações:

```env
# MariaDB
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=sua_senha
DB_NAME=produtosdb

# Segurança
JWT_SECRET=sua_chave
JWT_EXPIRES_IN=1h

# MongoDB
MONGO_URL=mongodb://usuario:senha@localhost:27017/produtosdb

# Porta
PORT=3000 <- porta padrão
```

### 4. Execute a API

```bash
dart pub get
```

```bash
dart run bin/api_produtos.dart
```

A API será iniciada e estará disponível no endereço configurado (geralmente `http://localhost:3000`).