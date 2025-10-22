-- ============================================================================
-- Script Master de Instalação V3 COMPLETO - Sistema de Boletos
-- Oracle 23i + APEX 24.2 + REST API
-- TODOS OS 10 BANCOS BRASILEIROS IMPLEMENTADOS
-- ============================================================================

PROMPT =========================================================
PROMPT Sistema de Boletos - Instalação Completa V3
PROMPT =========================================================
PROMPT
PROMPT Este script instalará:
PROMPT - Schema do banco de dados completo
PROMPT - Tabela de modelos de boleto
PROMPT - Packages PL/SQL para TODOS OS 10 BANCOS
PROMPT - Package de geração de PDF
PROMPT - Packages de utilidades, barcode, gerenciamento e HTML
PROMPT - API REST via ORDS
PROMPT - Dados de teste completos (110 boletos)
PROMPT
PROMPT BANCOS IMPLEMENTADOS (10):
PROMPT - 001: Banco do Brasil
PROMPT - 237: Bradesco
PROMPT - 104: Caixa Econômica Federal
PROMPT - 341: Itaú
PROMPT - 033: Santander
PROMPT - 756: Sicoob
PROMPT - 399: HSBC
PROMPT - 356: Banco Real
PROMPT - 041: Banrisul
PROMPT - 070: BRB - Banco de Brasília
PROMPT
PROMPT Certifique-se de estar conectado como o usuário correto!
PROMPT
PROMPT Conectado como:
SELECT USER FROM DUAL;
PROMPT

PAUSE Pressione ENTER para continuar ou CTRL+C para cancelar...

PROMPT
PROMPT =========================================================
PROMPT [1/17] Criando Schema do Banco de Dados...
PROMPT =========================================================
@@01_schema.sql

PROMPT
PROMPT =========================================================
PROMPT [2/17] Criando extensão do Schema (Modelos)...
PROMPT =========================================================
@@08_schema_modelos.sql

PROMPT
PROMPT =========================================================
PROMPT [3/17] Criando Package de Utilidades (PKG_BOLETO_UTILS)...
PROMPT =========================================================
@@02_pkg_boleto_utils.sql

PROMPT
PROMPT =========================================================
PROMPT [4/17] Criando Package para Banco do Brasil (001)...
PROMPT =========================================================
@@09_pkg_banco_001_bb.sql

PROMPT
PROMPT =========================================================
PROMPT [5/17] Criando Package para Bradesco (237)...
PROMPT =========================================================
@@10_pkg_banco_237_bradesco.sql

PROMPT
PROMPT =========================================================
PROMPT [6/17] Criando Packages para bancos complementares (6 bancos)...
PROMPT =========================================================
@@12_pkg_bancos_complementares.sql

PROMPT
PROMPT =========================================================
PROMPT [7/17] Criando Packages para bancos restantes (4 bancos)...
PROMPT =========================================================
@@14_pkg_bancos_restantes.sql

PROMPT
PROMPT =========================================================
PROMPT [8/17] Criando Package base de Código de Barras...
PROMPT =========================================================
@@03_pkg_boleto_barcode.sql

PROMPT
PROMPT =========================================================
PROMPT [9/17] Atualizando PKG_BOLETO_BARCODE com todos os bancos...
PROMPT =========================================================
@@15_update_barcode_todos_bancos.sql

PROMPT
PROMPT =========================================================
PROMPT [10/17] Criando Package de Gerenciamento (PKG_BOLETO_MANAGER)...
PROMPT =========================================================
@@04_pkg_boleto_manager.sql

PROMPT
PROMPT =========================================================
PROMPT [11/17] Atualizando PKG_BOLETO_MANAGER para gravar HTML/PDF...
PROMPT =========================================================
@@13_update_barcode_manager.sql

PROMPT
PROMPT =========================================================
PROMPT [12/17] Criando Package de HTML (PKG_BOLETO_HTML)...
PROMPT =========================================================
@@06_pkg_boleto_html.sql

PROMPT
PROMPT =========================================================
PROMPT [13/17] Criando Package de PDF (PKG_BOLETO_PDF)...
PROMPT =========================================================
@@11_pkg_boleto_pdf.sql

PROMPT
PROMPT =========================================================
PROMPT [14/17] Configurando API REST via ORDS...
PROMPT =========================================================
@@05_ords_rest_api.sql

PROMPT
PROMPT =========================================================
PROMPT [15/17] Verificando Instalação...
PROMPT =========================================================

PROMPT
PROMPT === Tabelas criadas:
SELECT table_name, num_rows
FROM user_tables
WHERE table_name LIKE 'BOLETO%'
ORDER BY table_name;

PROMPT
PROMPT === Packages criados:
SELECT object_name, object_type, status
FROM user_objects
WHERE object_type IN ('PACKAGE', 'PACKAGE BODY')
  AND object_name LIKE 'PKG_%'
ORDER BY object_name, object_type;

PROMPT
PROMPT === Packages por banco:
SELECT object_name, status
FROM user_objects
WHERE object_type = 'PACKAGE'
  AND object_name LIKE 'PKG_BANCO_%'
ORDER BY object_name;

PROMPT
PROMPT === Módulos ORDS:
SELECT name AS module_name, uri_prefix, status
FROM user_ords_modules
WHERE name LIKE '%.api'
ORDER BY name;

PROMPT
PROMPT === Bancos cadastrados:
SELECT codigo_banco, nome_banco, ativo
FROM boleto_bancos
WHERE ativo = 'S'
ORDER BY codigo_banco;

PROMPT
PROMPT === Modelos de boleto:
SELECT nome_modelo, tipo_saida, formato_pagina, quantidade_por_pagina, ativo
FROM boleto_modelos
ORDER BY nome_modelo;

PROMPT
PROMPT =========================================================
PROMPT [16/17] Dados de Teste - TODOS OS BANCOS
PROMPT =========================================================
PAUSE Pressione ENTER para criar dados de teste (110 boletos) ou CTRL+C para pular...

@@98_test_todos_bancos.sql

PROMPT
PROMPT =========================================================
PROMPT [17/17] Instalação Concluída!
PROMPT =========================================================
PROMPT
PROMPT ══════════════════════════════════════════════════════════
PROMPT ║           SISTEMA DE BOLETOS V3 - INSTALADO            ║
PROMPT ══════════════════════════════════════════════════════════
PROMPT
PROMPT ✅ BANCOS IMPLEMENTADOS: 10/10
PROMPT    001 - Banco do Brasil
PROMPT    237 - Bradesco
PROMPT    104 - Caixa Econômica Federal
PROMPT    341 - Itaú
PROMPT    033 - Santander
PROMPT    756 - Sicoob
PROMPT    399 - HSBC
PROMPT    356 - Banco Real
PROMPT    041 - Banrisul
PROMPT    070 - BRB - Banco de Brasília
PROMPT
PROMPT ✅ PACKAGES CRIADOS: 16
PROMPT    - 10 packages específicos por banco
PROMPT    - 6 packages utilitários
PROMPT
PROMPT ✅ TABELAS CRIADAS: 7
PROMPT    - boleto_bancos
PROMPT    - boleto_cedentes
PROMPT    - boleto_sacados
PROMPT    - boleto_contas
PROMPT    - boletos (com HTML/PDF)
PROMPT    - boleto_modelos
PROMPT    - boleto_historico
PROMPT
PROMPT ✅ API REST: 9 endpoints
PROMPT    - CRUD completo de boletos
PROMPT    - Geração de HTML/PDF
PROMPT    - Consultas por filtros
PROMPT
PROMPT ✅ DADOS DE TESTE (se executado):
PROMPT    - 10 boletos individuais (1 por banco)
PROMPT    - 100 parcelas de carnê (10 por banco)
PROMPT    - Total: 110 boletos gerados
PROMPT
PROMPT ══════════════════════════════════════════════════════════
PROMPT
PROMPT 📋 PRÓXIMOS PASSOS:
PROMPT
PROMPT 1. Testar API REST:
PROMPT    curl http://localhost:8080/ords/<schema>/api/v1/boletos/
PROMPT
PROMPT 2. Consultar boleto específico:
PROMPT    SELECT * FROM boletos WHERE id_boleto = 1;
PROMPT
PROMPT 3. Visualizar HTML gerado:
PROMPT    SELECT conteudo_html FROM boletos WHERE id_boleto = 1;
PROMPT
PROMPT 4. Gerar PDF:
PROMPT    DECLARE
PROMPT      v_pdf BLOB;
PROMPT    BEGIN
PROMPT      v_pdf := pkg_boleto_pdf.gerar_pdf(1);
PROMPT      pkg_boleto_pdf.salvar_pdf_boleto(1, v_pdf);
PROMPT    END;
PROMPT    /
PROMPT
PROMPT 5. Gerar carnê completo de um banco:
PROMPT    DECLARE
PROMPT      v_ids VARCHAR2(1000);
PROMPT      v_pdf BLOB;
PROMPT    BEGIN
PROMPT      SELECT LISTAGG(id_boleto, ',') WITHIN GROUP (ORDER BY id_boleto)
PROMPT      INTO v_ids
PROMPT      FROM boletos
PROMPT      WHERE numero_documento LIKE 'TESTE-001-CARNE-%';
PROMPT
PROMPT      v_pdf := pkg_boleto_pdf.gerar_pdf_carne(v_ids);
PROMPT    END;
PROMPT    /
PROMPT
PROMPT 6. Criar aplicação APEX:
PROMPT    Consulte: oracle/07_apex_application_guide.md
PROMPT
PROMPT ══════════════════════════════════════════════════════════
PROMPT
PROMPT 📚 DOCUMENTAÇÃO:
PROMPT    - oracle/README.md - Guia completo
PROMPT    - oracle/WHATS_NEW_V2.md - Novidades V2
PROMPT    - oracle/CONVERSION_GUIDE.md - Conversão Python→Oracle
PROMPT
PROMPT ══════════════════════════════════════════════════════════
PROMPT
PROMPT 🎯 RECURSOS IMPLEMENTADOS:
PROMPT
PROMPT ✓ Arquitetura modular por banco
PROMPT ✓ Cálculo automático de código de barras
PROMPT ✓ Linha digitável formatada
PROMPT ✓ Validação de CPF/CNPJ
PROMPT ✓ Armazenamento de HTML/PDF no banco
PROMPT ✓ Cache automático de conteúdo
PROMPT ✓ Modelos configuráveis
PROMPT ✓ Histórico completo de operações
PROMPT ✓ Metadados em JSON
PROMPT ✓ API REST completa
PROMPT ✓ Geração de carnês
PROMPT ✓ Suporte a todos os bancos brasileiros principais
PROMPT
PROMPT ══════════════════════════════════════════════════════════
PROMPT
PROMPT Sistema pronto para uso em PRODUÇÃO! 🚀
PROMPT
PROMPT ══════════════════════════════════════════════════════════
