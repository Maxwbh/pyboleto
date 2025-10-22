-- ============================================================================
-- Atualização PKG_BOLETO_BARCODE - Incluir todos os 10 bancos
-- ============================================================================

PROMPT =========================================================
PROMPT Atualizando PKG_BOLETO_BARCODE com todos os bancos...
PROMPT =========================================================

CREATE OR REPLACE PACKAGE BODY pkg_boleto_barcode AS

    -- ========================================================================
    -- FUNCTION: gerar_codigo_barras
    -- Função principal que delega para package específico de cada banco
    -- TODOS OS 10 BANCOS IMPLEMENTADOS
    -- ========================================================================
    FUNCTION gerar_codigo_barras(
        p_id_boleto IN NUMBER
    ) RETURN t_boleto_calculado IS
        v_result t_boleto_calculado;
        v_codigo_banco VARCHAR2(3);

        -- Dados do boleto
        v_data_vencimento DATE;
        v_valor_documento NUMBER;
        v_agencia VARCHAR2(10);
        v_conta VARCHAR2(20);
        v_carteira VARCHAR2(10);
        v_convenio VARCHAR2(20);
        v_nosso_numero VARCHAR2(20);
        v_ios VARCHAR2(20);
    BEGIN
        -- Busca dados do boleto
        SELECT
            bb.codigo_banco,
            b.data_vencimento,
            b.valor_documento,
            bc.agencia,
            bc.conta,
            bc.carteira,
            bc.convenio,
            b.nosso_numero,
            b.ios
        INTO
            v_codigo_banco,
            v_data_vencimento,
            v_valor_documento,
            v_agencia,
            v_conta,
            v_carteira,
            v_convenio,
            v_nosso_numero,
            v_ios
        FROM boletos b
        JOIN boleto_contas bc ON b.id_conta = bc.id_conta
        JOIN boleto_bancos bb ON bc.id_banco = bb.id_banco
        WHERE b.id_boleto = p_id_boleto;

        -- Delegar para package específico do banco
        CASE v_codigo_banco
            WHEN '001' THEN -- Banco do Brasil
                v_result := pkg_banco_001_bb.gerar_codigo_barras(
                    p_convenio => v_convenio,
                    p_nosso_numero => v_nosso_numero,
                    p_agencia => v_agencia,
                    p_conta => v_conta,
                    p_carteira => v_carteira,
                    p_valor => v_valor_documento,
                    p_data_vencimento => v_data_vencimento
                );

            WHEN '237' THEN -- Bradesco
                v_result := pkg_banco_237_bradesco.gerar_codigo_barras(
                    p_agencia => v_agencia,
                    p_carteira => v_carteira,
                    p_nosso_numero => v_nosso_numero,
                    p_conta => v_conta,
                    p_valor => v_valor_documento,
                    p_data_vencimento => v_data_vencimento
                );

            WHEN '104' THEN -- Caixa
                v_result := pkg_banco_104_caixa.gerar_codigo_barras(
                    p_nosso_numero => v_nosso_numero,
                    p_agencia => v_agencia,
                    p_modalidade => NVL(v_carteira, '14'),
                    p_conta => v_conta,
                    p_valor => v_valor_documento,
                    p_data_vencimento => v_data_vencimento
                );

            WHEN '341' THEN -- Itaú
                v_result := pkg_banco_341_itau.gerar_codigo_barras(
                    p_agencia => v_agencia,
                    p_conta => v_conta,
                    p_carteira => v_carteira,
                    p_nosso_numero => v_nosso_numero,
                    p_valor => v_valor_documento,
                    p_data_vencimento => v_data_vencimento
                );

            WHEN '033' THEN -- Santander
                v_result := pkg_banco_033_santander.gerar_codigo_barras(
                    p_nosso_numero => v_nosso_numero,
                    p_ios => NVL(v_ios, '0'),
                    p_carteira => v_carteira,
                    p_valor => v_valor_documento,
                    p_data_vencimento => v_data_vencimento
                );

            WHEN '756' THEN -- Sicoob
                v_result := pkg_banco_756_sicoob.gerar_codigo_barras(
                    p_carteira => NVL(v_carteira, '1'),
                    p_agencia => v_agencia,
                    p_modalidade => '01',
                    p_numero_cooperativa => v_agencia,
                    p_nosso_numero => v_nosso_numero,
                    p_valor => v_valor_documento,
                    p_data_vencimento => v_data_vencimento
                );

            WHEN '399' THEN -- HSBC
                v_result := pkg_banco_399_hsbc.gerar_codigo_barras(
                    p_nosso_numero => v_nosso_numero,
                    p_agencia => v_agencia,
                    p_conta => v_conta,
                    p_data_vencimento => v_data_vencimento,
                    p_valor => v_valor_documento
                );

            WHEN '356' THEN -- Banco Real
                v_result := pkg_banco_356_real.gerar_codigo_barras(
                    p_agencia => v_agencia,
                    p_conta => v_conta,
                    p_nosso_numero => v_nosso_numero,
                    p_valor => v_valor_documento,
                    p_data_vencimento => v_data_vencimento
                );

            WHEN '041' THEN -- Banrisul
                v_result := pkg_banco_041_banrisul.gerar_codigo_barras(
                    p_agencia => v_agencia,
                    p_conta => v_conta,
                    p_nosso_numero => v_nosso_numero,
                    p_valor => v_valor_documento,
                    p_data_vencimento => v_data_vencimento
                );

            WHEN '070' THEN -- BRB
                v_result := pkg_banco_070_brb.gerar_codigo_barras(
                    p_agencia => v_agencia,
                    p_carteira => NVL(v_carteira, '01'),
                    p_nosso_numero => v_nosso_numero,
                    p_conta => v_conta,
                    p_valor => v_valor_documento,
                    p_data_vencimento => v_data_vencimento
                );

            ELSE
                RAISE_APPLICATION_ERROR(-20101,
                    'Banco ' || v_codigo_banco || ' não possui package específico implementado. ' ||
                    'Bancos disponíveis: 001, 237, 104, 341, 033, 756, 399, 356, 041, 070');
        END CASE;

        RETURN v_result;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20102, 'Boleto não encontrado: ' || p_id_boleto);
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20103, 'Erro ao gerar código de barras: ' || SQLERRM);
    END gerar_codigo_barras;

    -- Mantém funções originais para compatibilidade V1 (delegam para packages específicos)
    FUNCTION campo_livre_bb(p_convenio IN VARCHAR2, p_nosso_numero IN VARCHAR2, p_agencia IN VARCHAR2, p_conta IN VARCHAR2, p_carteira IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN pkg_banco_001_bb.calcular_campo_livre(p_convenio, p_nosso_numero, p_agencia, p_conta, p_carteira);
    END;

    FUNCTION campo_livre_bradesco(p_agencia IN VARCHAR2, p_carteira IN VARCHAR2, p_nosso_numero IN VARCHAR2, p_conta IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN pkg_banco_237_bradesco.calcular_campo_livre(p_agencia, p_carteira, p_nosso_numero, p_conta);
    END;

    FUNCTION campo_livre_caixa(p_nosso_numero IN VARCHAR2, p_agencia IN VARCHAR2, p_modalidade IN VARCHAR2, p_conta IN VARCHAR2) RETURN VARCHAR2 IS
        v_result t_boleto_calculado;
    BEGIN
        v_result := pkg_banco_104_caixa.gerar_codigo_barras(p_nosso_numero, p_agencia, p_modalidade, p_conta, 0, SYSDATE);
        RETURN v_result.campo_livre;
    END;

    FUNCTION campo_livre_itau(p_agencia IN VARCHAR2, p_conta IN VARCHAR2, p_carteira IN VARCHAR2, p_nosso_numero IN VARCHAR2) RETURN VARCHAR2 IS
        v_result t_boleto_calculado;
    BEGIN
        v_result := pkg_banco_341_itau.gerar_codigo_barras(p_agencia, p_conta, p_carteira, p_nosso_numero, 0, SYSDATE);
        RETURN v_result.campo_livre;
    END;

    FUNCTION campo_livre_santander(p_fixo IN VARCHAR2, p_nosso_numero IN VARCHAR2, p_ios IN VARCHAR2, p_carteira IN VARCHAR2) RETURN VARCHAR2 IS
        v_result t_boleto_calculado;
    BEGIN
        v_result := pkg_banco_033_santander.gerar_codigo_barras(p_nosso_numero, p_ios, p_carteira, 0, SYSDATE);
        RETURN v_result.campo_livre;
    END;

    FUNCTION campo_livre_hsbc(p_nosso_numero IN VARCHAR2, p_agencia IN VARCHAR2, p_conta IN VARCHAR2, p_data_vencimento IN DATE) RETURN VARCHAR2 IS
        v_result t_boleto_calculado;
    BEGIN
        v_result := pkg_banco_399_hsbc.gerar_codigo_barras(p_nosso_numero, p_agencia, p_conta, p_data_vencimento, 0);
        RETURN v_result.campo_livre;
    END;

    FUNCTION campo_livre_banrisul(p_livre IN VARCHAR2, p_agencia IN VARCHAR2, p_conta IN VARCHAR2, p_nosso_numero IN VARCHAR2) RETURN VARCHAR2 IS
        v_result t_boleto_calculado;
    BEGIN
        v_result := pkg_banco_041_banrisul.gerar_codigo_barras(p_agencia, p_conta, p_nosso_numero, 0, SYSDATE);
        RETURN v_result.campo_livre;
    END;

    FUNCTION campo_livre_brb(p_agencia IN VARCHAR2, p_carteira IN VARCHAR2, p_nosso_numero IN VARCHAR2, p_conta IN VARCHAR2) RETURN VARCHAR2 IS
        v_result t_boleto_calculado;
    BEGIN
        v_result := pkg_banco_070_brb.gerar_codigo_barras(p_agencia, p_carteira, p_nosso_numero, p_conta, 0, SYSDATE);
        RETURN v_result.campo_livre;
    END;

    FUNCTION campo_livre_sicoob(p_carteira IN VARCHAR2, p_agencia IN VARCHAR2, p_modalidade IN VARCHAR2, p_numero_cooperativa IN VARCHAR2, p_nosso_numero IN VARCHAR2) RETURN VARCHAR2 IS
        v_result t_boleto_calculado;
    BEGIN
        v_result := pkg_banco_756_sicoob.gerar_codigo_barras(p_carteira, p_agencia, p_modalidade, p_numero_cooperativa, p_nosso_numero, 0, SYSDATE);
        RETURN v_result.campo_livre;
    END;

END pkg_boleto_barcode;
/

PROMPT
PROMPT PKG_BOLETO_BARCODE atualizado com todos os 10 bancos!
PROMPT
PROMPT Bancos suportados:
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
PROMPT =========================================================
