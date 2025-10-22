-- ============================================================================
-- Package: PKG_BOLETO_MANAGER
-- Gerenciamento completo de boletos (CRUD e operações)
-- ============================================================================

CREATE OR REPLACE PACKAGE pkg_boleto_manager AS

    -- Type para JSON response
    TYPE t_json_response IS RECORD (
        success BOOLEAN,
        message VARCHAR2(4000),
        data CLOB
    );

    -- Criar novo boleto
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
    ) RETURN NUMBER;

    -- Atualizar boleto existente
    PROCEDURE atualizar_boleto(
        p_id_boleto IN NUMBER,
        p_data_vencimento IN DATE DEFAULT NULL,
        p_valor_documento IN NUMBER DEFAULT NULL,
        p_instrucoes IN CLOB DEFAULT NULL,
        p_demonstrativo IN CLOB DEFAULT NULL
    );

    -- Cancelar boleto
    PROCEDURE cancelar_boleto(p_id_boleto IN NUMBER);

    -- Registrar pagamento
    PROCEDURE registrar_pagamento(
        p_id_boleto IN NUMBER,
        p_data_pagamento IN DATE,
        p_valor_pago IN NUMBER
    );

    -- Consultar boleto por ID
    FUNCTION consultar_boleto(p_id_boleto IN NUMBER) RETURN CLOB;

    -- Consultar boleto por nosso número
    FUNCTION consultar_por_nosso_numero(
        p_id_conta IN NUMBER,
        p_nosso_numero IN VARCHAR2
    ) RETURN CLOB;

    -- Listar boletos por filtros
    FUNCTION listar_boletos(
        p_id_cedente IN NUMBER DEFAULT NULL,
        p_id_sacado IN NUMBER DEFAULT NULL,
        p_data_vencimento_inicio IN DATE DEFAULT NULL,
        p_data_vencimento_fim IN DATE DEFAULT NULL,
        p_status IN VARCHAR2 DEFAULT NULL,
        p_limit IN NUMBER DEFAULT 100,
        p_offset IN NUMBER DEFAULT 0
    ) RETURN CLOB;

    -- Gerar boleto (recalcula código de barras)
    PROCEDURE gerar_boleto(p_id_boleto IN NUMBER);

    -- Gerar múltiplos boletos em lote
    PROCEDURE gerar_boletos_lote(p_ids_boletos IN VARCHAR2); -- IDs separados por vírgula

END pkg_boleto_manager;
/

CREATE OR REPLACE PACKAGE BODY pkg_boleto_manager AS

    -- ========================================================================
    -- FUNCTION: criar_boleto
    -- Cria um novo boleto e gera o código de barras automaticamente
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
        -- Define local de pagamento padrão
        v_local_pag := NVL(p_local_pagamento, 'Pagável em qualquer banco até o vencimento');

        -- Insere boleto
        INSERT INTO boletos (
            id_conta,
            id_sacado,
            numero_documento,
            nosso_numero,
            data_documento,
            data_vencimento,
            data_processamento,
            valor_documento,
            instrucoes,
            demonstrativo,
            especie_documento,
            aceite,
            local_pagamento,
            status
        ) VALUES (
            p_id_conta,
            p_id_sacado,
            p_numero_documento,
            p_nosso_numero,
            p_data_documento,
            p_data_vencimento,
            SYSDATE,
            p_valor_documento,
            p_instrucoes,
            p_demonstrativo,
            p_especie_documento,
            p_aceite,
            v_local_pag,
            'GERADO'
        ) RETURNING id_boleto INTO v_id_boleto;

        -- Gera código de barras
        gerar_boleto(v_id_boleto);

        -- Registra histórico
        INSERT INTO boleto_historico (
            id_boleto,
            tipo_evento,
            descricao
        ) VALUES (
            v_id_boleto,
            'CRIACAO',
            'Boleto criado com sucesso'
        );

        COMMIT;
        RETURN v_id_boleto;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20201, 'Boleto com este nosso número já existe para esta conta');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20202, 'Erro ao criar boleto: ' || SQLERRM);
    END criar_boleto;

    -- ========================================================================
    -- PROCEDURE: gerar_boleto
    -- Gera/recalcula o código de barras do boleto
    -- ========================================================================
    PROCEDURE gerar_boleto(p_id_boleto IN NUMBER) IS
        v_calculo pkg_boleto_barcode.t_boleto_calculado;
    BEGIN
        -- Gera código de barras
        v_calculo := pkg_boleto_barcode.gerar_codigo_barras(p_id_boleto);

        -- Atualiza boleto com os valores calculados
        UPDATE boletos
        SET codigo_barras = v_calculo.codigo_barras,
            linha_digitavel = v_calculo.linha_digitavel_formatada,
            dv_codigo_barras = v_calculo.dv_codigo_barras,
            campo_livre = v_calculo.campo_livre,
            updated_at = CURRENT_TIMESTAMP
        WHERE id_boleto = p_id_boleto;

        -- Registra histórico
        INSERT INTO boleto_historico (
            id_boleto,
            tipo_evento,
            descricao
        ) VALUES (
            p_id_boleto,
            'GERACAO',
            'Código de barras gerado: ' || v_calculo.codigo_barras
        );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20203, 'Erro ao gerar código de barras: ' || SQLERRM);
    END gerar_boleto;

    -- ========================================================================
    -- PROCEDURE: gerar_boletos_lote
    -- Gera múltiplos boletos em lote
    -- ========================================================================
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

    -- ========================================================================
    -- PROCEDURE: atualizar_boleto
    -- Atualiza informações do boleto
    -- ========================================================================
    PROCEDURE atualizar_boleto(
        p_id_boleto IN NUMBER,
        p_data_vencimento IN DATE DEFAULT NULL,
        p_valor_documento IN NUMBER DEFAULT NULL,
        p_instrucoes IN CLOB DEFAULT NULL,
        p_demonstrativo IN CLOB DEFAULT NULL
    ) IS
        v_count NUMBER;
    BEGIN
        -- Verifica se boleto existe e não está pago/cancelado
        SELECT COUNT(*)
        INTO v_count
        FROM boletos
        WHERE id_boleto = p_id_boleto
        AND status NOT IN ('PAGO', 'CANCELADO');

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20204, 'Boleto não encontrado ou não pode ser atualizado');
        END IF;

        -- Atualiza campos fornecidos
        UPDATE boletos
        SET data_vencimento = NVL(p_data_vencimento, data_vencimento),
            valor_documento = NVL(p_valor_documento, valor_documento),
            instrucoes = NVL(p_instrucoes, instrucoes),
            demonstrativo = NVL(p_demonstrativo, demonstrativo)
        WHERE id_boleto = p_id_boleto;

        -- Recalcula código de barras se valor ou vencimento mudaram
        IF p_data_vencimento IS NOT NULL OR p_valor_documento IS NOT NULL THEN
            gerar_boleto(p_id_boleto);
        END IF;

        -- Registra histórico
        INSERT INTO boleto_historico (
            id_boleto,
            tipo_evento,
            descricao
        ) VALUES (
            p_id_boleto,
            'ATUALIZACAO',
            'Boleto atualizado'
        );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END atualizar_boleto;

    -- ========================================================================
    -- PROCEDURE: cancelar_boleto
    -- Cancela um boleto
    -- ========================================================================
    PROCEDURE cancelar_boleto(p_id_boleto IN NUMBER) IS
    BEGIN
        UPDATE boletos
        SET status = 'CANCELADO'
        WHERE id_boleto = p_id_boleto
        AND status NOT IN ('PAGO', 'CANCELADO');

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20205, 'Boleto não encontrado ou não pode ser cancelado');
        END IF;

        -- Registra histórico
        INSERT INTO boleto_historico (
            id_boleto,
            tipo_evento,
            descricao
        ) VALUES (
            p_id_boleto,
            'CANCELAMENTO',
            'Boleto cancelado'
        );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END cancelar_boleto;

    -- ========================================================================
    -- PROCEDURE: registrar_pagamento
    -- Registra pagamento de um boleto
    -- ========================================================================
    PROCEDURE registrar_pagamento(
        p_id_boleto IN NUMBER,
        p_data_pagamento IN DATE,
        p_valor_pago IN NUMBER
    ) IS
    BEGIN
        UPDATE boletos
        SET status = 'PAGO',
            data_pagamento = p_data_pagamento,
            valor_pago = p_valor_pago
        WHERE id_boleto = p_id_boleto
        AND status NOT IN ('PAGO', 'CANCELADO');

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20206, 'Boleto não encontrado ou já foi pago/cancelado');
        END IF;

        -- Registra histórico
        INSERT INTO boleto_historico (
            id_boleto,
            tipo_evento,
            descricao
        ) VALUES (
            p_id_boleto,
            'PAGAMENTO',
            'Boleto pago - Valor: ' || TO_CHAR(p_valor_pago, 'FM999G999G999D00')
        );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END registrar_pagamento;

    -- ========================================================================
    -- FUNCTION: consultar_boleto
    -- Retorna JSON com dados completos do boleto
    -- ========================================================================
    FUNCTION consultar_boleto(p_id_boleto IN NUMBER) RETURN CLOB IS
        v_json CLOB;
    BEGIN
        SELECT JSON_OBJECT(
            'id_boleto' VALUE b.id_boleto,
            'numero_documento' VALUE b.numero_documento,
            'nosso_numero' VALUE b.nosso_numero,
            'data_documento' VALUE TO_CHAR(b.data_documento, 'YYYY-MM-DD'),
            'data_vencimento' VALUE TO_CHAR(b.data_vencimento, 'YYYY-MM-DD'),
            'data_processamento' VALUE TO_CHAR(b.data_processamento, 'YYYY-MM-DD'),
            'valor_documento' VALUE b.valor_documento,
            'valor_pago' VALUE b.valor_pago,
            'status' VALUE b.status,
            'codigo_barras' VALUE b.codigo_barras,
            'linha_digitavel' VALUE b.linha_digitavel,
            'instrucoes' VALUE b.instrucoes,
            'demonstrativo' VALUE b.demonstrativo,
            'local_pagamento' VALUE b.local_pagamento,
            'especie_documento' VALUE b.especie_documento,
            'aceite' VALUE b.aceite,
            'banco' VALUE JSON_OBJECT(
                'codigo' VALUE bb.codigo_banco,
                'nome' VALUE bb.nome_banco
            ),
            'cedente' VALUE JSON_OBJECT(
                'nome' VALUE ce.nome,
                'documento' VALUE ce.documento,
                'endereco' VALUE ce.endereco_completo,
                'agencia' VALUE bc.agencia,
                'conta' VALUE bc.conta,
                'carteira' VALUE bc.carteira
            ),
            'sacado' VALUE JSON_OBJECT(
                'nome' VALUE sa.nome,
                'documento' VALUE sa.documento,
                'endereco' VALUE sa.endereco_completo
            )
            RETURNING CLOB
        )
        INTO v_json
        FROM boletos b
        JOIN boleto_contas bc ON b.id_conta = bc.id_conta
        JOIN boleto_cedentes ce ON bc.id_cedente = ce.id_cedente
        JOIN boleto_sacados sa ON b.id_sacado = sa.id_sacado
        JOIN boleto_bancos bb ON bc.id_banco = bb.id_banco
        WHERE b.id_boleto = p_id_boleto;

        RETURN v_json;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN JSON_OBJECT('error' VALUE 'Boleto não encontrado');
    END consultar_boleto;

    -- ========================================================================
    -- FUNCTION: consultar_por_nosso_numero
    -- Busca boleto por nosso número e conta
    -- ========================================================================
    FUNCTION consultar_por_nosso_numero(
        p_id_conta IN NUMBER,
        p_nosso_numero IN VARCHAR2
    ) RETURN CLOB IS
        v_id_boleto NUMBER;
    BEGIN
        SELECT id_boleto
        INTO v_id_boleto
        FROM boletos
        WHERE id_conta = p_id_conta
        AND nosso_numero = p_nosso_numero;

        RETURN consultar_boleto(v_id_boleto);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN JSON_OBJECT('error' VALUE 'Boleto não encontrado');
    END consultar_por_nosso_numero;

    -- ========================================================================
    -- FUNCTION: listar_boletos
    -- Lista boletos com filtros opcionais
    -- ========================================================================
    FUNCTION listar_boletos(
        p_id_cedente IN NUMBER DEFAULT NULL,
        p_id_sacado IN NUMBER DEFAULT NULL,
        p_data_vencimento_inicio IN DATE DEFAULT NULL,
        p_data_vencimento_fim IN DATE DEFAULT NULL,
        p_status IN VARCHAR2 DEFAULT NULL,
        p_limit IN NUMBER DEFAULT 100,
        p_offset IN NUMBER DEFAULT 0
    ) RETURN CLOB IS
        v_json CLOB;
    BEGIN
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'id_boleto' VALUE b.id_boleto,
                'numero_documento' VALUE b.numero_documento,
                'nosso_numero' VALUE b.nosso_numero,
                'data_vencimento' VALUE TO_CHAR(b.data_vencimento, 'YYYY-MM-DD'),
                'valor_documento' VALUE b.valor_documento,
                'status' VALUE b.status,
                'cedente_nome' VALUE ce.nome,
                'sacado_nome' VALUE sa.nome,
                'banco_nome' VALUE bb.nome_banco
            )
            RETURNING CLOB
        )
        INTO v_json
        FROM (
            SELECT *
            FROM boletos b
            JOIN boleto_contas bc ON b.id_conta = bc.id_conta
            WHERE (p_id_cedente IS NULL OR bc.id_cedente = p_id_cedente)
            AND (p_id_sacado IS NULL OR b.id_sacado = p_id_sacado)
            AND (p_data_vencimento_inicio IS NULL OR b.data_vencimento >= p_data_vencimento_inicio)
            AND (p_data_vencimento_fim IS NULL OR b.data_vencimento <= p_data_vencimento_fim)
            AND (p_status IS NULL OR b.status = p_status)
            ORDER BY b.created_at DESC
            OFFSET p_offset ROWS FETCH NEXT p_limit ROWS ONLY
        ) b
        JOIN boleto_contas bc ON b.id_conta = bc.id_conta
        JOIN boleto_cedentes ce ON bc.id_cedente = ce.id_cedente
        JOIN boleto_sacados sa ON b.id_sacado = sa.id_sacado
        JOIN boleto_bancos bb ON bc.id_banco = bb.id_banco;

        RETURN NVL(v_json, JSON_ARRAY());
    END listar_boletos;

END pkg_boleto_manager;
/
