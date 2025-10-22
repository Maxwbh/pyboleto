-- ============================================================================
-- Package: PKG_BOLETO_BARCODE
-- Geração de código de barras e campo livre para cada banco
-- ============================================================================

CREATE OR REPLACE PACKAGE pkg_boleto_barcode AS

    -- Type para retornar dados do boleto calculados
    TYPE t_boleto_calculado IS RECORD (
        codigo_barras VARCHAR2(44),
        linha_digitavel VARCHAR2(54),
        linha_digitavel_formatada VARCHAR2(54),
        dv_codigo_barras VARCHAR2(1),
        campo_livre VARCHAR2(25)
    );

    -- Função principal para gerar código de barras
    FUNCTION gerar_codigo_barras(
        p_id_boleto IN NUMBER
    ) RETURN t_boleto_calculado;

    -- Funções específicas por banco para calcular campo livre
    FUNCTION campo_livre_bb(
        p_convenio IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_agencia IN VARCHAR2,
        p_conta IN VARCHAR2,
        p_carteira IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION campo_livre_bradesco(
        p_agencia IN VARCHAR2,
        p_carteira IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_conta IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION campo_livre_caixa(
        p_nosso_numero IN VARCHAR2,
        p_agencia IN VARCHAR2,
        p_modalidade IN VARCHAR2,
        p_conta IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION campo_livre_itau(
        p_agencia IN VARCHAR2,
        p_conta IN VARCHAR2,
        p_carteira IN VARCHAR2,
        p_nosso_numero IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION campo_livre_santander(
        p_fixo IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_ios IN VARCHAR2,
        p_carteira IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION campo_livre_hsbc(
        p_nosso_numero IN VARCHAR2,
        p_agencia IN VARCHAR2,
        p_conta IN VARCHAR2,
        p_data_vencimento IN DATE
    ) RETURN VARCHAR2;

    FUNCTION campo_livre_banrisul(
        p_livre IN VARCHAR2,
        p_agencia IN VARCHAR2,
        p_conta IN VARCHAR2,
        p_nosso_numero IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION campo_livre_brb(
        p_agencia IN VARCHAR2,
        p_carteira IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_conta IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION campo_livre_sicoob(
        p_carteira IN VARCHAR2,
        p_agencia IN VARCHAR2,
        p_modalidade IN VARCHAR2,
        p_numero_cooperativa IN VARCHAR2,
        p_nosso_numero IN VARCHAR2
    ) RETURN VARCHAR2;

END pkg_boleto_barcode;
/

CREATE OR REPLACE PACKAGE BODY pkg_boleto_barcode AS

    -- ========================================================================
    -- FUNCTION: campo_livre_bb
    -- Banco do Brasil - Campo livre específico
    -- Suporta convênios de 6, 7 e 8 dígitos
    -- ========================================================================
    FUNCTION campo_livre_bb(
        p_convenio IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_agencia IN VARCHAR2,
        p_conta IN VARCHAR2,
        p_carteira IN VARCHAR2
    ) RETURN VARCHAR2 IS
        v_campo_livre VARCHAR2(25);
        v_convenio_len NUMBER := LENGTH(p_convenio);
    BEGIN
        IF v_convenio_len = 6 THEN
            -- Convênio de 6 dígitos: NNNNNN + NNNNN + AAAA + CCC + 000
            v_campo_livre := pkg_boleto_utils.lpad_zero(p_convenio, 6) ||
                            pkg_boleto_utils.lpad_zero(p_nosso_numero, 5) ||
                            pkg_boleto_utils.lpad_zero(p_agencia, 4) ||
                            pkg_boleto_utils.lpad_zero(p_conta, 8) ||
                            pkg_boleto_utils.lpad_zero(p_carteira, 2);
        ELSIF v_convenio_len = 7 THEN
            -- Convênio de 7 dígitos: NNNNNNN + NNNNNNNNNN + CC
            v_campo_livre := pkg_boleto_utils.lpad_zero(p_convenio, 7) ||
                            pkg_boleto_utils.lpad_zero(p_nosso_numero, 10) ||
                            pkg_boleto_utils.lpad_zero(p_carteira, 2) ||
                            '000000';
        ELSIF v_convenio_len = 8 THEN
            -- Convênio de 8 dígitos: NNNNNNNN + NNNNNNNNN + 00
            v_campo_livre := pkg_boleto_utils.lpad_zero(p_convenio, 8) ||
                            pkg_boleto_utils.lpad_zero(p_nosso_numero, 9) ||
                            pkg_boleto_utils.lpad_zero(p_carteira, 2) ||
                            '000000';
        ELSE
            RAISE_APPLICATION_ERROR(-20100, 'Convênio deve ter 6, 7 ou 8 dígitos');
        END IF;

        RETURN SUBSTR(v_campo_livre, 1, 25);
    END campo_livre_bb;

    -- ========================================================================
    -- FUNCTION: campo_livre_bradesco
    -- Bradesco - Campo livre específico
    -- Formato: AAAA CC NNNNNNNNNNN CCCCCCCC 0
    -- ========================================================================
    FUNCTION campo_livre_bradesco(
        p_agencia IN VARCHAR2,
        p_carteira IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_conta IN VARCHAR2
    ) RETURN VARCHAR2 IS
        v_campo_livre VARCHAR2(25);
        v_dv NUMBER;
    BEGIN
        v_campo_livre := pkg_boleto_utils.lpad_zero(p_agencia, 4) ||
                        pkg_boleto_utils.lpad_zero(p_carteira, 2) ||
                        pkg_boleto_utils.lpad_zero(p_nosso_numero, 11) ||
                        pkg_boleto_utils.lpad_zero(p_conta, 7);

        -- Calcula DV do campo livre
        v_dv := pkg_boleto_utils.modulo11(v_campo_livre, 7, 0);
        v_campo_livre := v_campo_livre || TO_CHAR(v_dv);

        RETURN SUBSTR(v_campo_livre, 1, 25);
    END campo_livre_bradesco;

    -- ========================================================================
    -- FUNCTION: campo_livre_caixa
    -- Caixa Econômica Federal - Campo livre específico
    -- Formato: NNNNNNNNNNNNNN AAAA MM CCCCCC D
    -- ========================================================================
    FUNCTION campo_livre_caixa(
        p_nosso_numero IN VARCHAR2,
        p_agencia IN VARCHAR2,
        p_modalidade IN VARCHAR2,
        p_conta IN VARCHAR2
    ) RETURN VARCHAR2 IS
        v_campo_livre VARCHAR2(25);
        v_dv NUMBER;
    BEGIN
        v_campo_livre := pkg_boleto_utils.lpad_zero(p_nosso_numero, 14) ||
                        pkg_boleto_utils.lpad_zero(p_agencia, 4) ||
                        pkg_boleto_utils.lpad_zero(p_modalidade, 2) ||
                        pkg_boleto_utils.lpad_zero(p_conta, 8);

        -- Calcula DV do campo livre usando módulo 11
        v_dv := pkg_boleto_utils.modulo11(v_campo_livre, 9, 0);
        v_campo_livre := v_campo_livre || TO_CHAR(v_dv);

        RETURN SUBSTR(v_campo_livre, 1, 25);
    END campo_livre_caixa;

    -- ========================================================================
    -- FUNCTION: campo_livre_itau
    -- Itaú - Campo livre específico
    -- Formato: CCC NNNNNNNNN D AAAA CCCCCC D CCC
    -- ========================================================================
    FUNCTION campo_livre_itau(
        p_agencia IN VARCHAR2,
        p_conta IN VARCHAR2,
        p_carteira IN VARCHAR2,
        p_nosso_numero IN VARCHAR2
    ) RETURN VARCHAR2 IS
        v_campo_livre VARCHAR2(25);
        v_agencia_conta_nosso VARCHAR2(20);
        v_dv_agencia_conta NUMBER;
        v_dv NUMBER;
    BEGIN
        -- Calcula DV da agência/conta/carteira/nosso número
        v_agencia_conta_nosso := pkg_boleto_utils.lpad_zero(p_agencia, 4) ||
                                pkg_boleto_utils.lpad_zero(p_conta, 5) ||
                                pkg_boleto_utils.lpad_zero(p_carteira, 3) ||
                                pkg_boleto_utils.lpad_zero(p_nosso_numero, 8);

        v_dv_agencia_conta := pkg_boleto_utils.modulo10(v_agencia_conta_nosso);

        -- Monta campo livre
        v_campo_livre := pkg_boleto_utils.lpad_zero(p_carteira, 3) ||
                        pkg_boleto_utils.lpad_zero(p_nosso_numero, 8) ||
                        TO_CHAR(v_dv_agencia_conta) ||
                        pkg_boleto_utils.lpad_zero(p_agencia, 4) ||
                        pkg_boleto_utils.lpad_zero(p_conta, 5) ||
                        '000';

        RETURN SUBSTR(v_campo_livre, 1, 25);
    END campo_livre_itau;

    -- ========================================================================
    -- FUNCTION: campo_livre_santander
    -- Santander - Campo livre específico
    -- Formato: 9 + NNNNNNNN + NNNNNNN + DDDDDDD + C
    -- ========================================================================
    FUNCTION campo_livre_santander(
        p_fixo IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_ios IN VARCHAR2,
        p_carteira IN VARCHAR2
    ) RETURN VARCHAR2 IS
        v_campo_livre VARCHAR2(25);
        v_dv NUMBER;
    BEGIN
        v_campo_livre := '9' ||
                        pkg_boleto_utils.lpad_zero(p_nosso_numero, 7) ||
                        pkg_boleto_utils.lpad_zero(p_ios, 7) ||
                        pkg_boleto_utils.lpad_zero(p_carteira, 3);

        -- Calcula DV do nosso número
        v_dv := pkg_boleto_utils.modulo11(p_nosso_numero, 9, 0);

        v_campo_livre := v_campo_livre ||
                        TO_CHAR(v_dv) ||
                        '0000000';

        RETURN SUBSTR(v_campo_livre, 1, 25);
    END campo_livre_santander;

    -- ========================================================================
    -- FUNCTION: campo_livre_hsbc
    -- HSBC - Campo livre específico
    -- ========================================================================
    FUNCTION campo_livre_hsbc(
        p_nosso_numero IN VARCHAR2,
        p_agencia IN VARCHAR2,
        p_conta IN VARCHAR2,
        p_data_vencimento IN DATE
    ) RETURN VARCHAR2 IS
        v_campo_livre VARCHAR2(25);
        v_data_juliana VARCHAR2(4);
    BEGIN
        -- Calcula data juliana (YDDD onde Y é último dígito do ano e DDD é dia do ano)
        v_data_juliana := TO_CHAR(p_data_vencimento, 'Y') ||
                         LPAD(TO_CHAR(p_data_vencimento, 'DDD'), 3, '0');

        v_campo_livre := pkg_boleto_utils.lpad_zero(p_nosso_numero, 13) ||
                        pkg_boleto_utils.lpad_zero(p_agencia, 4) ||
                        pkg_boleto_utils.lpad_zero(p_conta, 7) ||
                        '00';

        RETURN SUBSTR(v_campo_livre, 1, 25);
    END campo_livre_hsbc;

    -- ========================================================================
    -- FUNCTION: campo_livre_banrisul
    -- Banrisul - Campo livre específico
    -- ========================================================================
    FUNCTION campo_livre_banrisul(
        p_livre IN VARCHAR2,
        p_agencia IN VARCHAR2,
        p_conta IN VARCHAR2,
        p_nosso_numero IN VARCHAR2
    ) RETURN VARCHAR2 IS
        v_campo_livre VARCHAR2(25);
        v_dv1 NUMBER;
        v_dv2 NUMBER;
    BEGIN
        -- Formato: 21 AAAA DDDDDDDD CCCCCCCC DD
        v_campo_livre := '21' ||
                        pkg_boleto_utils.lpad_zero(p_agencia, 4) ||
                        pkg_boleto_utils.lpad_zero(p_nosso_numero, 8);

        v_dv1 := pkg_boleto_utils.modulo10(v_campo_livre);
        v_campo_livre := v_campo_livre ||
                        pkg_boleto_utils.lpad_zero(p_conta, 8) ||
                        '40';

        RETURN SUBSTR(v_campo_livre, 1, 25);
    END campo_livre_banrisul;

    -- ========================================================================
    -- FUNCTION: campo_livre_brb
    -- Banco de Brasília - Campo livre específico
    -- ========================================================================
    FUNCTION campo_livre_brb(
        p_agencia IN VARCHAR2,
        p_carteira IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_conta IN VARCHAR2
    ) RETURN VARCHAR2 IS
        v_campo_livre VARCHAR2(25);
    BEGIN
        v_campo_livre := pkg_boleto_utils.lpad_zero(p_agencia, 4) ||
                        pkg_boleto_utils.lpad_zero(p_carteira, 2) ||
                        pkg_boleto_utils.lpad_zero(p_nosso_numero, 7) ||
                        pkg_boleto_utils.lpad_zero(p_conta, 7) ||
                        '000000';

        RETURN SUBSTR(v_campo_livre, 1, 25);
    END campo_livre_brb;

    -- ========================================================================
    -- FUNCTION: campo_livre_sicoob
    -- Sicoob - Campo livre específico
    -- Formato: C AAAA MM CCCC NNNNNNNNNN D
    -- ========================================================================
    FUNCTION campo_livre_sicoob(
        p_carteira IN VARCHAR2,
        p_agencia IN VARCHAR2,
        p_modalidade IN VARCHAR2,
        p_numero_cooperativa IN VARCHAR2,
        p_nosso_numero IN VARCHAR2
    ) RETURN VARCHAR2 IS
        v_campo_livre VARCHAR2(25);
        v_dv NUMBER;
    BEGIN
        v_campo_livre := pkg_boleto_utils.lpad_zero(p_carteira, 1) ||
                        pkg_boleto_utils.lpad_zero(p_agencia, 4) ||
                        pkg_boleto_utils.lpad_zero(p_modalidade, 2) ||
                        pkg_boleto_utils.lpad_zero(p_numero_cooperativa, 7) ||
                        pkg_boleto_utils.lpad_zero(p_nosso_numero, 10);

        -- Calcula DV
        v_dv := pkg_boleto_utils.modulo11(v_campo_livre, 9, 0);
        v_campo_livre := v_campo_livre || TO_CHAR(v_dv);

        RETURN SUBSTR(v_campo_livre, 1, 25);
    END campo_livre_sicoob;

    -- ========================================================================
    -- FUNCTION: gerar_codigo_barras
    -- Função principal que gera o código de barras completo
    -- ========================================================================
    FUNCTION gerar_codigo_barras(
        p_id_boleto IN NUMBER
    ) RETURN t_boleto_calculado IS
        v_result t_boleto_calculado;
        v_codigo_banco VARCHAR2(3);
        v_moeda VARCHAR2(1) := '9'; -- Real
        v_dv VARCHAR2(1);
        v_fator_vencimento VARCHAR2(4);
        v_valor VARCHAR2(10);
        v_campo_livre VARCHAR2(25);
        v_codigo_temp VARCHAR2(43);

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

        -- Calcula campo livre específico por banco
        CASE v_codigo_banco
            WHEN '001' THEN -- Banco do Brasil
                v_campo_livre := campo_livre_bb(v_convenio, v_nosso_numero, v_agencia, v_conta, v_carteira);
            WHEN '237' THEN -- Bradesco
                v_campo_livre := campo_livre_bradesco(v_agencia, v_carteira, v_nosso_numero, v_conta);
            WHEN '104' THEN -- Caixa
                v_campo_livre := campo_livre_caixa(v_nosso_numero, v_agencia, v_carteira, v_conta);
            WHEN '341' THEN -- Itaú
                v_campo_livre := campo_livre_itau(v_agencia, v_conta, v_carteira, v_nosso_numero);
            WHEN '033' THEN -- Santander
                v_campo_livre := campo_livre_santander('9', v_nosso_numero, v_ios, v_carteira);
            WHEN '399' THEN -- HSBC
                v_campo_livre := campo_livre_hsbc(v_nosso_numero, v_agencia, v_conta, v_data_vencimento);
            WHEN '041' THEN -- Banrisul
                v_campo_livre := campo_livre_banrisul('', v_agencia, v_conta, v_nosso_numero);
            WHEN '070' THEN -- BRB
                v_campo_livre := campo_livre_brb(v_agencia, v_carteira, v_nosso_numero, v_conta);
            WHEN '756' THEN -- Sicoob
                v_campo_livre := campo_livre_sicoob(v_carteira, v_agencia, '01', v_agencia, v_nosso_numero);
            ELSE
                RAISE_APPLICATION_ERROR(-20101, 'Banco não implementado: ' || v_codigo_banco);
        END CASE;

        -- Calcula fator de vencimento e valor
        v_fator_vencimento := pkg_boleto_utils.fator_vencimento(v_data_vencimento);
        v_valor := pkg_boleto_utils.formata_valor(v_valor_documento, 10);

        -- Monta código de barras sem o DV (posição 5)
        v_codigo_temp := v_codigo_banco ||
                        v_moeda ||
                        v_fator_vencimento ||
                        v_valor ||
                        v_campo_livre;

        -- Calcula DV do código de barras (módulo 11)
        v_dv := TO_CHAR(pkg_boleto_utils.modulo11(v_codigo_temp, 9, 1));

        -- Monta código de barras completo
        v_result.codigo_barras := SUBSTR(v_codigo_temp, 1, 4) ||
                                 v_dv ||
                                 SUBSTR(v_codigo_temp, 5);

        v_result.dv_codigo_barras := v_dv;
        v_result.campo_livre := v_campo_livre;

        -- Gera linha digitável
        v_result.linha_digitavel := pkg_boleto_utils.linha_digitavel(v_result.codigo_barras);
        v_result.linha_digitavel_formatada := pkg_boleto_utils.formata_linha_digitavel(v_result.linha_digitavel);

        RETURN v_result;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20102, 'Boleto não encontrado: ' || p_id_boleto);
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20103, 'Erro ao gerar código de barras: ' || SQLERRM);
    END gerar_codigo_barras;

END pkg_boleto_barcode;
/
