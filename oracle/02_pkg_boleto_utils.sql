-- ============================================================================
-- Package: PKG_BOLETO_UTILS
-- Funções utilitárias para cálculo de dígitos verificadores e código de barras
-- ============================================================================

CREATE OR REPLACE PACKAGE pkg_boleto_utils AS

    -- Constantes
    C_DATA_BASE CONSTANT DATE := TO_DATE('07/10/1997', 'DD/MM/YYYY');

    -- Funções de Módulo
    FUNCTION modulo10(p_numero IN VARCHAR2) RETURN NUMBER;
    FUNCTION modulo11(p_numero IN VARCHAR2,
                      p_base IN NUMBER DEFAULT 9,
                      p_r IN NUMBER DEFAULT 0) RETURN NUMBER;

    -- Funções de formatação
    FUNCTION lpad_zero(p_texto IN VARCHAR2, p_tamanho IN NUMBER) RETURN VARCHAR2;
    FUNCTION formata_valor(p_valor IN NUMBER, p_tamanho IN NUMBER DEFAULT 10) RETURN VARCHAR2;
    FUNCTION fator_vencimento(p_data_vencimento IN DATE) RETURN VARCHAR2;

    -- Função para calcular linha digitável a partir do código de barras
    FUNCTION linha_digitavel(p_codigo_barras IN VARCHAR2) RETURN VARCHAR2;

    -- Função para formatar linha digitável com pontos e espaços
    FUNCTION formata_linha_digitavel(p_linha IN VARCHAR2) RETURN VARCHAR2;

    -- Função para remover formatação (pontos, espaços, etc)
    FUNCTION remove_formatacao(p_texto IN VARCHAR2) RETURN VARCHAR2;

    -- Função para validar CPF
    FUNCTION valida_cpf(p_cpf IN VARCHAR2) RETURN BOOLEAN;

    -- Função para validar CNPJ
    FUNCTION valida_cnpj(p_cnpj IN VARCHAR2) RETURN BOOLEAN;

END pkg_boleto_utils;
/

CREATE OR REPLACE PACKAGE BODY pkg_boleto_utils AS

    -- ========================================================================
    -- FUNCTION: modulo10
    -- Calcula o dígito verificador usando módulo 10
    -- Baseado na implementação Python original
    -- ========================================================================
    FUNCTION modulo10(p_numero IN VARCHAR2) RETURN NUMBER IS
        v_numero VARCHAR2(1000) := p_numero;
        v_soma NUMBER := 0;
        v_multiplicador NUMBER := 2;
        v_digito NUMBER;
        v_produto NUMBER;
        v_i NUMBER;
    BEGIN
        -- Processa da direita para esquerda
        FOR v_i IN REVERSE 1..LENGTH(v_numero) LOOP
            v_digito := TO_NUMBER(SUBSTR(v_numero, v_i, 1));
            v_produto := v_digito * v_multiplicador;

            -- Se produto > 9, soma os dígitos
            IF v_produto > 9 THEN
                v_produto := TRUNC(v_produto / 10) + MOD(v_produto, 10);
            END IF;

            v_soma := v_soma + v_produto;

            -- Alterna multiplicador entre 2 e 1
            v_multiplicador := CASE WHEN v_multiplicador = 2 THEN 1 ELSE 2 END;
        END LOOP;

        -- Retorna o dígito verificador
        v_digito := MOD(v_soma, 10);

        IF v_digito = 0 THEN
            RETURN 0;
        ELSE
            RETURN 10 - v_digito;
        END IF;
    END modulo10;

    -- ========================================================================
    -- FUNCTION: modulo11
    -- Calcula o dígito verificador usando módulo 11
    -- p_base: base máxima para multiplicação (padrão 9)
    -- p_r: valor de retorno quando resto é 0, 1 ou 10 (padrão 0)
    -- ========================================================================
    FUNCTION modulo11(p_numero IN VARCHAR2,
                      p_base IN NUMBER DEFAULT 9,
                      p_r IN NUMBER DEFAULT 0) RETURN NUMBER IS
        v_numero VARCHAR2(1000) := p_numero;
        v_soma NUMBER := 0;
        v_multiplicador NUMBER := 2;
        v_digito NUMBER;
        v_i NUMBER;
        v_resto NUMBER;
    BEGIN
        -- Processa da direita para esquerda
        FOR v_i IN REVERSE 1..LENGTH(v_numero) LOOP
            v_digito := TO_NUMBER(SUBSTR(v_numero, v_i, 1));
            v_soma := v_soma + (v_digito * v_multiplicador);

            v_multiplicador := v_multiplicador + 1;
            IF v_multiplicador > p_base THEN
                v_multiplicador := 2;
            END IF;
        END LOOP;

        v_resto := MOD(v_soma, 11);
        v_digito := 11 - v_resto;

        -- Regras especiais para módulo 11
        IF v_digito IN (0, 10, 11) THEN
            RETURN p_r;
        ELSE
            RETURN v_digito;
        END IF;
    END modulo11;

    -- ========================================================================
    -- FUNCTION: lpad_zero
    -- Preenche string com zeros à esquerda
    -- ========================================================================
    FUNCTION lpad_zero(p_texto IN VARCHAR2, p_tamanho IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
        RETURN LPAD(NVL(p_texto, '0'), p_tamanho, '0');
    END lpad_zero;

    -- ========================================================================
    -- FUNCTION: formata_valor
    -- Formata valor monetário para o código de barras (sem vírgula/ponto)
    -- Exemplo: 1234.50 -> 0000123450
    -- ========================================================================
    FUNCTION formata_valor(p_valor IN NUMBER, p_tamanho IN NUMBER DEFAULT 10) RETURN VARCHAR2 IS
        v_valor_centavos NUMBER;
    BEGIN
        -- Converte para centavos (multiplicando por 100)
        v_valor_centavos := TRUNC(p_valor * 100);
        RETURN LPAD(v_valor_centavos, p_tamanho, '0');
    END formata_valor;

    -- ========================================================================
    -- FUNCTION: fator_vencimento
    -- Calcula o fator de vencimento (dias desde 07/10/1997)
    -- ========================================================================
    FUNCTION fator_vencimento(p_data_vencimento IN DATE) RETURN VARCHAR2 IS
        v_dias NUMBER;
    BEGIN
        v_dias := TRUNC(p_data_vencimento) - C_DATA_BASE;

        IF v_dias < 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Data de vencimento não pode ser anterior a 07/10/1997');
        END IF;

        RETURN LPAD(v_dias, 4, '0');
    END fator_vencimento;

    -- ========================================================================
    -- FUNCTION: linha_digitavel
    -- Calcula a linha digitável a partir do código de barras
    -- ========================================================================
    FUNCTION linha_digitavel(p_codigo_barras IN VARCHAR2) RETURN VARCHAR2 IS
        v_campo1 VARCHAR2(10);
        v_campo2 VARCHAR2(11);
        v_campo3 VARCHAR2(11);
        v_campo4 VARCHAR2(1);
        v_campo5 VARCHAR2(14);
        v_dv1 NUMBER;
        v_dv2 NUMBER;
        v_dv3 NUMBER;
    BEGIN
        -- Valida tamanho do código de barras
        IF LENGTH(p_codigo_barras) != 44 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Código de barras deve ter 44 caracteres');
        END IF;

        -- Campo 1: Posições 1-4 e 20-24 do código de barras + DV
        v_campo1 := SUBSTR(p_codigo_barras, 1, 4) || SUBSTR(p_codigo_barras, 20, 5);
        v_dv1 := modulo10(v_campo1);
        v_campo1 := v_campo1 || TO_CHAR(v_dv1);

        -- Campo 2: Posições 25-34 do código de barras + DV
        v_campo2 := SUBSTR(p_codigo_barras, 25, 10);
        v_dv2 := modulo10(v_campo2);
        v_campo2 := v_campo2 || TO_CHAR(v_dv2);

        -- Campo 3: Posições 35-44 do código de barras + DV
        v_campo3 := SUBSTR(p_codigo_barras, 35, 10);
        v_dv3 := modulo10(v_campo3);
        v_campo3 := v_campo3 || TO_CHAR(v_dv3);

        -- Campo 4: Dígito verificador do código de barras (posição 5)
        v_campo4 := SUBSTR(p_codigo_barras, 5, 1);

        -- Campo 5: Fator de vencimento + valor (posições 6-19)
        v_campo5 := SUBSTR(p_codigo_barras, 6, 14);

        -- Retorna linha digitável sem formatação
        RETURN v_campo1 || v_campo2 || v_campo3 || v_campo4 || v_campo5;
    END linha_digitavel;

    -- ========================================================================
    -- FUNCTION: formata_linha_digitavel
    -- Formata linha digitável com pontos e espaços
    -- Formato: NNNNN.NNNNN NNNNN.NNNNNN NNNNN.NNNNNN N NNNNNNNNNNNNNN
    -- ========================================================================
    FUNCTION formata_linha_digitavel(p_linha IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        IF LENGTH(p_linha) != 47 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Linha digitável deve ter 47 caracteres');
        END IF;

        RETURN SUBSTR(p_linha, 1, 5)  || '.' ||
               SUBSTR(p_linha, 6, 5)  || ' ' ||
               SUBSTR(p_linha, 11, 5) || '.' ||
               SUBSTR(p_linha, 16, 6) || ' ' ||
               SUBSTR(p_linha, 22, 5) || '.' ||
               SUBSTR(p_linha, 27, 6) || ' ' ||
               SUBSTR(p_linha, 33, 1) || ' ' ||
               SUBSTR(p_linha, 34, 14);
    END formata_linha_digitavel;

    -- ========================================================================
    -- FUNCTION: remove_formatacao
    -- Remove pontos, espaços, hífens e barras
    -- ========================================================================
    FUNCTION remove_formatacao(p_texto IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN TRANSLATE(p_texto, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ .-/', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
    END remove_formatacao;

    -- ========================================================================
    -- FUNCTION: valida_cpf
    -- Valida CPF usando módulo 11
    -- ========================================================================
    FUNCTION valida_cpf(p_cpf IN VARCHAR2) RETURN BOOLEAN IS
        v_cpf VARCHAR2(11);
        v_soma NUMBER;
        v_digito1 NUMBER;
        v_digito2 NUMBER;
        v_i NUMBER;
    BEGIN
        -- Remove formatação
        v_cpf := REGEXP_REPLACE(p_cpf, '[^0-9]', '');

        -- Valida tamanho
        IF LENGTH(v_cpf) != 11 THEN
            RETURN FALSE;
        END IF;

        -- Valida sequências inválidas (111.111.111-11, etc)
        IF REGEXP_LIKE(v_cpf, '^([0-9])\1{10}$') THEN
            RETURN FALSE;
        END IF;

        -- Calcula primeiro dígito
        v_soma := 0;
        FOR v_i IN 1..9 LOOP
            v_soma := v_soma + (TO_NUMBER(SUBSTR(v_cpf, v_i, 1)) * (11 - v_i));
        END LOOP;
        v_digito1 := 11 - MOD(v_soma, 11);
        IF v_digito1 >= 10 THEN
            v_digito1 := 0;
        END IF;

        -- Calcula segundo dígito
        v_soma := 0;
        FOR v_i IN 1..10 LOOP
            v_soma := v_soma + (TO_NUMBER(SUBSTR(v_cpf, v_i, 1)) * (12 - v_i));
        END LOOP;
        v_digito2 := 11 - MOD(v_soma, 11);
        IF v_digito2 >= 10 THEN
            v_digito2 := 0;
        END IF;

        -- Valida dígitos
        RETURN (TO_NUMBER(SUBSTR(v_cpf, 10, 1)) = v_digito1) AND
               (TO_NUMBER(SUBSTR(v_cpf, 11, 1)) = v_digito2);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END valida_cpf;

    -- ========================================================================
    -- FUNCTION: valida_cnpj
    -- Valida CNPJ usando módulo 11
    -- ========================================================================
    FUNCTION valida_cnpj(p_cnpj IN VARCHAR2) RETURN BOOLEAN IS
        v_cnpj VARCHAR2(14);
        v_soma NUMBER;
        v_digito1 NUMBER;
        v_digito2 NUMBER;
        v_multiplicador NUMBER;
        v_i NUMBER;
    BEGIN
        -- Remove formatação
        v_cnpj := REGEXP_REPLACE(p_cnpj, '[^0-9]', '');

        -- Valida tamanho
        IF LENGTH(v_cnpj) != 14 THEN
            RETURN FALSE;
        END IF;

        -- Valida sequências inválidas
        IF REGEXP_LIKE(v_cnpj, '^([0-9])\1{13}$') THEN
            RETURN FALSE;
        END IF;

        -- Calcula primeiro dígito
        v_soma := 0;
        v_multiplicador := 5;
        FOR v_i IN 1..12 LOOP
            v_soma := v_soma + (TO_NUMBER(SUBSTR(v_cnpj, v_i, 1)) * v_multiplicador);
            v_multiplicador := v_multiplicador - 1;
            IF v_multiplicador < 2 THEN
                v_multiplicador := 9;
            END IF;
        END LOOP;
        v_digito1 := MOD(v_soma, 11);
        IF v_digito1 < 2 THEN
            v_digito1 := 0;
        ELSE
            v_digito1 := 11 - v_digito1;
        END IF;

        -- Calcula segundo dígito
        v_soma := 0;
        v_multiplicador := 6;
        FOR v_i IN 1..13 LOOP
            v_soma := v_soma + (TO_NUMBER(SUBSTR(v_cnpj, v_i, 1)) * v_multiplicador);
            v_multiplicador := v_multiplicador - 1;
            IF v_multiplicador < 2 THEN
                v_multiplicador := 9;
            END IF;
        END LOOP;
        v_digito2 := MOD(v_soma, 11);
        IF v_digito2 < 2 THEN
            v_digito2 := 0;
        ELSE
            v_digito2 := 11 - v_digito2;
        END IF;

        -- Valida dígitos
        RETURN (TO_NUMBER(SUBSTR(v_cnpj, 13, 1)) = v_digito1) AND
               (TO_NUMBER(SUBSTR(v_cnpj, 14, 1)) = v_digito2);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END valida_cnpj;

END pkg_boleto_utils;
/

-- Testes básicos
BEGIN
    DBMS_OUTPUT.PUT_LINE('Teste Módulo 10: ' || pkg_boleto_utils.modulo10('3999100100001234567870000123456'));
    DBMS_OUTPUT.PUT_LINE('Teste Módulo 11: ' || pkg_boleto_utils.modulo11('0019373700000001000500940144816060680935031'));
    DBMS_OUTPUT.PUT_LINE('Teste CPF válido: ' || CASE WHEN pkg_boleto_utils.valida_cpf('12345678909') THEN 'SIM' ELSE 'NÃO' END);
    DBMS_OUTPUT.PUT_LINE('Teste CNPJ válido: ' || CASE WHEN pkg_boleto_utils.valida_cnpj('11222333000181') THEN 'SIM' ELSE 'NÃO' END);
END;
/
