-- ============================================================================
-- Script Master de Instalação V2 - Sistema de Boletos
-- Oracle 23i + APEX 24.2 + REST API
-- Com Packages Separados por Banco e Geração de PDF
-- ============================================================================

PROMPT =========================================================
PROMPT Sistema de Boletos - Instalação Completa V2
PROMPT =========================================================
PROMPT
PROMPT Este script instalará:
PROMPT - Schema do banco de dados
PROMPT - Tabela de modelos de boleto
PROMPT - Packages PL/SQL para cada banco
PROMPT - Package de geração de PDF
PROMPT - Packages de utilidades, barcode, gerenciamento e HTML
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
PROMPT [1/14] Criando Schema do Banco de Dados...
PROMPT =========================================================
@@01_schema.sql

PROMPT
PROMPT =========================================================
PROMPT [2/14] Criando extensão do Schema (Modelos)...
PROMPT =========================================================
@@08_schema_modelos.sql

PROMPT
PROMPT =========================================================
PROMPT [3/14] Criando Package de Utilidades (PKG_BOLETO_UTILS)...
PROMPT =========================================================
@@02_pkg_boleto_utils.sql

PROMPT
PROMPT =========================================================
PROMPT [4/14] Criando Package para Banco do Brasil (001)...
PROMPT =========================================================
@@09_pkg_banco_001_bb.sql

PROMPT
PROMPT =========================================================
PROMPT [5/14] Criando Package para Bradesco (237)...
PROMPT =========================================================
@@10_pkg_banco_237_bradesco.sql

PROMPT
PROMPT =========================================================
PROMPT [6/14] Criando Packages para bancos complementares...
PROMPT =========================================================
@@12_pkg_bancos_complementares.sql

PROMPT
PROMPT =========================================================
PROMPT [7/14] Criando Package de Código de Barras (PKG_BOLETO_BARCODE)...
PROMPT =========================================================
@@03_pkg_boleto_barcode.sql

PROMPT
PROMPT =========================================================
PROMPT [8/14] Atualizando PKG_BOLETO_BARCODE e PKG_BOLETO_MANAGER...
PROMPT =========================================================
@@13_update_barcode_manager.sql

PROMPT
PROMPT =========================================================
PROMPT [9/14] Criando Package de Gerenciamento (PKG_BOLETO_MANAGER)...
PROMPT =========================================================
@@04_pkg_boleto_manager.sql

PROMPT
PROMPT =========================================================
PROMPT [10/14] Criando Package de HTML (PKG_BOLETO_HTML)...
PROMPT =========================================================
@@06_pkg_boleto_html.sql

PROMPT
PROMPT =========================================================
PROMPT [11/14] Criando Package de PDF (PKG_BOLETO_PDF)...
PROMPT =========================================================
@@11_pkg_boleto_pdf.sql

PROMPT
PROMPT =========================================================
PROMPT [12/14] Configurando API REST via ORDS...
PROMPT =========================================================
@@05_ords_rest_api.sql

PROMPT
PROMPT =========================================================
PROMPT [13/14] Verificando Instalação...
PROMPT =========================================================

PROMPT
PROMPT Tabelas criadas:
SELECT table_name, num_rows
FROM user_tables
WHERE table_name LIKE 'BOLETO%'
ORDER BY table_name;

PROMPT
PROMPT Packages criados:
SELECT object_name, object_type, status
FROM user_objects
WHERE object_type IN ('PACKAGE', 'PACKAGE BODY')
  AND object_name LIKE 'PKG_%'
ORDER BY object_name, object_type;

PROMPT
PROMPT Módulos ORDS:
SELECT name AS module_name, uri_prefix, status
FROM user_ords_modules
WHERE name LIKE '%.api'
ORDER BY name;

PROMPT
PROMPT Bancos cadastrados:
SELECT codigo_banco, nome_banco, ativo
FROM boleto_bancos
WHERE ativo = 'S'
ORDER BY nome_banco;

PROMPT
PROMPT Modelos de boleto:
SELECT nome_modelo, tipo_saida, formato_pagina, quantidade_por_pagina, ativo
FROM boleto_modelos
ORDER BY nome_modelo;

PROMPT
PROMPT =========================================================
PROMPT [14/14] Dados de Teste (Opcional)...
PROMPT =========================================================
PAUSE Pressione ENTER para criar dados de teste ou CTRL+C para pular...

@@99_test_data.sql

PROMPT
PROMPT =========================================================
PROMPT Instalação Concluída com Sucesso!
PROMPT =========================================================
PROMPT
PROMPT Arquitetura implementada:
PROMPT
PROMPT 1. BANCO DE DADOS
PROMPT    - 7 tabelas principais
PROMPT    - Índices otimizados
PROMPT    - Triggers de auditoria
PROMPT    - 10 bancos brasileiros cadastrados
PROMPT    - 4 modelos de boleto (HTML/PDF)
PROMPT
PROMPT 2. PACKAGES POR BANCO (Separados)
PROMPT    - pkg_banco_001_bb (Banco do Brasil)
PROMPT    - pkg_banco_237_bradesco (Bradesco)
PROMPT    - pkg_banco_104_caixa (Caixa)
PROMPT    - pkg_banco_341_itau (Itaú)
PROMPT    - pkg_banco_033_santander (Santander)
PROMPT    - pkg_banco_756_sicoob (Sicoob)
PROMPT
PROMPT 3. PACKAGES UTILITÁRIOS
PROMPT    - pkg_boleto_utils (Cálculos e validações)
PROMPT    - pkg_boleto_barcode (Delegação para bancos)
PROMPT    - pkg_boleto_manager (CRUD e operações)
PROMPT    - pkg_boleto_html (Geração HTML)
PROMPT    - pkg_boleto_pdf (Geração PDF)
PROMPT
PROMPT 4. API REST (ORDS)
PROMPT    - 9 endpoints RESTful
PROMPT    - JSON nativo Oracle 23i
PROMPT    - CRUD completo
PROMPT
PROMPT Próximos passos:
PROMPT 1. Cadastrar cedentes (empresas)
PROMPT 2. Cadastrar sacados (clientes)
PROMPT 3. Cadastrar contas bancárias
PROMPT 4. Criar boletos via API REST ou PL/SQL
PROMPT 5. Gerar HTML/PDF automaticamente
PROMPT
PROMPT Para criar aplicação APEX:
PROMPT   oracle/07_apex_application_guide.md
PROMPT
PROMPT Para documentação completa:
PROMPT   oracle/README.md
PROMPT
PROMPT API REST disponível em:
PROMPT   http://<servidor>:<porta>/ords/<schema>/api/v1/
PROMPT
PROMPT Exemplo de uso PL/SQL:
PROMPT   DECLARE
PROMPT     v_id NUMBER;
PROMPT   BEGIN
PROMPT     v_id := pkg_boleto_manager.criar_boleto(
PROMPT       p_id_conta => 1,
PROMPT       p_id_sacado => 1,
PROMPT       p_numero_documento => 'DOC-001',
PROMPT       p_nosso_numero => '000001',
PROMPT       p_data_documento => SYSDATE,
PROMPT       p_data_vencimento => SYSDATE + 30,
PROMPT       p_valor_documento => 1500.00
PROMPT     );
PROMPT     DBMS_OUTPUT.PUT_LINE('Boleto ID: ' || v_id);
PROMPT
PROMPT     -- HTML gerado automaticamente!
PROMPT     -- Para obter: SELECT conteudo_html FROM boletos WHERE id_boleto = v_id;
PROMPT   END;
PROMPT   /
PROMPT
PROMPT =========================================================
PROMPT Sistema Pronto para Uso!
PROMPT =========================================================
