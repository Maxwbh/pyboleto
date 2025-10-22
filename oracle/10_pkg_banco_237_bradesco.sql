-- ============================================================================
-- Package: PKG_BANCO_237_BRADESCO
-- Bradesco - Implementação específica
-- ============================================================================

CREATE OR REPLACE PACKAGE pkg_banco_237_bradesco AS

    -- Constantes do banco
    C_CODIGO_BANCO CONSTANT VARCHAR2(3) := '237';
    C_NOME_BANCO CONSTANT VARCHAR2(100) := 'Bradesco';
    C_DIGITO_MOEDA CONSTANT VARCHAR2(1) := '9';

    -- Calcular dígito verificador do nosso número
    FUNCTION calcular_dv_nosso_numero(
        p_nosso_numero IN VARCHAR2,
        p_carteira IN VARCHAR2
    ) RETURN VARCHAR2;

    -- Formatar nosso número
    FUNCTION formatar_nosso_numero(
        p_nosso_numero IN VARCHAR2
    ) RETURN VARCHAR2;

    -- Calcular campo livre (25 posições)
    FUNCTION calcular_campo_livre(
        p_agencia IN VARCHAR2,
        p_carteira IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_conta IN VARCHAR2
    ) RETURN VARCHAR2;

    -- Gerar código de barras completo
    FUNCTION gerar_codigo_barras(
        p_agencia IN VARCHAR2,
        p_carteira IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_conta IN VARCHAR2,
        p_valor IN NUMBER,
        p_data_vencimento IN DATE
    ) RETURN pkg_boleto_barcode.t_boleto_calculado;

END pkg_banco_237_bradesco;
/

CREATE OR REPLACE PACKAGE BODY pkg_banco_237_bradesco AS

    -- ========================================================================
    -- FUNCTION: calcular_dv_nosso_numero
    -- Calcula DV do nosso número usando módulo 11 base 7
    -- ========================================================================
    FUNCTION calcular_dv_nosso_numero(
        p_nosso_numero IN VARCHAR2,
        p_carteira IN VARCHAR2
    ) RETURN VARCHAR2 IS
        v_numero VARCHAR2(50);
    BEGIN
        v_numero := pkg_boleto_utils.lpad_zero(p_carteira, 2) ||
                   pkg_boleto_utils.lpad_zero(p_nosso_numero, 11);
        RETURN TO_CHAR(pkg_boleto_utils.modulo11(v_numero, 7, 0));
    END calcular_dv_nosso_numero;

    -- ========================================================================
    -- FUNCTION: formatar_nosso_numero
    -- Formata nosso número com 11 dígitos
    -- ========================================================================
    FUNCTION formatar_nosso_numero(
        p_nosso_numero IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pkg_boleto_utils.lpad_zero(p_nosso_numero, 11);
    END formatar_nosso_numero;

    -- ========================================================================
    -- FUNCTION: calcular_campo_livre
    -- Formato Bradesco: AAAA CC NNNNNNNNNNN CCCCCCC D
    -- Agência(4) + Carteira(2) + Nosso Número(11) + Conta(7) + DV(1) = 25
    -- ========================================================================
    FUNCTION calcular_campo_livre(
        p_agencia IN VARCHAR2,
        p_carteira IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_conta IN VARCHAR2
    ) RETURN VARCHAR2 IS
        v_campo_livre VARCHAR2(25);
        v_dv VARCHAR2(1);
        v_nosso_numero_formatado VARCHAR2(11);
    BEGIN
        v_nosso_numero_formatado := formatar_nosso_numero(p_nosso_numero);

        -- Montar campo livre sem DV
        v_campo_livre := pkg_boleto_utils.lpad_zero(p_agencia, 4) ||
                        pkg_boleto_utils.lpad_zero(p_carteira, 2) ||
                        v_nosso_numero_formatado ||
                        pkg_boleto_utils.lpad_zero(p_conta, 7);

        -- Calcular DV do campo livre usando módulo 11 base 7
        v_dv := TO_CHAR(pkg_boleto_utils.modulo11(v_campo_livre, 7, 0));

        -- Campo livre completo
        v_campo_livre := v_campo_livre || v_dv;

        RETURN SUBSTR(v_campo_livre, 1, 25);
    END calcular_campo_livre;

    -- ========================================================================
    -- FUNCTION: gerar_codigo_barras
    -- Gera código de barras completo do Bradesco
    -- ========================================================================
    FUNCTION gerar_codigo_barras(
        p_agencia IN VARCHAR2,
        p_carteira IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_conta IN VARCHAR2,
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
            p_agencia,
            p_carteira,
            p_nosso_numero,
            p_conta
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

END pkg_banco_237_bradesco;
/

-- Testes
PROMPT
PROMPT === Testando PKG_BANCO_237_BRADESCO ===

DECLARE
    v_resultado pkg_boleto_barcode.t_boleto_calculado;
BEGIN
    v_resultado := pkg_banco_237_bradesco.gerar_codigo_barras(
        p_agencia => '0278',
        p_carteira => '06',
        p_nosso_numero => '2125525',
        p_conta => '0039232',
        p_valor => 8280.00,
        p_data_vencimento => TO_DATE('05/02/2011', 'DD/MM/YYYY')
    );

    DBMS_OUTPUT.PUT_LINE('Bradesco - Teste');
    DBMS_OUTPUT.PUT_LINE('Código de Barras: ' || v_resultado.codigo_barras);
    DBMS_OUTPUT.PUT_LINE('Linha Digitável: ' || v_resultado.linha_digitavel_formatada);
    DBMS_OUTPUT.PUT_LINE('Campo Livre: ' || v_resultado.campo_livre);
END;
/

PROMPT
PROMPT Package PKG_BANCO_237_BRADESCO criado com sucesso!
PROMPT
