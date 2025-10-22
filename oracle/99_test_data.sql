-- ============================================================================
-- Script de Dados de Teste - Sistema de Boletos
-- ============================================================================

PROMPT
PROMPT =========================================================
PROMPT Criando Dados de Teste...
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
    'Empresa ACME LTDA',
    '12.345.678/0001-90',
    'CNPJ',
    'Rua das Flores, 123',
    'Centro',
    'São Paulo',
    'SP',
    '01234-567',
    'Rua das Flores, 123 - Centro - São Paulo - SP - CEP 01234-567'
);

PROMPT Cedente criado: Empresa ACME LTDA

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
    'João da Silva',
    '123.456.789-09',
    'CPF',
    'Avenida Paulista, 1000',
    'Bela Vista',
    'São Paulo',
    'SP',
    '01310-100',
    'Avenida Paulista, 1000 - Bela Vista - São Paulo - SP - CEP 01310-100'
);

PROMPT Sacado criado: João da Silva

-- Criar conta bancária de teste (Bradesco)
INSERT INTO boleto_contas (
    id_cedente,
    id_banco,
    agencia,
    agencia_dv,
    conta,
    conta_dv,
    carteira,
    convenio,
    ativo
) VALUES (
    1, -- Empresa ACME
    2, -- Bradesco
    '0278',
    '0',
    '0039232',
    '4',
    '06',
    NULL,
    'S'
);

PROMPT Conta bancária criada: Bradesco Ag: 0278-0 Cc: 0039232-4

-- Criar boleto de teste
DECLARE
    v_id_boleto NUMBER;
    v_calculo pkg_boleto_barcode.t_boleto_calculado;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Criando boleto de teste...');

    v_id_boleto := pkg_boleto_manager.criar_boleto(
        p_id_conta => 1,
        p_id_sacado => 1,
        p_numero_documento => 'DOC-00001',
        p_nosso_numero => '2125525',
        p_data_documento => TO_DATE('15/01/2024', 'DD/MM/YYYY'),
        p_data_vencimento => TO_DATE('15/02/2024', 'DD/MM/YYYY'),
        p_valor_documento => 1500.00,
        p_instrucoes => 'Não receber após o vencimento' || CHR(10) ||
                       'Multa de 2% após o vencimento' || CHR(10) ||
                       'Juros de 1% ao mês',
        p_demonstrativo => 'Referente ao serviço de consultoria' || CHR(10) ||
                          'Período: Janeiro/2024' || CHR(10) ||
                          'Contrato: 12345',
        p_especie_documento => 'DM',
        p_aceite => 'N'
    );

    DBMS_OUTPUT.PUT_LINE('Boleto criado com ID: ' || v_id_boleto);

    -- Buscar dados do boleto
    SELECT
        codigo_barras,
        linha_digitavel,
        dv_codigo_barras,
        campo_livre
    INTO
        v_calculo.codigo_barras,
        v_calculo.linha_digitavel_formatada,
        v_calculo.dv_codigo_barras,
        v_calculo.campo_livre
    FROM boletos
    WHERE id_boleto = v_id_boleto;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== DADOS DO BOLETO ===');
    DBMS_OUTPUT.PUT_LINE('Número do Documento: DOC-00001');
    DBMS_OUTPUT.PUT_LINE('Nosso Número: 2125525');
    DBMS_OUTPUT.PUT_LINE('Valor: R$ 1.500,00');
    DBMS_OUTPUT.PUT_LINE('Vencimento: 15/02/2024');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Código de Barras: ' || v_calculo.codigo_barras);
    DBMS_OUTPUT.PUT_LINE('Linha Digitável: ' || v_calculo.linha_digitavel_formatada);
    DBMS_OUTPUT.PUT_LINE('DV: ' || v_calculo.dv_codigo_barras);
    DBMS_OUTPUT.PUT_LINE('Campo Livre: ' || v_calculo.campo_livre);
    DBMS_OUTPUT.PUT_LINE('');
END;
/

COMMIT;

PROMPT
PROMPT =========================================================
PROMPT Dados de Teste Criados com Sucesso!
PROMPT =========================================================
PROMPT
PROMPT Resumo:
PROMPT - 1 Cedente: Empresa ACME LTDA
PROMPT - 1 Sacado: João da Silva
PROMPT - 1 Conta: Bradesco 0278-0 / 0039232-4
PROMPT - 1 Boleto: DOC-00001 (R$ 1.500,00)
PROMPT
PROMPT Consultar boleto:
PROMPT   SELECT * FROM boletos WHERE id_boleto = 1;
PROMPT
PROMPT Gerar HTML:
PROMPT   SELECT pkg_boleto_html.gerar_html(1) FROM dual;
PROMPT
PROMPT Consultar via API REST:
PROMPT   curl http://localhost:8080/ords/<schema>/api/v1/boletos/1
PROMPT
PROMPT =========================================================

-- Exemplos de consultas
PROMPT
PROMPT === EXEMPLOS DE CONSULTAS ===
PROMPT

-- Listar todos os boletos
PROMPT Todos os boletos:
SELECT
    b.id_boleto,
    b.numero_documento,
    b.nosso_numero,
    TO_CHAR(b.data_vencimento, 'DD/MM/YYYY') AS vencimento,
    TO_CHAR(b.valor_documento, 'FM999G999G999D00') AS valor,
    b.status,
    bb.nome_banco AS banco
FROM boletos b
JOIN boleto_contas bc ON b.id_conta = bc.id_conta
JOIN boleto_bancos bb ON bc.id_banco = bb.id_banco;

PROMPT
PROMPT === EXEMPLOS DE USO PL/SQL ===
PROMPT
PROMPT -- Criar novo boleto:
PROMPT DECLARE
PROMPT     v_id NUMBER;
PROMPT BEGIN
PROMPT     v_id := pkg_boleto_manager.criar_boleto(
PROMPT         p_id_conta => 1,
PROMPT         p_id_sacado => 1,
PROMPT         p_numero_documento => 'DOC-00002',
PROMPT         p_nosso_numero => '2125526',
PROMPT         p_data_documento => SYSDATE,
PROMPT         p_data_vencimento => SYSDATE + 30,
PROMPT         p_valor_documento => 2000.00
PROMPT     );
PROMPT     DBMS_OUTPUT.PUT_LINE('Boleto ID: ' || v_id);
PROMPT END;
PROMPT /
PROMPT
PROMPT -- Consultar boleto JSON:
PROMPT SELECT pkg_boleto_manager.consultar_boleto(1) FROM dual;
PROMPT
PROMPT -- Gerar HTML:
PROMPT SELECT pkg_boleto_html.gerar_html(1) FROM dual;
PROMPT
PROMPT -- Registrar pagamento:
PROMPT BEGIN
PROMPT     pkg_boleto_manager.registrar_pagamento(
PROMPT         p_id_boleto => 1,
PROMPT         p_data_pagamento => SYSDATE,
PROMPT         p_valor_pago => 1500.00
PROMPT     );
PROMPT END;
PROMPT /
PROMPT
PROMPT =========================================================
