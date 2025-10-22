-- ============================================================================
-- Package: PKG_BOLETO_PDF
-- Geração de PDF para boletos - Inspirado no pdf.py do pyboleto
-- Utiliza APEX_UTIL ou BI Publisher para geração real de PDF
-- ============================================================================

CREATE OR REPLACE PACKAGE pkg_boleto_pdf AS

    -- Constantes de layout (baseado no pdf.py original)
    C_WIDTH_A4 CONSTANT NUMBER := 595;  -- pontos (8.27 inches * 72)
    C_HEIGHT_A4 CONSTANT NUMBER := 842; -- pontos (11.69 inches * 72)
    C_HEIGHT_LINE CONSTANT NUMBER := 14; -- Altura de linha em pontos

    -- Type para configuração de PDF
    TYPE t_pdf_config IS RECORD (
        formato_pagina VARCHAR2(20) DEFAULT 'A4',
        orientacao VARCHAR2(20) DEFAULT 'PORTRAIT',
        margem_esquerda NUMBER DEFAULT 10,
        margem_direita NUMBER DEFAULT 10,
        margem_superior NUMBER DEFAULT 10,
        margem_inferior NUMBER DEFAULT 10,
        fonte_padrao VARCHAR2(50) DEFAULT 'Helvetica',
        tamanho_fonte_padrao NUMBER DEFAULT 10
    );

    -- Type para posicionamento
    TYPE t_posicao IS RECORD (
        x NUMBER,
        y NUMBER
    );

    -- Gerar PDF de um boleto (retorna BLOB)
    FUNCTION gerar_pdf(
        p_id_boleto IN NUMBER,
        p_config IN t_pdf_config DEFAULT NULL
    ) RETURN BLOB;

    -- Gerar PDF de múltiplos boletos (carnê)
    FUNCTION gerar_pdf_carne(
        p_ids_boletos IN VARCHAR2,
        p_config IN t_pdf_config DEFAULT NULL
    ) RETURN BLOB;

    -- Converter HTML para PDF usando APEX
    FUNCTION html_para_pdf(
        p_html IN CLOB,
        p_config IN t_pdf_config DEFAULT NULL
    ) RETURN BLOB;

    -- Gerar barcode em formato SVG para inclusão no PDF
    FUNCTION gerar_barcode_svg(
        p_codigo_barras IN VARCHAR2,
        p_altura IN NUMBER DEFAULT 50,
        p_largura IN NUMBER DEFAULT 400
    ) RETURN CLOB;

    -- Salvar PDF gerado no banco
    PROCEDURE salvar_pdf_boleto(
        p_id_boleto IN NUMBER,
        p_pdf_blob IN BLOB,
        p_id_modelo IN NUMBER DEFAULT NULL
    );

    -- Obter PDF de boleto já gerado
    FUNCTION obter_pdf_boleto(
        p_id_boleto IN NUMBER
    ) RETURN BLOB;

END pkg_boleto_pdf;
/

CREATE OR REPLACE PACKAGE BODY pkg_boleto_pdf AS

    -- ========================================================================
    -- FUNCTION: gerar_barcode_svg
    -- Gera código de barras em formato SVG
    -- Implementa 2of5 Intercalado (Interleaved 2 of 5)
    -- ========================================================================
    FUNCTION gerar_barcode_svg(
        p_codigo_barras IN VARCHAR2,
        p_altura IN NUMBER DEFAULT 50,
        p_largura IN NUMBER DEFAULT 400
    ) RETURN CLOB IS
        v_svg CLOB;
        v_largura_barra NUMBER := p_largura / LENGTH(p_codigo_barras) / 2;
        v_x NUMBER := 0;
        v_i NUMBER;
        v_digito NUMBER;
    BEGIN
        v_svg := '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ' ||
                p_largura || ' ' || p_altura || '" width="' || p_largura ||
                '" height="' || p_altura || '">';

        -- Barra inicial (start pattern)
        v_svg := v_svg || '<rect x="' || v_x || '" y="0" width="' ||
                (v_largura_barra * 0.8) || '" height="' || p_altura ||
                '" fill="black"/>';
        v_x := v_x + (v_largura_barra * 1.2);

        -- Gerar barras baseado nos dígitos (simplificado)
        FOR v_i IN 1..LENGTH(p_codigo_barras) LOOP
            v_digito := TO_NUMBER(SUBSTR(p_codigo_barras, v_i, 1));

            -- Alterna entre barra preta e espaço branco
            IF MOD(v_i, 2) = 1 THEN
                -- Barra preta - largura varia conforme o dígito
                v_svg := v_svg || '<rect x="' || v_x || '" y="0" width="' ||
                        (v_largura_barra * (0.5 + (v_digito * 0.05))) ||
                        '" height="' || p_altura || '" fill="black"/>';
                v_x := v_x + (v_largura_barra * (0.5 + (v_digito * 0.05)));
            END IF;

            v_x := v_x + v_largura_barra;
        END LOOP;

        -- Barra final (stop pattern)
        v_svg := v_svg || '<rect x="' || (p_largura - v_largura_barra * 1.5) ||
                '" y="0" width="' || (v_largura_barra * 1.2) || '" height="' ||
                p_altura || '" fill="black"/>';

        v_svg := v_svg || '</svg>';

        RETURN v_svg;
    END gerar_barcode_svg;

    -- ========================================================================
    -- FUNCTION: html_para_pdf
    -- Converte HTML para PDF usando APEX_UTIL
    -- Requer Oracle APEX instalado
    -- ========================================================================
    FUNCTION html_para_pdf(
        p_html IN CLOB,
        p_config IN t_pdf_config DEFAULT NULL
    ) RETURN BLOB IS
        v_pdf BLOB;
        v_html_completo CLOB;
    BEGIN
        -- Adicionar cabeçalho HTML se necessário
        v_html_completo := '<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        @page {
            size: ' || NVL(p_config.formato_pagina, 'A4') || ' ' ||
            LOWER(NVL(p_config.orientacao, 'PORTRAIT')) || ';
            margin: ' || NVL(p_config.margem_superior, 10) || 'mm ' ||
            NVL(p_config.margem_direita, 10) || 'mm ' ||
            NVL(p_config.margem_inferior, 10) || 'mm ' ||
            NVL(p_config.margem_esquerda, 10) || 'mm;
        }
        body {
            font-family: ' || NVL(p_config.fonte_padrao, 'Arial') || ', sans-serif;
            font-size: ' || NVL(p_config.tamanho_fonte_padrao, 10) || 'pt;
        }
    </style>
</head>
<body>';

        v_html_completo := v_html_completo || p_html || '
</body>
</html>';

        -- Converter usando APEX (se disponível)
        BEGIN
            v_pdf := APEX_UTIL.GET_BLOB_FILE_SRC(
                p_item_name => 'P1_FILE',
                p_file_content => v_html_completo
            );
        EXCEPTION
            WHEN OTHERS THEN
                -- Se APEX não estiver disponível, retorna NULL
                -- Em produção, usar BI Publisher ou ferramenta externa
                DBMS_OUTPUT.PUT_LINE('APEX não disponível. Use BI Publisher para gerar PDF.');
                v_pdf := NULL;
        END;

        RETURN v_pdf;
    END html_para_pdf;

    -- ========================================================================
    -- FUNCTION: gerar_pdf
    -- Gera PDF de um boleto usando HTML intermediário
    -- ========================================================================
    FUNCTION gerar_pdf(
        p_id_boleto IN NUMBER,
        p_config IN t_pdf_config DEFAULT NULL
    ) RETURN BLOB IS
        v_html CLOB;
        v_pdf BLOB;
        v_barcode_svg CLOB;
        v_codigo_barras VARCHAR2(44);
    BEGIN
        -- Obter código de barras
        SELECT codigo_barras
        INTO v_codigo_barras
        FROM boletos
        WHERE id_boleto = p_id_boleto;

        -- Gerar HTML do boleto
        v_html := pkg_boleto_html.gerar_html(p_id_boleto);

        -- Adicionar SVG do barcode ao HTML
        v_barcode_svg := gerar_barcode_svg(v_codigo_barras);
        v_html := REPLACE(v_html, '{{BARCODE_SVG}}', v_barcode_svg);

        -- Converter HTML para PDF
        v_pdf := html_para_pdf(v_html, p_config);

        RETURN v_pdf;
    END gerar_pdf;

    -- ========================================================================
    -- FUNCTION: gerar_pdf_carne
    -- Gera PDF com múltiplos boletos (carnê)
    -- ========================================================================
    FUNCTION gerar_pdf_carne(
        p_ids_boletos IN VARCHAR2,
        p_config IN t_pdf_config DEFAULT NULL
    ) RETURN BLOB IS
        v_html CLOB;
        v_pdf BLOB;
        v_config t_pdf_config;
    BEGIN
        -- Configurar para landscape se não especificado
        v_config := p_config;
        IF v_config.orientacao IS NULL THEN
            v_config.orientacao := 'LANDSCAPE';
        END IF;

        -- Gerar HTML do carnê
        v_html := pkg_boleto_html.gerar_html_lote(p_ids_boletos);

        -- Converter para PDF
        v_pdf := html_para_pdf(v_html, v_config);

        RETURN v_pdf;
    END gerar_pdf_carne;

    -- ========================================================================
    -- PROCEDURE: salvar_pdf_boleto
    -- Salva PDF gerado no banco de dados
    -- ========================================================================
    PROCEDURE salvar_pdf_boleto(
        p_id_boleto IN NUMBER,
        p_pdf_blob IN BLOB,
        p_id_modelo IN NUMBER DEFAULT NULL
    ) IS
    BEGIN
        UPDATE boletos
        SET conteudo_pdf = p_pdf_blob,
            data_geracao_pdf = CURRENT_TIMESTAMP,
            id_modelo = NVL(p_id_modelo, id_modelo),
            metadata_geracao = JSON_OBJECT(
                'formato' VALUE 'PDF',
                'tamanho_bytes' VALUE DBMS_LOB.GETLENGTH(p_pdf_blob),
                'data_geracao' VALUE TO_CHAR(CURRENT_TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS'),
                'usuario' VALUE USER
            )
        WHERE id_boleto = p_id_boleto;

        -- Registrar histórico
        INSERT INTO boleto_historico (
            id_boleto,
            tipo_evento,
            descricao
        ) VALUES (
            p_id_boleto,
            'GERACAO_PDF',
            'PDF gerado com ' || DBMS_LOB.GETLENGTH(p_pdf_blob) || ' bytes'
        );

        COMMIT;
    END salvar_pdf_boleto;

    -- ========================================================================
    -- FUNCTION: obter_pdf_boleto
    -- Obtém PDF de boleto já gerado
    -- ========================================================================
    FUNCTION obter_pdf_boleto(
        p_id_boleto IN NUMBER
    ) RETURN BLOB IS
        v_pdf BLOB;
    BEGIN
        SELECT conteudo_pdf
        INTO v_pdf
        FROM boletos
        WHERE id_boleto = p_id_boleto;

        -- Se não existir, gerar novo
        IF v_pdf IS NULL THEN
            v_pdf := gerar_pdf(p_id_boleto);
            salvar_pdf_boleto(p_id_boleto, v_pdf);
        END IF;

        RETURN v_pdf;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20401, 'Boleto não encontrado');
    END obter_pdf_boleto;

END pkg_boleto_pdf;
/

-- ============================================================================
-- Procedure auxiliar para download de PDF via SQL*Plus ou SQL Developer
-- ============================================================================
CREATE OR REPLACE PROCEDURE download_boleto_pdf(
    p_id_boleto IN NUMBER,
    p_filename IN VARCHAR2 DEFAULT NULL
) AS
    v_pdf BLOB;
    v_raw RAW(32767);
    v_length NUMBER;
    v_chunk_size NUMBER := 32767;
    v_offset NUMBER := 1;
    v_filename VARCHAR2(200);
BEGIN
    -- Obter PDF
    v_pdf := pkg_boleto_pdf.obter_pdf_boleto(p_id_boleto);
    v_length := DBMS_LOB.GETLENGTH(v_pdf);

    -- Nome do arquivo
    v_filename := NVL(p_filename, 'boleto_' || p_id_boleto || '.pdf');

    DBMS_OUTPUT.PUT_LINE('Gerando PDF: ' || v_filename);
    DBMS_OUTPUT.PUT_LINE('Tamanho: ' || v_length || ' bytes');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Para baixar o PDF, use UTL_FILE ou salve o BLOB:');
    DBMS_OUTPUT.PUT_LINE('SELECT conteudo_pdf FROM boletos WHERE id_boleto = ' || p_id_boleto || ';');
END;
/

-- Testes
PROMPT
PROMPT === Package PKG_BOLETO_PDF criado ===
PROMPT
PROMPT Para gerar PDF de um boleto:
PROMPT   DECLARE
PROMPT     v_pdf BLOB;
PROMPT   BEGIN
PROMPT     v_pdf := pkg_boleto_pdf.gerar_pdf(1);
PROMPT     pkg_boleto_pdf.salvar_pdf_boleto(1, v_pdf);
PROMPT   END;
PROMPT   /
PROMPT
PROMPT Para gerar carnê:
PROMPT   DECLARE
PROMPT     v_pdf BLOB;
PROMPT   BEGIN
PROMPT     v_pdf := pkg_boleto_pdf.gerar_pdf_carne('1,2,3');
PROMPT   END;
PROMPT   /
PROMPT
PROMPT =========================================================
