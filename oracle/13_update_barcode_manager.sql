-- ============================================================================
-- Atualização dos Packages PKG_BOLETO_BARCODE e PKG_BOLETO_MANAGER
-- Para usar packages específicos de cada banco e gravar HTML/PDF
-- ============================================================================

PROMPT =========================================================
PROMPT Atualizando PKG_BOLETO_BARCODE...
PROMPT =========================================================

-- ============================================================================
-- Recriar PKG_BOLETO_BARCODE para usar packages específicos dos bancos
-- ============================================================================
CREATE OR REPLACE PACKAGE BODY pkg_boleto_barcode AS

    -- ========================================================================
    -- FUNCTION: gerar_codigo_barras
    -- Função principal que delega para package específico de cada banco
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

            ELSE
                -- Para bancos não implementados em packages específicos, usar implementação legada
                v_result := campo_livre_bradesco(v_agencia, v_carteira, v_nosso_numero, v_conta);
                RAISE_APPLICATION_ERROR(-20101,
                    'Banco ' || v_codigo_banco || ' não possui package específico implementado');
        END CASE;

        RETURN v_result;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20102, 'Boleto não encontrado: ' || p_id_boleto);
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20103, 'Erro ao gerar código de barras: ' || SQLERRM);
    END gerar_codigo_barras;

    -- Mantém funções originais para compatibilidade...
    FUNCTION campo_livre_bb(p_convenio IN VARCHAR2, p_nosso_numero IN VARCHAR2, p_agencia IN VARCHAR2, p_conta IN VARCHAR2, p_carteira IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN pkg_banco_001_bb.calcular_campo_livre(p_convenio, p_nosso_numero, p_agencia, p_conta, p_carteira);
    END;

    FUNCTION campo_livre_bradesco(p_agencia IN VARCHAR2, p_carteira IN VARCHAR2, p_nosso_numero IN VARCHAR2, p_conta IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN pkg_banco_237_bradesco.calcular_campo_livre(p_agencia, p_carteira, p_nosso_numero, p_conta);
    END;

    FUNCTION campo_livre_caixa(p_nosso_numero IN VARCHAR2, p_agencia IN VARCHAR2, p_modalidade IN VARCHAR2, p_conta IN VARCHAR2) RETURN VARCHAR2 IS
        v_result pkg_boleto_barcode.t_boleto_calculado;
    BEGIN
        v_result := pkg_banco_104_caixa.gerar_codigo_barras(p_nosso_numero, p_agencia, p_modalidade, p_conta, 0, SYSDATE);
        RETURN v_result.campo_livre;
    END;

    FUNCTION campo_livre_itau(p_agencia IN VARCHAR2, p_conta IN VARCHAR2, p_carteira IN VARCHAR2, p_nosso_numero IN VARCHAR2) RETURN VARCHAR2 IS
        v_result pkg_boleto_barcode.t_boleto_calculado;
    BEGIN
        v_result := pkg_banco_341_itau.gerar_codigo_barras(p_agencia, p_conta, p_carteira, p_nosso_numero, 0, SYSDATE);
        RETURN v_result.campo_livre;
    END;

    FUNCTION campo_livre_santander(p_fixo IN VARCHAR2, p_nosso_numero IN VARCHAR2, p_ios IN VARCHAR2, p_carteira IN VARCHAR2) RETURN VARCHAR2 IS
        v_result pkg_boleto_barcode.t_boleto_calculado;
    BEGIN
        v_result := pkg_banco_033_santander.gerar_codigo_barras(p_nosso_numero, p_ios, p_carteira, 0, SYSDATE);
        RETURN v_result.campo_livre;
    END;

    FUNCTION campo_livre_hsbc(p_nosso_numero IN VARCHAR2, p_agencia IN VARCHAR2, p_conta IN VARCHAR2, p_data_vencimento IN DATE) RETURN VARCHAR2 IS
    BEGIN
        RETURN pkg_boleto_utils.lpad_zero(p_nosso_numero, 13) ||
               pkg_boleto_utils.lpad_zero(p_agencia, 4) ||
               pkg_boleto_utils.lpad_zero(p_conta, 7) || '00';
    END;

    FUNCTION campo_livre_banrisul(p_livre IN VARCHAR2, p_agencia IN VARCHAR2, p_conta IN VARCHAR2, p_nosso_numero IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN '21' || pkg_boleto_utils.lpad_zero(p_agencia, 4) ||
               pkg_boleto_utils.lpad_zero(p_nosso_numero, 8) ||
               pkg_boleto_utils.lpad_zero(p_conta, 8) || '40';
    END;

    FUNCTION campo_livre_brb(p_agencia IN VARCHAR2, p_carteira IN VARCHAR2, p_nosso_numero IN VARCHAR2, p_conta IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN pkg_boleto_utils.lpad_zero(p_agencia, 4) ||
               pkg_boleto_utils.lpad_zero(p_carteira, 2) ||
               pkg_boleto_utils.lpad_zero(p_nosso_numero, 7) ||
               pkg_boleto_utils.lpad_zero(p_conta, 7) || '000000';
    END;

    FUNCTION campo_livre_sicoob(p_carteira IN VARCHAR2, p_agencia IN VARCHAR2, p_modalidade IN VARCHAR2, p_numero_cooperativa IN VARCHAR2, p_nosso_numero IN VARCHAR2) RETURN VARCHAR2 IS
        v_result pkg_boleto_barcode.t_boleto_calculado;
    BEGIN
        v_result := pkg_banco_756_sicoob.gerar_codigo_barras(p_carteira, p_agencia, p_modalidade, p_numero_cooperativa, p_nosso_numero, 0, SYSDATE);
        RETURN v_result.campo_livre;
    END;

END pkg_boleto_barcode;
/

PROMPT PKG_BOLETO_BARCODE atualizado!

PROMPT =========================================================
PROMPT Atualizando PKG_BOLETO_MANAGER...
PROMPT =========================================================

-- ============================================================================
-- Atualizar PKG_BOLETO_MANAGER para gravar HTML/PDF
-- ============================================================================
CREATE OR REPLACE PACKAGE BODY pkg_boleto_manager AS

    -- Função auxiliar interna para gerar e gravar conteúdo
    PROCEDURE gerar_e_gravar_conteudo(
        p_id_boleto IN NUMBER,
        p_id_modelo IN NUMBER DEFAULT NULL
    ) IS
        v_html CLOB;
        v_pdf BLOB;
        v_id_modelo NUMBER;
    BEGIN
        -- Determinar modelo a usar
        v_id_modelo := p_id_modelo;
        IF v_id_modelo IS NULL THEN
            SELECT id_modelo
            INTO v_id_modelo
            FROM boleto_modelos
            WHERE nome_modelo = 'PADRAO_HTML'
              AND ativo = 'S';
        END IF;

        -- Gerar HTML
        v_html := pkg_boleto_html.gerar_html(p_id_boleto);

        -- Gravar HTML no banco
        UPDATE boletos
        SET conteudo_html = v_html,
            data_geracao_html = CURRENT_TIMESTAMP,
            id_modelo = v_id_modelo
        WHERE id_boleto = p_id_boleto;

        -- Registrar no histórico
        INSERT INTO boleto_historico (
            id_boleto,
            tipo_evento,
            descricao
        ) VALUES (
            p_id_boleto,
            'GERACAO_HTML',
            'HTML gerado com ' || DBMS_LOB.GETLENGTH(v_html) || ' caracteres'
        );

        COMMIT;
    END gerar_e_gravar_conteudo;

    -- ========================================================================
    -- FUNCTION: criar_boleto (atualizado)
    -- Cria boleto e gera conteúdo HTML automaticamente
    -- ========================================================================
    FUNCTION criar_boleto(
        p_id_conta IN NUMBER,
        p_id_sacado IN NUMBER,
        p_numero_documento IN VARCHAR2,
        p_nosso_numero IN VARCHAR2,
        p_data_documento IN DATE,
        p_data_vencimento IN DATE,
        p_valor_documento IN NUMBER,
        p_instrucoes IN CLOB DEFAULT NULL,
        p_demonstrativo IN CLOB DEFAULT NULL,
        p_especie_documento IN VARCHAR2 DEFAULT 'DM',
        p_aceite IN CHAR DEFAULT 'N',
        p_local_pagamento IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER IS
        v_id_boleto NUMBER;
        v_local_pag VARCHAR2(200);
    BEGIN
        v_local_pag := NVL(p_local_pagamento, 'Pagável em qualquer banco até o vencimento');

        INSERT INTO boletos (
            id_conta, id_sacado, numero_documento, nosso_numero,
            data_documento, data_vencimento, data_processamento,
            valor_documento, instrucoes, demonstrativo,
            especie_documento, aceite, local_pagamento, status
        ) VALUES (
            p_id_conta, p_id_sacado, p_numero_documento, p_nosso_numero,
            p_data_documento, p_data_vencimento, SYSDATE,
            p_valor_documento, p_instrucoes, p_demonstrativo,
            p_especie_documento, p_aceite, v_local_pag, 'GERADO'
        ) RETURNING id_boleto INTO v_id_boleto;

        -- Gerar código de barras
        gerar_boleto(v_id_boleto);

        -- Gerar e gravar HTML
        gerar_e_gravar_conteudo(v_id_boleto);

        INSERT INTO boleto_historico (id_boleto, tipo_evento, descricao)
        VALUES (v_id_boleto, 'CRIACAO', 'Boleto criado com sucesso');

        COMMIT;
        RETURN v_id_boleto;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20201, 'Boleto com este nosso número já existe');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20202, 'Erro ao criar boleto: ' || SQLERRM);
    END criar_boleto;

    -- Mantém procedures originais
    PROCEDURE gerar_boleto(p_id_boleto IN NUMBER) IS
        v_calculo pkg_boleto_barcode.t_boleto_calculado;
    BEGIN
        v_calculo := pkg_boleto_barcode.gerar_codigo_barras(p_id_boleto);

        UPDATE boletos
        SET codigo_barras = v_calculo.codigo_barras,
            linha_digitavel = v_calculo.linha_digitavel_formatada,
            dv_codigo_barras = v_calculo.dv_codigo_barras,
            campo_livre = v_calculo.campo_livre,
            updated_at = CURRENT_TIMESTAMP
        WHERE id_boleto = p_id_boleto;

        INSERT INTO boleto_historico (id_boleto, tipo_evento, descricao)
        VALUES (p_id_boleto, 'GERACAO', 'Código de barras gerado: ' || v_calculo.codigo_barras);

        COMMIT;
    END gerar_boleto;

    PROCEDURE gerar_boletos_lote(p_ids_boletos IN VARCHAR2) IS
        v_id_boleto NUMBER;
        v_pos NUMBER;
        v_ids VARCHAR2(4000) := p_ids_boletos || ',';
    BEGIN
        LOOP
            v_pos := INSTR(v_ids, ',');
            EXIT WHEN v_pos = 0;
            v_id_boleto := TO_NUMBER(SUBSTR(v_ids, 1, v_pos - 1));
            gerar_boleto(v_id_boleto);
            v_ids := SUBSTR(v_ids, v_pos + 1);
        END LOOP;
    END gerar_boletos_lote;

    PROCEDURE atualizar_boleto(p_id_boleto IN NUMBER, p_data_vencimento IN DATE DEFAULT NULL,
        p_valor_documento IN NUMBER DEFAULT NULL, p_instrucoes IN CLOB DEFAULT NULL,
        p_demonstrativo IN CLOB DEFAULT NULL) IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM boletos
        WHERE id_boleto = p_id_boleto AND status NOT IN ('PAGO', 'CANCELADO');

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20204, 'Boleto não encontrado ou não pode ser atualizado');
        END IF;

        UPDATE boletos
        SET data_vencimento = NVL(p_data_vencimento, data_vencimento),
            valor_documento = NVL(p_valor_documento, valor_documento),
            instrucoes = NVL(p_instrucoes, instrucoes),
            demonstrativo = NVL(p_demonstrativo, demonstrativo)
        WHERE id_boleto = p_id_boleto;

        IF p_data_vencimento IS NOT NULL OR p_valor_documento IS NOT NULL THEN
            gerar_boleto(p_id_boleto);
            gerar_e_gravar_conteudo(p_id_boleto);
        END IF;

        INSERT INTO boleto_historico (id_boleto, tipo_evento, descricao)
        VALUES (p_id_boleto, 'ATUALIZACAO', 'Boleto atualizado');

        COMMIT;
    END atualizar_boleto;

    PROCEDURE cancelar_boleto(p_id_boleto IN NUMBER) IS
    BEGIN
        UPDATE boletos SET status = 'CANCELADO'
        WHERE id_boleto = p_id_boleto AND status NOT IN ('PAGO', 'CANCELADO');

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20205, 'Boleto não encontrado ou não pode ser cancelado');
        END IF;

        INSERT INTO boleto_historico (id_boleto, tipo_evento, descricao)
        VALUES (p_id_boleto, 'CANCELAMENTO', 'Boleto cancelado');

        COMMIT;
    END cancelar_boleto;

    PROCEDURE registrar_pagamento(p_id_boleto IN NUMBER, p_data_pagamento IN DATE, p_valor_pago IN NUMBER) IS
    BEGIN
        UPDATE boletos
        SET status = 'PAGO', data_pagamento = p_data_pagamento, valor_pago = p_valor_pago
        WHERE id_boleto = p_id_boleto AND status NOT IN ('PAGO', 'CANCELADO');

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20206, 'Boleto não encontrado ou já foi pago/cancelado');
        END IF;

        INSERT INTO boleto_historico (id_boleto, tipo_evento, descricao)
        VALUES (p_id_boleto, 'PAGAMENTO', 'Boleto pago - Valor: ' || TO_CHAR(p_valor_pago, 'FM999G999G999D00'));

        COMMIT;
    END registrar_pagamento;

    FUNCTION consultar_boleto(p_id_boleto IN NUMBER) RETURN CLOB IS
        v_json CLOB;
    BEGIN
        SELECT JSON_OBJECT(
            'id_boleto' VALUE b.id_boleto,
            'numero_documento' VALUE b.numero_documento,
            'nosso_numero' VALUE b.nosso_numero,
            'data_vencimento' VALUE TO_CHAR(b.data_vencimento, 'YYYY-MM-DD'),
            'valor_documento' VALUE b.valor_documento,
            'status' VALUE b.status,
            'codigo_barras' VALUE b.codigo_barras,
            'linha_digitavel' VALUE b.linha_digitavel
            RETURNING CLOB
        ) INTO v_json
        FROM boletos b WHERE b.id_boleto = p_id_boleto;

        RETURN v_json;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN JSON_OBJECT('error' VALUE 'Boleto não encontrado');
    END consultar_boleto;

    FUNCTION consultar_por_nosso_numero(p_id_conta IN NUMBER, p_nosso_numero IN VARCHAR2) RETURN CLOB IS
        v_id_boleto NUMBER;
    BEGIN
        SELECT id_boleto INTO v_id_boleto FROM boletos
        WHERE id_conta = p_id_conta AND nosso_numero = p_nosso_numero;
        RETURN consultar_boleto(v_id_boleto);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN JSON_OBJECT('error' VALUE 'Boleto não encontrado');
    END consultar_por_nosso_numero;

    FUNCTION listar_boletos(p_id_cedente IN NUMBER DEFAULT NULL, p_id_sacado IN NUMBER DEFAULT NULL,
        p_data_vencimento_inicio IN DATE DEFAULT NULL, p_data_vencimento_fim IN DATE DEFAULT NULL,
        p_status IN VARCHAR2 DEFAULT NULL, p_limit IN NUMBER DEFAULT 100, p_offset IN NUMBER DEFAULT 0) RETURN CLOB IS
        v_json CLOB;
    BEGIN
        SELECT JSON_ARRAYAGG(JSON_OBJECT('id_boleto' VALUE b.id_boleto RETURNING CLOB)) INTO v_json
        FROM (SELECT * FROM boletos b JOIN boleto_contas bc ON b.id_conta = bc.id_conta
              WHERE (p_id_cedente IS NULL OR bc.id_cedente = p_id_cedente)
                AND (p_id_sacado IS NULL OR b.id_sacado = p_id_sacado)
                AND (p_status IS NULL OR b.status = p_status)
              ORDER BY b.created_at DESC OFFSET p_offset ROWS FETCH NEXT p_limit ROWS ONLY) b;
        RETURN NVL(v_json, JSON_ARRAY());
    END listar_boletos;

END pkg_boleto_manager;
/

PROMPT PKG_BOLETO_MANAGER atualizado!
PROMPT
PROMPT =========================================================
PROMPT Atualização concluída!
PROMPT =========================================================
