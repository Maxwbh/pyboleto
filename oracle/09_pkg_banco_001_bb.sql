-- ============================================================================
-- Package: PKG_BANCO_001_BB
-- Banco do Brasil - Implementação específica
-- ============================================================================

CREATE OR REPLACE PACKAGE pkg_banco_001_bb AS

    -- Constantes do banco
    C_CODIGO_BANCO CONSTANT VARCHAR2(3) := '001';
    C_NOME_BANCO CONSTANT VARCHAR2(100) := 'Banco do Brasil';
    C_DIGITO_MOEDA CONSTANT VARCHAR2(1) := '9';

    -- Type para dados específicos do BB
    TYPE t_dados_bb IS RECORD (
        convenio VARCHAR2(20),
        convenio_digitos NUMBER,
        formato_convenio VARCHAR2(10), -- '6', '7', '8'
        variacao_carteira VARCHAR2(3),
        nosso_numero VARCHAR2(20),
        nosso_numero_dv VARCHAR2(1)
    );

    -- Validar dados específicos do BB
    FUNCTION validar_dados(
        p_convenio IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_carteira IN VARCHAR2
    ) RETURN BOOLEAN;

    -- Calcular dígito verificador do nosso número
    FUNCTION calcular_dv_nosso_numero(
        p_nosso_numero IN VARCHAR2,
        p_convenio IN VARCHAR2
    ) RETURN VARCHAR2;

    -- Formatar nosso número conforme padrão BB
    FUNCTION formatar_nosso_numero(
        p_nosso_numero IN VARCHAR2,
        p_convenio IN VARCHAR2
    ) RETURN VARCHAR2;

    -- Calcular campo livre (25 posições)
    FUNCTION calcular_campo_livre(
        p_convenio IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_agencia IN VARCHAR2,
        p_conta IN VARCHAR2,
        p_carteira IN VARCHAR2
    ) RETURN VARCHAR2;

    -- Gerar código de barras completo
    FUNCTION gerar_codigo_barras(
        p_convenio IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_agencia IN VARCHAR2,
        p_conta IN VARCHAR2,
        p_carteira IN VARCHAR2,
        p_valor IN NUMBER,
        p_data_vencimento IN DATE
    ) RETURN pkg_boleto_barcode.t_boleto_calculado;

END pkg_banco_001_bb;
/

CREATE OR REPLACE PACKAGE BODY pkg_banco_001_bb AS

    -- ========================================================================
    -- FUNCTION: validar_dados
    -- Valida se os dados estão corretos para o BB
    -- ========================================================================
    FUNCTION validar_dados(
        p_convenio IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_carteira IN VARCHAR2
    ) RETURN BOOLEAN IS
        v_convenio_len NUMBER := LENGTH(p_convenio);
    BEGIN
        -- Convênio deve ter 6, 7 ou 8 dígitos
        IF v_convenio_len NOT IN (6, 7, 8) THEN
            RETURN FALSE;
        END IF;

        -- Validar tamanho do nosso número conforme convênio
        IF v_convenio_len = 6 AND LENGTH(p_nosso_numero) > 5 THEN
            RETURN FALSE;
        ELSIF v_convenio_len = 7 AND LENGTH(p_nosso_numero) > 10 THEN
            RETURN FALSE;
        ELSIF v_convenio_len = 8 AND LENGTH(p_nosso_numero) > 9 THEN
            RETURN FALSE;
        END IF;

        RETURN TRUE;
    END validar_dados;

    -- ========================================================================
    -- FUNCTION: calcular_dv_nosso_numero
    -- Calcula DV do nosso número para BB
    -- ========================================================================
    FUNCTION calcular_dv_nosso_numero(
        p_nosso_numero IN VARCHAR2,
        p_convenio IN VARCHAR2
    ) RETURN VARCHAR2 IS
        v_numero VARCHAR2(50);
    BEGIN
        -- Para BB, o DV é calculado sobre convênio + nosso número
        v_numero := p_convenio || p_nosso_numero;
        RETURN TO_CHAR(pkg_boleto_utils.modulo11(v_numero, 9, 0));
    END calcular_dv_nosso_numero;

    -- ========================================================================
    -- FUNCTION: formatar_nosso_numero
    -- Formata nosso número conforme padrão BB
    -- ========================================================================
    FUNCTION formatar_nosso_numero(
        p_nosso_numero IN VARCHAR2,
        p_convenio IN VARCHAR2
    ) RETURN VARCHAR2 IS
        v_convenio_len NUMBER := LENGTH(p_convenio);
        v_tamanho_nn NUMBER;
    BEGIN
        -- Define tamanho do nosso número baseado no convênio
        IF v_convenio_len = 6 THEN
            v_tamanho_nn := 5;
        ELSIF v_convenio_len = 7 THEN
            v_tamanho_nn := 10;
        ELSIF v_convenio_len = 8 THEN
            v_tamanho_nn := 9;
        ELSE
            RAISE_APPLICATION_ERROR(-20001, 'Convênio inválido para BB');
        END IF;

        RETURN pkg_boleto_utils.lpad_zero(p_nosso_numero, v_tamanho_nn);
    END formatar_nosso_numero;

    -- ========================================================================
    -- FUNCTION: calcular_campo_livre
    -- Calcula campo livre específico do BB (25 posições)
    -- ========================================================================
    FUNCTION calcular_campo_livre(
        p_convenio IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_agencia IN VARCHAR2,
        p_conta IN VARCHAR2,
        p_carteira IN VARCHAR2
    ) RETURN VARCHAR2 IS
        v_campo_livre VARCHAR2(25);
        v_convenio_len NUMBER := LENGTH(p_convenio);
        v_nosso_numero_formatado VARCHAR2(20);
    BEGIN
        -- Validar dados
        IF NOT validar_dados(p_convenio, p_nosso_numero, p_carteira) THEN
            RAISE_APPLICATION_ERROR(-20002, 'Dados inválidos para Banco do Brasil');
        END IF;

        v_nosso_numero_formatado := formatar_nosso_numero(p_nosso_numero, p_convenio);

        -- Formato conforme tamanho do convênio
        IF v_convenio_len = 6 THEN
            -- Formato: CCCCCCNNNNNAAAACCCCCCCCCC
            -- 6 dígitos convênio + 5 nosso número + 4 agência + 8 conta + 2 carteira
            v_campo_livre := pkg_boleto_utils.lpad_zero(p_convenio, 6) ||
                            v_nosso_numero_formatado ||
                            pkg_boleto_utils.lpad_zero(p_agencia, 4) ||
                            pkg_boleto_utils.lpad_zero(p_conta, 8) ||
                            pkg_boleto_utils.lpad_zero(p_carteira, 2);

        ELSIF v_convenio_len = 7 THEN
            -- Formato: CCCCCCCNNNNNNNNNNCC000000
            -- 7 dígitos convênio + 10 nosso número + 2 carteira + 6 zeros
            v_campo_livre := pkg_boleto_utils.lpad_zero(p_convenio, 7) ||
                            v_nosso_numero_formatado ||
                            pkg_boleto_utils.lpad_zero(p_carteira, 2) ||
                            '000000';

        ELSIF v_convenio_len = 8 THEN
            -- Formato: CCCCCCCCNNNNNNNNNCC000000
            -- 8 dígitos convênio + 9 nosso número + 2 carteira + 6 zeros
            v_campo_livre := pkg_boleto_utils.lpad_zero(p_convenio, 8) ||
                            v_nosso_numero_formatado ||
                            pkg_boleto_utils.lpad_zero(p_carteira, 2) ||
                            '000000';
        END IF;

        -- Garante 25 posições
        RETURN SUBSTR(v_campo_livre, 1, 25);
    END calcular_campo_livre;

    -- ========================================================================
    -- FUNCTION: gerar_codigo_barras
    -- Gera código de barras completo do BB
    -- ========================================================================
    FUNCTION gerar_codigo_barras(
        p_convenio IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_agencia IN VARCHAR2,
        p_conta IN VARCHAR2,
        p_carteira IN VARCHAR2,
        p_valor IN NUMBER,
        p_data_vencimento IN DATE
    ) RETURN pkg_boleto_barcode.t_boleto_calculado IS
        v_result pkg_boleto_barcode.t_boleto_calculado;
        v_campo_livre VARCHAR2(25);
        v_fator_vencimento VARCHAR2(4);
        v_valor_formatado VARCHAR2(10);
        v_codigo_temp VARCHAR2(43);
        v_dv VARCHAR2(1);
    BEGIN
        -- Calcular campo livre
        v_campo_livre := calcular_campo_livre(
            p_convenio,
            p_nosso_numero,
            p_agencia,
            p_conta,
            p_carteira
        );

        -- Calcular fator de vencimento e valor
        v_fator_vencimento := pkg_boleto_utils.fator_vencimento(p_data_vencimento);
        v_valor_formatado := pkg_boleto_utils.formata_valor(p_valor, 10);

        -- Montar código de barras sem DV (posição 5)
        v_codigo_temp := C_CODIGO_BANCO ||
                        C_DIGITO_MOEDA ||
                        v_fator_vencimento ||
                        v_valor_formatado ||
                        v_campo_livre;

        -- Calcular DV (posição 5)
        v_dv := TO_CHAR(pkg_boleto_utils.modulo11(v_codigo_temp, 9, 1));

        -- Código de barras completo
        v_result.codigo_barras := SUBSTR(v_codigo_temp, 1, 4) ||
                                 v_dv ||
                                 SUBSTR(v_codigo_temp, 5);

        v_result.dv_codigo_barras := v_dv;
        v_result.campo_livre := v_campo_livre;

        -- Gerar linha digitável
        v_result.linha_digitavel := pkg_boleto_utils.linha_digitavel(v_result.codigo_barras);
        v_result.linha_digitavel_formatada := pkg_boleto_utils.formata_linha_digitavel(v_result.linha_digitavel);

        RETURN v_result;
    END gerar_codigo_barras;

END pkg_banco_001_bb;
/

-- Testes
PROMPT
PROMPT === Testando PKG_BANCO_001_BB ===

DECLARE
    v_resultado pkg_boleto_barcode.t_boleto_calculado;
BEGIN
    -- Teste com convênio de 7 dígitos
    v_resultado := pkg_banco_001_bb.gerar_codigo_barras(
        p_convenio => '1234567',
        p_nosso_numero => '123456',
        p_agencia => '1234',
        p_conta => '12345678',
        p_carteira => '18',
        p_valor => 1500.00,
        p_data_vencimento => TO_DATE('15/02/2024', 'DD/MM/YYYY')
    );

    DBMS_OUTPUT.PUT_LINE('Banco do Brasil - Teste');
    DBMS_OUTPUT.PUT_LINE('Código de Barras: ' || v_resultado.codigo_barras);
    DBMS_OUTPUT.PUT_LINE('Linha Digitável: ' || v_resultado.linha_digitavel_formatada);
    DBMS_OUTPUT.PUT_LINE('Campo Livre: ' || v_resultado.campo_livre);
END;
/

PROMPT
PROMPT Package PKG_BANCO_001_BB criado com sucesso!
PROMPT
