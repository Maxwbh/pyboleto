-- ============================================================================
-- Packages Complementares para outros Bancos
-- Caixa (104), Itaú (341), Santander (033), HSBC (399), Banrisul (041)
-- BRB (070), Real (356), Sicoob (756)
-- ============================================================================

PROMPT =========================================================
PROMPT Criando packages para bancos complementares...
PROMPT =========================================================

-- ============================================================================
-- PKG_BANCO_104_CAIXA
-- ============================================================================
CREATE OR REPLACE PACKAGE pkg_banco_104_caixa AS
    C_CODIGO_BANCO CONSTANT VARCHAR2(3) := '104';
    C_NOME_BANCO CONSTANT VARCHAR2(100) := 'Caixa Econômica Federal';

    FUNCTION gerar_codigo_barras(
        p_nosso_numero IN VARCHAR2,
        p_agencia IN VARCHAR2,
        p_modalidade IN VARCHAR2,
        p_conta IN VARCHAR2,
        p_valor IN NUMBER,
        p_data_vencimento IN DATE
    ) RETURN pkg_boleto_barcode.t_boleto_calculado;
END;
/

CREATE OR REPLACE PACKAGE BODY pkg_banco_104_caixa AS
    FUNCTION gerar_codigo_barras(
        p_nosso_numero IN VARCHAR2,
        p_agencia IN VARCHAR2,
        p_modalidade IN VARCHAR2,
        p_conta IN VARCHAR2,
        p_valor IN NUMBER,
        p_data_vencimento IN DATE
    ) RETURN pkg_boleto_barcode.t_boleto_calculado IS
        v_result pkg_boleto_barcode.t_boleto_calculado;
        v_campo_livre VARCHAR2(25);
    BEGIN
        -- Campo livre: NNNNNNNNNNNNNN AAAA MM CCCCCCCC D
        v_campo_livre := pkg_boleto_utils.lpad_zero(p_nosso_numero, 14) ||
                        pkg_boleto_utils.lpad_zero(p_agencia, 4) ||
                        pkg_boleto_utils.lpad_zero(p_modalidade, 2) ||
                        pkg_boleto_utils.lpad_zero(p_conta, 8);

        v_campo_livre := v_campo_livre ||
                        TO_CHAR(pkg_boleto_utils.modulo11(v_campo_livre, 9, 0));

        v_result.campo_livre := SUBSTR(v_campo_livre, 1, 25);

        -- Gerar código completo
        DECLARE
            v_codigo_temp VARCHAR2(43);
            v_dv VARCHAR2(1);
        BEGIN
            v_codigo_temp := '1049' ||
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
-- PKG_BANCO_341_ITAU
-- ============================================================================
CREATE OR REPLACE PACKAGE pkg_banco_341_itau AS
    C_CODIGO_BANCO CONSTANT VARCHAR2(3) := '341';
    C_NOME_BANCO CONSTANT VARCHAR2(100) := 'Itaú';

    FUNCTION gerar_codigo_barras(
        p_agencia IN VARCHAR2,
        p_conta IN VARCHAR2,
        p_carteira IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_valor IN NUMBER,
        p_data_vencimento IN DATE
    ) RETURN pkg_boleto_barcode.t_boleto_calculado;
END;
/

CREATE OR REPLACE PACKAGE BODY pkg_banco_341_itau AS
    FUNCTION gerar_codigo_barras(
        p_agencia IN VARCHAR2,
        p_conta IN VARCHAR2,
        p_carteira IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_valor IN NUMBER,
        p_data_vencimento IN DATE
    ) RETURN pkg_boleto_barcode.t_boleto_calculado IS
        v_result pkg_boleto_barcode.t_boleto_calculado;
        v_agencia_conta_nosso VARCHAR2(20);
        v_dv NUMBER;
    BEGIN
        -- Calcular DV da agência/conta/carteira/nosso número
        v_agencia_conta_nosso := pkg_boleto_utils.lpad_zero(p_agencia, 4) ||
                                pkg_boleto_utils.lpad_zero(p_conta, 5) ||
                                pkg_boleto_utils.lpad_zero(p_carteira, 3) ||
                                pkg_boleto_utils.lpad_zero(p_nosso_numero, 8);

        v_dv := pkg_boleto_utils.modulo10(v_agencia_conta_nosso);

        -- Campo livre: CCC NNNNNNNNN D AAAA CCCCC DDD
        v_result.campo_livre := pkg_boleto_utils.lpad_zero(p_carteira, 3) ||
                               pkg_boleto_utils.lpad_zero(p_nosso_numero, 8) ||
                               TO_CHAR(v_dv) ||
                               pkg_boleto_utils.lpad_zero(p_agencia, 4) ||
                               pkg_boleto_utils.lpad_zero(p_conta, 5) ||
                               '000';

        -- Gerar código completo
        DECLARE
            v_codigo_temp VARCHAR2(43);
            v_dv_barras VARCHAR2(1);
        BEGIN
            v_codigo_temp := '3419' ||
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
-- PKG_BANCO_033_SANTANDER
-- ============================================================================
CREATE OR REPLACE PACKAGE pkg_banco_033_santander AS
    C_CODIGO_BANCO CONSTANT VARCHAR2(3) := '033';
    C_NOME_BANCO CONSTANT VARCHAR2(100) := 'Santander';

    FUNCTION gerar_codigo_barras(
        p_nosso_numero IN VARCHAR2,
        p_ios IN VARCHAR2,
        p_carteira IN VARCHAR2,
        p_valor IN NUMBER,
        p_data_vencimento IN DATE
    ) RETURN pkg_boleto_barcode.t_boleto_calculado;
END;
/

CREATE OR REPLACE PACKAGE BODY pkg_banco_033_santander AS
    FUNCTION gerar_codigo_barras(
        p_nosso_numero IN VARCHAR2,
        p_ios IN VARCHAR2,
        p_carteira IN VARCHAR2,
        p_valor IN NUMBER,
        p_data_vencimento IN DATE
    ) RETURN pkg_boleto_barcode.t_boleto_calculado IS
        v_result pkg_boleto_barcode.t_boleto_calculado;
        v_dv NUMBER;
    BEGIN
        v_dv := pkg_boleto_utils.modulo11(p_nosso_numero, 9, 0);

        -- Campo livre: 9 NNNNNNN DDDDDDD C D 0000000
        v_result.campo_livre := '9' ||
                               pkg_boleto_utils.lpad_zero(p_nosso_numero, 7) ||
                               pkg_boleto_utils.lpad_zero(NVL(p_ios, '0'), 7) ||
                               pkg_boleto_utils.lpad_zero(p_carteira, 3) ||
                               TO_CHAR(v_dv) ||
                               '0000000';

        -- Gerar código completo
        DECLARE
            v_codigo_temp VARCHAR2(43);
            v_dv_barras VARCHAR2(1);
        BEGIN
            v_codigo_temp := '0339' ||
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
-- PKG_BANCO_756_SICOOB
-- ============================================================================
CREATE OR REPLACE PACKAGE pkg_banco_756_sicoob AS
    C_CODIGO_BANCO CONSTANT VARCHAR2(3) := '756';
    C_NOME_BANCO CONSTANT VARCHAR2(100) := 'Sicoob';

    FUNCTION gerar_codigo_barras(
        p_carteira IN VARCHAR2,
        p_agencia IN VARCHAR2,
        p_modalidade IN VARCHAR2,
        p_numero_cooperativa IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_valor IN NUMBER,
        p_data_vencimento IN DATE
    ) RETURN pkg_boleto_barcode.t_boleto_calculado;
END;
/

CREATE OR REPLACE PACKAGE BODY pkg_banco_756_sicoob AS
    FUNCTION gerar_codigo_barras(
        p_carteira IN VARCHAR2,
        p_agencia IN VARCHAR2,
        p_modalidade IN VARCHAR2,
        p_numero_cooperativa IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_valor IN NUMBER,
        p_data_vencimento IN DATE
    ) RETURN pkg_boleto_barcode.t_boleto_calculado IS
        v_result pkg_boleto_barcode.t_boleto_calculado;
        v_campo_temp VARCHAR2(24);
        v_dv NUMBER;
    BEGIN
        -- Campo livre: C AAAA MM CCCC NNNNNNNNNN D
        v_campo_temp := pkg_boleto_utils.lpad_zero(p_carteira, 1) ||
                       pkg_boleto_utils.lpad_zero(p_agencia, 4) ||
                       pkg_boleto_utils.lpad_zero(p_modalidade, 2) ||
                       pkg_boleto_utils.lpad_zero(p_numero_cooperativa, 7) ||
                       pkg_boleto_utils.lpad_zero(p_nosso_numero, 10);

        v_dv := pkg_boleto_utils.modulo11(v_campo_temp, 9, 0);
        v_result.campo_livre := v_campo_temp || TO_CHAR(v_dv);

        -- Gerar código completo
        DECLARE
            v_codigo_temp VARCHAR2(43);
            v_dv_barras VARCHAR2(1);
        BEGIN
            v_codigo_temp := '7569' ||
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

PROMPT
PROMPT =========================================================
PROMPT Packages dos bancos complementares criados com sucesso!
PROMPT =========================================================
PROMPT
PROMPT Bancos com packages específicos:
PROMPT - 001: Banco do Brasil (pkg_banco_001_bb)
PROMPT - 237: Bradesco (pkg_banco_237_bradesco)
PROMPT - 104: Caixa (pkg_banco_104_caixa)
PROMPT - 341: Itaú (pkg_banco_341_itau)
PROMPT - 033: Santander (pkg_banco_033_santander)
PROMPT - 756: Sicoob (pkg_banco_756_sicoob)
PROMPT
PROMPT Verificando packages:
SELECT object_name, status
FROM user_objects
WHERE object_type = 'PACKAGE'
  AND object_name LIKE 'PKG_BANCO_%'
ORDER BY object_name;

PROMPT
PROMPT =========================================================
