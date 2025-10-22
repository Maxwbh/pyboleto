-- ============================================================================
-- Packages para Bancos Faltantes
-- HSBC (399), Banco Real (356), Banrisul (041), BRB (070)
-- ============================================================================

PROMPT =========================================================
PROMPT Criando packages para bancos faltantes...
PROMPT =========================================================

-- ============================================================================
-- PKG_BANCO_399_HSBC
-- ============================================================================
CREATE OR REPLACE PACKAGE pkg_banco_399_hsbc AS
    C_CODIGO_BANCO CONSTANT VARCHAR2(3) := '399';
    C_NOME_BANCO CONSTANT VARCHAR2(100) := 'HSBC';

    -- Calcular data juliana (YDDD)
    FUNCTION calcular_data_juliana(p_data IN DATE) RETURN VARCHAR2;

    FUNCTION gerar_codigo_barras(
        p_nosso_numero IN VARCHAR2,
        p_agencia IN VARCHAR2,
        p_conta IN VARCHAR2,
        p_data_vencimento IN DATE,
        p_valor IN NUMBER
    ) RETURN pkg_boleto_barcode.t_boleto_calculado;
END;
/

CREATE OR REPLACE PACKAGE BODY pkg_banco_399_hsbc AS

    FUNCTION calcular_data_juliana(p_data IN DATE) RETURN VARCHAR2 IS
        v_ano_ultimo_digito VARCHAR2(1);
        v_dia_do_ano VARCHAR2(3);
    BEGIN
        -- Y = último dígito do ano
        v_ano_ultimo_digito := SUBSTR(TO_CHAR(p_data, 'YYYY'), 4, 1);
        -- DDD = dia do ano (001-366)
        v_dia_do_ano := LPAD(TO_CHAR(p_data, 'DDD'), 3, '0');

        RETURN v_ano_ultimo_digito || v_dia_do_ano;
    END calcular_data_juliana;

    FUNCTION gerar_codigo_barras(
        p_nosso_numero IN VARCHAR2,
        p_agencia IN VARCHAR2,
        p_conta IN VARCHAR2,
        p_data_vencimento IN DATE,
        p_valor IN NUMBER
    ) RETURN pkg_boleto_barcode.t_boleto_calculado IS
        v_result pkg_boleto_barcode.t_boleto_calculado;
        v_data_juliana VARCHAR2(4);
    BEGIN
        -- Calcula data juliana
        v_data_juliana := calcular_data_juliana(p_data_vencimento);

        -- Campo livre: NNNNNNNNNNNNN AAAA CCCCCCC DJ
        -- Nosso número (13) + Agência (4) + Conta (7) + Data Juliana (4) = 28 -> 25
        v_result.campo_livre := pkg_boleto_utils.lpad_zero(p_nosso_numero, 13) ||
                               pkg_boleto_utils.lpad_zero(p_agencia, 4) ||
                               pkg_boleto_utils.lpad_zero(p_conta, 7) ||
                               '0'; -- Ajuste para 25 posições

        -- Gerar código completo
        DECLARE
            v_codigo_temp VARCHAR2(43);
            v_dv VARCHAR2(1);
        BEGIN
            v_codigo_temp := '3999' ||
                            pkg_boleto_utils.fator_vencimento(p_data_vencimento) ||
                            pkg_boleto_utils.formata_valor(p_valor, 10) ||
                            v_result.campo_livre;

            v_dv := TO_CHAR(pkg_boleto_utils.modulo11(v_codigo_temp, 9, 1));
            v_result.codigo_barras := SUBSTR(v_codigo_temp, 1, 4) || v_dv || SUBSTR(v_codigo_temp, 5);
            v_result.dv_codigo_barras := v_dv;
        END;

        v_result.linha_digitavel := pkg_boleto_utils.linha_digitavel(v_result.codigo_barras);
        v_result.linha_digitavel_formatada := pkg_boleto_utils.formata_linha_digitavel(v_result.linha_digitavel);

        RETURN v_result;
    END;
END;
/

-- ============================================================================
-- PKG_BANCO_356_REAL
-- ============================================================================
CREATE OR REPLACE PACKAGE pkg_banco_356_real AS
    C_CODIGO_BANCO CONSTANT VARCHAR2(3) := '356';
    C_NOME_BANCO CONSTANT VARCHAR2(100) := 'Banco Real';

    FUNCTION gerar_codigo_barras(
        p_agencia IN VARCHAR2,
        p_conta IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_valor IN NUMBER,
        p_data_vencimento IN DATE
    ) RETURN pkg_boleto_barcode.t_boleto_calculado;
END;
/

CREATE OR REPLACE PACKAGE BODY pkg_banco_356_real AS

    FUNCTION gerar_codigo_barras(
        p_agencia IN VARCHAR2,
        p_conta IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_valor IN NUMBER,
        p_data_vencimento IN DATE
    ) RETURN pkg_boleto_barcode.t_boleto_calculado IS
        v_result pkg_boleto_barcode.t_boleto_calculado;
        v_dv NUMBER;
    BEGIN
        -- Banco Real usa formato similar ao Santander
        -- Campo livre: AAAA CCCCCCCC NNNNNNNNNNN DD
        v_dv := pkg_boleto_utils.modulo11(p_nosso_numero, 9, 0);

        v_result.campo_livre := pkg_boleto_utils.lpad_zero(p_agencia, 4) ||
                               pkg_boleto_utils.lpad_zero(p_conta, 8) ||
                               pkg_boleto_utils.lpad_zero(p_nosso_numero, 11) ||
                               TO_CHAR(v_dv) ||
                               '0';

        -- Gerar código completo
        DECLARE
            v_codigo_temp VARCHAR2(43);
            v_dv_barras VARCHAR2(1);
        BEGIN
            v_codigo_temp := '3569' ||
                            pkg_boleto_utils.fator_vencimento(p_data_vencimento) ||
                            pkg_boleto_utils.formata_valor(p_valor, 10) ||
                            v_result.campo_livre;

            v_dv_barras := TO_CHAR(pkg_boleto_utils.modulo11(v_codigo_temp, 9, 1));
            v_result.codigo_barras := SUBSTR(v_codigo_temp, 1, 4) || v_dv_barras || SUBSTR(v_codigo_temp, 5);
            v_result.dv_codigo_barras := v_dv_barras;
        END;

        v_result.linha_digitavel := pkg_boleto_utils.linha_digitavel(v_result.codigo_barras);
        v_result.linha_digitavel_formatada := pkg_boleto_utils.formata_linha_digitavel(v_result.linha_digitavel);

        RETURN v_result;
    END;
END;
/

-- ============================================================================
-- PKG_BANCO_041_BANRISUL
-- ============================================================================
CREATE OR REPLACE PACKAGE pkg_banco_041_banrisul AS
    C_CODIGO_BANCO CONSTANT VARCHAR2(3) := '041';
    C_NOME_BANCO CONSTANT VARCHAR2(100) := 'Banrisul';

    FUNCTION gerar_codigo_barras(
        p_agencia IN VARCHAR2,
        p_conta IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_valor IN NUMBER,
        p_data_vencimento IN DATE
    ) RETURN pkg_boleto_barcode.t_boleto_calculado;
END;
/

CREATE OR REPLACE PACKAGE BODY pkg_banco_041_banrisul AS

    FUNCTION gerar_codigo_barras(
        p_agencia IN VARCHAR2,
        p_conta IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_valor IN NUMBER,
        p_data_vencimento IN DATE
    ) RETURN pkg_boleto_barcode.t_boleto_calculado IS
        v_result pkg_boleto_barcode.t_boleto_calculado;
        v_campo_temp VARCHAR2(24);
        v_dv1 NUMBER;
    BEGIN
        -- Campo livre Banrisul: 21 AAAA NNNNNNNN D CCCCCCCC 40
        v_campo_temp := '21' ||
                       pkg_boleto_utils.lpad_zero(p_agencia, 4) ||
                       pkg_boleto_utils.lpad_zero(p_nosso_numero, 8);

        v_dv1 := pkg_boleto_utils.modulo10(v_campo_temp);

        v_result.campo_livre := v_campo_temp ||
                               TO_CHAR(v_dv1) ||
                               pkg_boleto_utils.lpad_zero(p_conta, 8) ||
                               '40';

        -- Gerar código completo
        DECLARE
            v_codigo_temp VARCHAR2(43);
            v_dv VARCHAR2(1);
        BEGIN
            v_codigo_temp := '0419' ||
                            pkg_boleto_utils.fator_vencimento(p_data_vencimento) ||
                            pkg_boleto_utils.formata_valor(p_valor, 10) ||
                            v_result.campo_livre;

            v_dv := TO_CHAR(pkg_boleto_utils.modulo11(v_codigo_temp, 9, 1));
            v_result.codigo_barras := SUBSTR(v_codigo_temp, 1, 4) || v_dv || SUBSTR(v_codigo_temp, 5);
            v_result.dv_codigo_barras := v_dv;
        END;

        v_result.linha_digitavel := pkg_boleto_utils.linha_digitavel(v_result.codigo_barras);
        v_result.linha_digitavel_formatada := pkg_boleto_utils.formata_linha_digitavel(v_result.linha_digitavel);

        RETURN v_result;
    END;
END;
/

-- ============================================================================
-- PKG_BANCO_070_BRB
-- ============================================================================
CREATE OR REPLACE PACKAGE pkg_banco_070_brb AS
    C_CODIGO_BANCO CONSTANT VARCHAR2(3) := '070';
    C_NOME_BANCO CONSTANT VARCHAR2(100) := 'BRB - Banco de Brasília';

    FUNCTION gerar_codigo_barras(
        p_agencia IN VARCHAR2,
        p_carteira IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_conta IN VARCHAR2,
        p_valor IN NUMBER,
        p_data_vencimento IN DATE
    ) RETURN pkg_boleto_barcode.t_boleto_calculado;
END;
/

CREATE OR REPLACE PACKAGE BODY pkg_banco_070_brb AS

    FUNCTION gerar_codigo_barras(
        p_agencia IN VARCHAR2,
        p_carteira IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_conta IN VARCHAR2,
        p_valor IN NUMBER,
        p_data_vencimento IN DATE
    ) RETURN pkg_boleto_barcode.t_boleto_calculado IS
        v_result pkg_boleto_barcode.t_boleto_calculado;
    BEGIN
        -- Campo livre BRB: AAAA CC NNNNNNN CCCCCCC 000000
        v_result.campo_livre := pkg_boleto_utils.lpad_zero(p_agencia, 4) ||
                               pkg_boleto_utils.lpad_zero(p_carteira, 2) ||
                               pkg_boleto_utils.lpad_zero(p_nosso_numero, 7) ||
                               pkg_boleto_utils.lpad_zero(p_conta, 7) ||
                               '00000';

        -- Gerar código completo
        DECLARE
            v_codigo_temp VARCHAR2(43);
            v_dv VARCHAR2(1);
        BEGIN
            v_codigo_temp := '0709' ||
                            pkg_boleto_utils.fator_vencimento(p_data_vencimento) ||
                            pkg_boleto_utils.formata_valor(p_valor, 10) ||
                            v_result.campo_livre;

            v_dv := TO_CHAR(pkg_boleto_utils.modulo11(v_codigo_temp, 9, 1));
            v_result.codigo_barras := SUBSTR(v_codigo_temp, 1, 4) || v_dv || SUBSTR(v_codigo_temp, 5);
            v_result.dv_codigo_barras := v_dv;
        END;

        v_result.linha_digitavel := pkg_boleto_utils.linha_digitavel(v_result.codigo_barras);
        v_result.linha_digitavel_formatada := pkg_boleto_utils.formata_linha_digitavel(v_result.linha_digitavel);

        RETURN v_result;
    END;
END;
/

PROMPT
PROMPT =========================================================
PROMPT Packages dos bancos faltantes criados!
PROMPT =========================================================
PROMPT
PROMPT Bancos completos com packages:
SELECT object_name, status
FROM user_objects
WHERE object_type = 'PACKAGE'
  AND object_name LIKE 'PKG_BANCO_%'
ORDER BY object_name;

PROMPT
PROMPT Total de bancos implementados: 10
PROMPT - 001: Banco do Brasil
PROMPT - 237: Bradesco
PROMPT - 104: Caixa
PROMPT - 341: Itaú
PROMPT - 033: Santander
PROMPT - 756: Sicoob
PROMPT - 399: HSBC
PROMPT - 356: Banco Real
PROMPT - 041: Banrisul
PROMPT - 070: BRB
PROMPT
PROMPT =========================================================
