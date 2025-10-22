-- ============================================================================
-- Script Master de Instalação - Sistema de Boletos
-- Oracle 23i + APEX 24.2 + REST API
-- ============================================================================

PROMPT =========================================================
PROMPT Sistema de Boletos - Instalação Completa
PROMPT =========================================================
PROMPT
PROMPT Este script instalará:
PROMPT - Schema de banco de dados (tabelas, índices, triggers)
PROMPT - Packages PL/SQL (utilidades, barcode, gerenciamento, HTML)
PROMPT - API REST via ORDS
PROMPT
PROMPT Certifique-se de estar conectado como o usuário correto!
PROMPT
PROMPT Conectado como:
SELECT USER FROM DUAL;
PROMPT

PAUSE Pressione ENTER para continuar ou CTRL+C para cancelar...

PROMPT
PROMPT =========================================================
PROMPT [1/6] Criando Schema do Banco de Dados...
PROMPT =========================================================
@@01_schema.sql

PROMPT
PROMPT =========================================================
PROMPT [2/6] Criando Package de Utilidades (PKG_BOLETO_UTILS)...
PROMPT =========================================================
@@02_pkg_boleto_utils.sql

PROMPT
PROMPT =========================================================
PROMPT [3/6] Criando Package de Código de Barras (PKG_BOLETO_BARCODE)...
PROMPT =========================================================
@@03_pkg_boleto_barcode.sql

PROMPT
PROMPT =========================================================
PROMPT [4/6] Criando Package de Gerenciamento (PKG_BOLETO_MANAGER)...
PROMPT =========================================================
@@04_pkg_boleto_manager.sql

PROMPT
PROMPT =========================================================
PROMPT [5/6] Configurando API REST via ORDS...
PROMPT =========================================================
@@05_ords_rest_api.sql

PROMPT
PROMPT =========================================================
PROMPT [6/6] Criando Package de HTML (PKG_BOLETO_HTML)...
PROMPT =========================================================
@@06_pkg_boleto_html.sql

PROMPT
PROMPT =========================================================
PROMPT Verificando Instalação...
PROMPT =========================================================

-- Verificar tabelas
PROMPT
PROMPT Tabelas criadas:
SELECT table_name, num_rows
FROM user_tables
WHERE table_name LIKE 'BOLETO%'
ORDER BY table_name;

-- Verificar packages
PROMPT
PROMPT Packages criados:
SELECT object_name, object_type, status
FROM user_objects
WHERE object_type IN ('PACKAGE', 'PACKAGE BODY')
  AND object_name LIKE 'PKG_BOLETO%'
ORDER BY object_name, object_type;

-- Verificar módulos ORDS
PROMPT
PROMPT Módulos ORDS:
SELECT name AS module_name, uri_prefix, status
FROM user_ords_modules
WHERE name LIKE '%.api'
ORDER BY name;

-- Verificar dados iniciais
PROMPT
PROMPT Bancos cadastrados:
SELECT codigo_banco, nome_banco, ativo
FROM boleto_bancos
WHERE ativo = 'S'
ORDER BY nome_banco;

PROMPT
PROMPT =========================================================
PROMPT Instalação Concluída com Sucesso!
PROMPT =========================================================
PROMPT
PROMPT Próximos passos:
PROMPT 1. Cadastrar cedentes (empresas)
PROMPT 2. Cadastrar sacados (clientes)
PROMPT 3. Cadastrar contas bancárias
PROMPT 4. Criar boletos via API REST ou PL/SQL
PROMPT
PROMPT Para criar aplicação APEX, consulte:
PROMPT   oracle/07_apex_application_guide.md
PROMPT
PROMPT Para documentação completa, consulte:
PROMPT   oracle/README.md
PROMPT
PROMPT API REST disponível em:
PROMPT   http://<servidor>:<porta>/ords/<schema>/api/v1/
PROMPT
PROMPT =========================================================

-- Script de exemplo básico
PROMPT
PROMPT Deseja executar script de teste? (Criará cedente, sacado e boleto exemplo)
PAUSE Pressione ENTER para executar ou CTRL+C para pular...

@@99_test_data.sql

PROMPT
PROMPT =========================================================
PROMPT Instalação e Testes Concluídos!
PROMPT =========================================================
