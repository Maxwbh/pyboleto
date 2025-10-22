-- ============================================================================
-- Script de Teste Completo - Todos os Bancos
-- Gera boletos individuais e carnês de 10 parcelas para cada banco
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200

PROMPT =========================================================
PROMPT TESTE COMPLETO - TODOS OS BANCOS
PROMPT =========================================================
PROMPT
PROMPT Este script irá:
PROMPT 1. Criar cedente e sacado de teste
PROMPT 2. Criar contas bancárias para os 10 bancos
PROMPT 3. Gerar 1 boleto individual para cada banco (10 boletos)
PROMPT 4. Gerar carnê de 10 parcelas para cada banco (100 boletos)
PROMPT 5. Validar códigos de barras gerados
PROMPT 6. Gerar HTML para todos os boletos
PROMPT
PROMPT Total de boletos gerados: 110
PROMPT
PROMPT =========================================================

-- Limpar dados de teste anteriores (se existirem)
BEGIN
    DELETE FROM boleto_historico WHERE id_boleto IN (SELECT id_boleto FROM boletos WHERE numero_documento LIKE 'TESTE-%');
    DELETE FROM boletos WHERE numero_documento LIKE 'TESTE-%';
    DELETE FROM boleto_contas WHERE id_cedente IN (SELECT id_cedente FROM boleto_cedentes WHERE documento = '12.345.678/0001-90');
    DELETE FROM boleto_sacados WHERE documento = '987.654.321-00';
    DELETE FROM boleto_cedentes WHERE documento = '12.345.678/0001-90';
    COMMIT;
END;
/

PROMPT
PROMPT =========================================================
PROMPT [1/6] Criando Cedente e Sacado de Teste
PROMPT =========================================================

-- Criar cedente de teste
INSERT INTO boleto_cedentes (
    nome,
    documento,
    tipo_documento,
    logradouro,
    bairro,
    cidade,
    uf,
    cep,
    endereco_completo
) VALUES (
    'EMPRESA TESTE LTDA',
    '12.345.678/0001-90',
    'CNPJ',
    'Avenida Paulista, 1000',
    'Bela Vista',
    'São Paulo',
    'SP',
    '01310-100',
    'Avenida Paulista, 1000 - Bela Vista - São Paulo - SP - CEP 01310-100'
);

PROMPT Cedente criado: EMPRESA TESTE LTDA

-- Criar sacado de teste
INSERT INTO boleto_sacados (
    nome,
    documento,
    tipo_documento,
    logradouro,
    bairro,
    cidade,
    uf,
    cep,
    endereco_completo
) VALUES (
    'CLIENTE TESTE SILVA',
    '987.654.321-00',
    'CPF',
    'Rua das Flores, 123',
    'Centro',
    'Rio de Janeiro',
    'RJ',
    '20010-000',
    'Rua das Flores, 123 - Centro - Rio de Janeiro - RJ - CEP 20010-000'
);

PROMPT Sacado criado: CLIENTE TESTE SILVA

COMMIT;

PROMPT
PROMPT =========================================================
PROMPT [2/6] Criando Contas Bancárias para os 10 Bancos
PROMPT =========================================================

DECLARE
    v_id_cedente NUMBER;
    v_id_sacado NUMBER;
BEGIN
    -- Buscar IDs criados
    SELECT id_cedente INTO v_id_cedente FROM boleto_cedentes WHERE documento = '12.345.678/0001-90';
    SELECT id_sacado INTO v_id_sacado FROM boleto_sacados WHERE documento = '987.654.321-00';

    -- Banco do Brasil (001)
    INSERT INTO boleto_contas (id_cedente, id_banco, agencia, agencia_dv, conta, conta_dv, carteira, convenio, ativo)
    VALUES (v_id_cedente, 1, '1234', '0', '12345678', '9', '18', '1234567', 'S');

    -- Bradesco (237)
    INSERT INTO boleto_contas (id_cedente, id_banco, agencia, agencia_dv, conta, conta_dv, carteira, ativo)
    VALUES (v_id_cedente, 2, '0278', '0', '0039232', '4', '06', 'S');

    -- Caixa (104)
    INSERT INTO boleto_contas (id_cedente, id_banco, agencia, agencia_dv, conta, conta_dv, carteira, ativo)
    VALUES (v_id_cedente, 3, '1234', '0', '12345678', '9', '14', 'S');

    -- Itaú (341)
    INSERT INTO boleto_contas (id_cedente, id_banco, agencia, agencia_dv, conta, conta_dv, carteira, ativo)
    VALUES (v_id_cedente, 4, '0123', '0', '12345', '6', '175', 'S');

    -- Santander (033)
    INSERT INTO boleto_contas (id_cedente, id_banco, agencia, agencia_dv, conta, conta_dv, carteira, ativo)
    VALUES (v_id_cedente, 5, '1234', '0', '12345678', '9', '101', 'S');

    -- HSBC (399)
    INSERT INTO boleto_contas (id_cedente, id_banco, agencia, agencia_dv, conta, conta_dv, carteira, ativo)
    VALUES (v_id_cedente, 6, '1234', '0', '1234567', '8', '00', 'S');

    -- Banco Real (356)
    INSERT INTO boleto_contas (id_cedente, id_banco, agencia, agencia_dv, conta, conta_dv, carteira, ativo)
    VALUES (v_id_cedente, 7, '1234', '0', '12345678', '9', '57', 'S');

    -- Banrisul (041)
    INSERT INTO boleto_contas (id_cedente, id_banco, agencia, agencia_dv, conta, conta_dv, carteira, ativo)
    VALUES (v_id_cedente, 8, '1234', '0', '12345678', '9', '01', 'S');

    -- BRB (070)
    INSERT INTO boleto_contas (id_cedente, id_banco, agencia, agencia_dv, conta, conta_dv, carteira, ativo)
    VALUES (v_id_cedente, 9, '1234', '0', '1234567', '8', '01', 'S');

    -- Sicoob (756)
    INSERT INTO boleto_contas (id_cedente, id_banco, agencia, agencia_dv, conta, conta_dv, carteira, ativo)
    VALUES (v_id_cedente, 10, '1234', '0', '12345678', '9', '1', 'S');

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Contas bancárias criadas para todos os 10 bancos!');
END;
/

SELECT
    bc.id_conta,
    bb.codigo_banco,
    bb.nome_banco,
    bc.agencia || '-' || bc.agencia_dv AS agencia,
    bc.conta || '-' || bc.conta_dv AS conta,
    bc.carteira
FROM boleto_contas bc
JOIN boleto_bancos bb ON bc.id_banco = bb.id_banco
ORDER BY bb.codigo_banco;

PROMPT
PROMPT =========================================================
PROMPT [3/6] Gerando Boletos Individuais (1 por banco)
PROMPT =========================================================

DECLARE
    v_id_cedente NUMBER;
    v_id_sacado NUMBER;
    v_id_conta NUMBER;
    v_id_boleto NUMBER;
    v_contador NUMBER := 0;
    v_codigo_banco VARCHAR2(3);
    v_nome_banco VARCHAR2(100);

    CURSOR c_contas IS
        SELECT bc.id_conta, bb.codigo_banco, bb.nome_banco
        FROM boleto_contas bc
        JOIN boleto_bancos bb ON bc.id_banco = bb.id_banco
        WHERE bc.ativo = 'S'
        ORDER BY bb.codigo_banco;
BEGIN
    -- Buscar IDs
    SELECT id_cedente INTO v_id_cedente FROM boleto_cedentes WHERE documento = '12.345.678/0001-90';
    SELECT id_sacado INTO v_id_sacado FROM boleto_sacados WHERE documento = '987.654.321-00';

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Gerando boletos individuais...');
    DBMS_OUTPUT.PUT_LINE('');

    FOR rec IN c_contas LOOP
        v_contador := v_contador + 1;

        v_id_boleto := pkg_boleto_manager.criar_boleto(
            p_id_conta => rec.id_conta,
            p_id_sacado => v_id_sacado,
            p_numero_documento => 'TESTE-' || rec.codigo_banco || '-001',
            p_nosso_numero => LPAD(v_contador, 10, '0'),
            p_data_documento => SYSDATE,
            p_data_vencimento => SYSDATE + 30,
            p_valor_documento => 1500.00,
            p_instrucoes => 'Não receber após o vencimento' || CHR(10) ||
                           'Multa de 2% após o vencimento' || CHR(10) ||
                           'Juros de 1% ao mês',
            p_demonstrativo => 'Referente a teste de boleto' || CHR(10) ||
                              'Banco: ' || rec.nome_banco || CHR(10) ||
                              'Período: Teste',
            p_especie_documento => 'DM',
            p_aceite => 'N'
        );

        DBMS_OUTPUT.PUT_LINE('[' || rec.codigo_banco || '] ' || RPAD(rec.nome_banco, 30) ||
                           ' - Boleto ID: ' || LPAD(v_id_boleto, 5) ||
                           ' - Doc: TESTE-' || rec.codigo_banco || '-001');
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Total de boletos individuais gerados: ' || v_contador);
END;
/

PROMPT
PROMPT =========================================================
PROMPT [4/6] Gerando Carnês de 10 Parcelas (1 carnê por banco)
PROMPT =========================================================

DECLARE
    v_id_cedente NUMBER;
    v_id_sacado NUMBER;
    v_id_boleto NUMBER;
    v_total NUMBER := 0;
    v_parcela NUMBER;

    CURSOR c_contas IS
        SELECT bc.id_conta, bb.codigo_banco, bb.nome_banco
        FROM boleto_contas bc
        JOIN boleto_bancos bb ON bc.id_banco = bb.id_banco
        WHERE bc.ativo = 'S'
        ORDER BY bb.codigo_banco;
BEGIN
    SELECT id_cedente INTO v_id_cedente FROM boleto_cedentes WHERE documento = '12.345.678/0001-90';
    SELECT id_sacado INTO v_id_sacado FROM boleto_sacados WHERE documento = '987.654.321-00';

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Gerando carnês com 10 parcelas para cada banco...');
    DBMS_OUTPUT.PUT_LINE('');

    FOR rec IN c_contas LOOP
        DBMS_OUTPUT.PUT_LINE('[' || rec.codigo_banco || '] ' || rec.nome_banco || ':');

        FOR v_parcela IN 1..10 LOOP
            v_id_boleto := pkg_boleto_manager.criar_boleto(
                p_id_conta => rec.id_conta,
                p_id_sacado => v_id_sacado,
                p_numero_documento => 'TESTE-' || rec.codigo_banco || '-CARNE-' || LPAD(v_parcela, 2, '0'),
                p_nosso_numero => LPAD((v_total + v_parcela), 10, '0'),
                p_data_documento => SYSDATE,
                p_data_vencimento => ADD_MONTHS(SYSDATE, v_parcela),
                p_valor_documento => 500.00,
                p_instrucoes => 'Carnê - Parcela ' || v_parcela || '/10' || CHR(10) ||
                               'Não receber após o vencimento',
                p_demonstrativo => 'Carnê de teste - Banco ' || rec.nome_banco || CHR(10) ||
                                  'Parcela ' || v_parcela || ' de 10' || CHR(10) ||
                                  'Vencimento: ' || TO_CHAR(ADD_MONTHS(SYSDATE, v_parcela), 'DD/MM/YYYY'),
                p_especie_documento => 'DM',
                p_aceite => 'N'
            );

            v_total := v_total + 1;
        END LOOP;

        DBMS_OUTPUT.PUT_LINE('  ✓ 10 parcelas geradas (IDs: ' || (v_total - 9) || ' a ' || v_total || ')');
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Total de parcelas de carnê geradas: ' || v_total);
END;
/

PROMPT
PROMPT =========================================================
PROMPT [5/6] Validando Códigos de Barras Gerados
PROMPT =========================================================

SELECT
    bb.codigo_banco,
    bb.nome_banco,
    COUNT(*) AS total_boletos,
    COUNT(DISTINCT b.codigo_barras) AS codigos_unicos,
    MIN(LENGTH(b.codigo_barras)) AS tam_min,
    MAX(LENGTH(b.codigo_barras)) AS tam_max,
    COUNT(CASE WHEN b.codigo_barras IS NOT NULL THEN 1 END) AS com_codigo,
    COUNT(CASE WHEN b.linha_digitavel IS NOT NULL THEN 1 END) AS com_linha_digitavel
FROM boletos b
JOIN boleto_contas bc ON b.id_conta = bc.id_conta
JOIN boleto_bancos bb ON bc.id_banco = bb.id_banco
WHERE b.numero_documento LIKE 'TESTE-%'
GROUP BY bb.codigo_banco, bb.nome_banco
ORDER BY bb.codigo_banco;

PROMPT
PROMPT =========================================================
PROMPT [6/6] Resumo Final
PROMPT =========================================================

SELECT 'Total de Boletos Gerados' AS metrica, COUNT(*) AS valor
FROM boletos
WHERE numero_documento LIKE 'TESTE-%'
UNION ALL
SELECT 'Boletos Individuais', COUNT(*)
FROM boletos
WHERE numero_documento LIKE 'TESTE-%-001'
UNION ALL
SELECT 'Parcelas de Carnê', COUNT(*)
FROM boletos
WHERE numero_documento LIKE 'TESTE-%-CARNE-%'
UNION ALL
SELECT 'Com Código de Barras', COUNT(*)
FROM boletos
WHERE numero_documento LIKE 'TESTE-%'
  AND codigo_barras IS NOT NULL
UNION ALL
SELECT 'Com Linha Digitável', COUNT(*)
FROM boletos
WHERE numero_documento LIKE 'TESTE-%'
  AND linha_digitavel IS NOT NULL
UNION ALL
SELECT 'Com HTML Gerado', COUNT(*)
FROM boletos
WHERE numero_documento LIKE 'TESTE-%'
  AND conteudo_html IS NOT NULL;

PROMPT
PROMPT =========================================================
PROMPT Exemplos de Códigos de Barras por Banco
PROMPT =========================================================

SELECT
    bb.codigo_banco,
    RPAD(bb.nome_banco, 25) AS banco,
    b.numero_documento,
    b.codigo_barras,
    b.linha_digitavel
FROM (
    SELECT
        bc.id_banco,
        b.numero_documento,
        b.codigo_barras,
        b.linha_digitavel,
        ROW_NUMBER() OVER (PARTITION BY bc.id_banco ORDER BY b.id_boleto) AS rn
    FROM boletos b
    JOIN boleto_contas bc ON b.id_conta = bc.id_conta
    WHERE b.numero_documento LIKE 'TESTE-%-001'
) b
JOIN boleto_bancos bb ON b.id_banco = bb.id_banco
WHERE b.rn = 1
ORDER BY bb.codigo_banco;

PROMPT
PROMPT =========================================================
PROMPT Consultas Úteis para Verificação
PROMPT =========================================================
PROMPT
PROMPT -- Boletos por banco:
PROMPT SELECT bb.codigo_banco, bb.nome_banco, COUNT(*) AS total
PROMPT FROM boletos b
PROMPT JOIN boleto_contas bc ON b.id_conta = bc.id_conta
PROMPT JOIN boleto_bancos bb ON bc.id_banco = bb.id_banco
PROMPT WHERE b.numero_documento LIKE 'TESTE-%'
PROMPT GROUP BY bb.codigo_banco, bb.nome_banco
PROMPT ORDER BY bb.codigo_banco;
PROMPT
PROMPT -- Visualizar HTML de um boleto:
PROMPT SELECT conteudo_html FROM boletos WHERE id_boleto = 1;
PROMPT
PROMPT -- Gerar PDF de um boleto:
PROMPT DECLARE
PROMPT   v_pdf BLOB;
PROMPT BEGIN
PROMPT   v_pdf := pkg_boleto_pdf.gerar_pdf(1);
PROMPT   pkg_boleto_pdf.salvar_pdf_boleto(1, v_pdf);
PROMPT END;
PROMPT /
PROMPT
PROMPT -- Gerar carnê em PDF (banco específico):
PROMPT DECLARE
PROMPT   v_ids VARCHAR2(1000);
PROMPT   v_pdf BLOB;
PROMPT BEGIN
PROMPT   SELECT LISTAGG(id_boleto, ',') WITHIN GROUP (ORDER BY id_boleto)
PROMPT   INTO v_ids
PROMPT   FROM boletos WHERE numero_documento LIKE 'TESTE-001-CARNE-%';
PROMPT
PROMPT   v_pdf := pkg_boleto_pdf.gerar_pdf_carne(v_ids);
PROMPT END;
PROMPT /
PROMPT
PROMPT =========================================================
PROMPT TESTE COMPLETO FINALIZADO COM SUCESSO!
PROMPT =========================================================
PROMPT
PROMPT Próximos passos:
PROMPT 1. Validar visualmente os HTMLs gerados
PROMPT 2. Gerar PDFs de teste
PROMPT 3. Comparar códigos de barras com pyboleto original
PROMPT 4. Testar integração com API REST
PROMPT
PROMPT Para limpar dados de teste:
PROMPT   DELETE FROM boleto_historico WHERE id_boleto IN
PROMPT     (SELECT id_boleto FROM boletos WHERE numero_documento LIKE 'TESTE-%');
PROMPT   DELETE FROM boletos WHERE numero_documento LIKE 'TESTE-%';
PROMPT   COMMIT;
PROMPT
PROMPT =========================================================
