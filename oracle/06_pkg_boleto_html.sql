-- ============================================================================
-- Package: PKG_BOLETO_HTML
-- Geração de HTML para visualização e impressão de boletos
-- ============================================================================

CREATE OR REPLACE PACKAGE pkg_boleto_html AS

    -- Gerar HTML completo do boleto
    FUNCTION gerar_html(p_id_boleto IN NUMBER) RETURN CLOB;

    -- Gerar múltiplos boletos em um único HTML (carnê)
    FUNCTION gerar_html_lote(p_ids_boletos IN VARCHAR2) RETURN CLOB;

    -- Gerar apenas o código de barras SVG
    FUNCTION gerar_barcode_svg(p_codigo_barras IN VARCHAR2) RETURN CLOB;

END pkg_boleto_html;
/

CREATE OR REPLACE PACKAGE BODY pkg_boleto_html AS

    -- CSS para o boleto
    FUNCTION get_css RETURN CLOB IS
    BEGIN
        RETURN q'[
<style>
    * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
    }

    body {
        font-family: Arial, sans-serif;
        font-size: 10pt;
        margin: 0;
        padding: 20px;
    }

    .boleto-container {
        width: 666px;
        margin: 0 auto;
        page-break-after: always;
    }

    .corte {
        border-top: 1px dashed #000;
        margin: 10px 0;
        padding-top: 10px;
        text-align: left;
        font-size: 8pt;
    }

    table {
        width: 100%;
        border-collapse: collapse;
        margin-bottom: 0;
    }

    td {
        border: 1px solid #000;
        padding: 3px;
        vertical-align: top;
    }

    .label {
        font-size: 7pt;
        font-weight: normal;
    }

    .value {
        font-size: 10pt;
        font-weight: bold;
        margin-top: 2px;
    }

    .header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        border: 1px solid #000;
        padding: 5px;
        margin-bottom: 2px;
    }

    .logo {
        height: 20px;
    }

    .banco-codigo {
        font-size: 14pt;
        font-weight: bold;
        border-left: 2px solid #000;
        border-right: 2px solid #000;
        padding: 0 10px;
    }

    .linha-digitavel {
        font-size: 12pt;
        font-weight: bold;
        text-align: right;
        flex-grow: 1;
        padding-right: 5px;
    }

    .barcode {
        text-align: center;
        margin: 10px 0;
    }

    .barcode-image {
        height: 50px;
    }

    .instrucoes, .demonstrativo {
        border: 1px solid #000;
        padding: 5px;
        min-height: 80px;
        margin-top: 2px;
        font-size: 9pt;
    }

    .titulo-secao {
        font-weight: bold;
        font-size: 8pt;
        margin-bottom: 5px;
    }

    @media print {
        body {
            padding: 0;
        }
        .boleto-container {
            page-break-after: always;
        }
    }
</style>
]';
    END get_css;

    -- ========================================================================
    -- FUNCTION: gerar_barcode_svg
    -- Gera representação SVG simplificada do código de barras
    -- (Implementação completa requer lógica de barras 2of5 Intercalado)
    -- ========================================================================
    FUNCTION gerar_barcode_svg(p_codigo_barras IN VARCHAR2) RETURN CLOB IS
        v_svg CLOB;
        v_width NUMBER := 2;
        v_x NUMBER := 0;
        v_i NUMBER;
        v_digito NUMBER;
    BEGIN
        v_svg := '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 100" width="400" height="100">';

        -- Implementação simplificada - cada dígito vira uma barra
        -- Para implementação completa, use 2of5 Intercalado
        FOR v_i IN 1..LENGTH(p_codigo_barras) LOOP
            v_digito := TO_NUMBER(SUBSTR(p_codigo_barras, v_i, 1));

            -- Alterna entre barras pretas e brancas
            IF MOD(v_i, 2) = 1 THEN
                v_svg := v_svg || '<rect x="' || v_x || '" y="0" width="' || v_width ||
                        '" height="100" fill="black"/>';
            END IF;

            v_x := v_x + v_width + 1;
        END LOOP;

        v_svg := v_svg || '</svg>';

        RETURN v_svg;
    END gerar_barcode_svg;

    -- ========================================================================
    -- FUNCTION: gerar_html
    -- Gera HTML completo do boleto
    -- ========================================================================
    FUNCTION gerar_html(p_id_boleto IN NUMBER) RETURN CLOB IS
        v_html CLOB;
        v_barcode_svg CLOB;

        -- Variáveis do boleto
        v_codigo_banco VARCHAR2(3);
        v_nome_banco VARCHAR2(100);
        v_codigo_barras VARCHAR2(44);
        v_linha_digitavel VARCHAR2(54);
        v_local_pagamento VARCHAR2(200);
        v_data_vencimento DATE;
        v_cedente_nome VARCHAR2(200);
        v_cedente_doc VARCHAR2(18);
        v_cedente_end VARCHAR2(1000);
        v_agencia VARCHAR2(10);
        v_agencia_dv VARCHAR2(2);
        v_conta VARCHAR2(20);
        v_conta_dv VARCHAR2(2);
        v_carteira VARCHAR2(10);
        v_nosso_numero VARCHAR2(20);
        v_numero_documento VARCHAR2(50);
        v_data_documento DATE;
        v_data_processamento DATE;
        v_especie VARCHAR2(10);
        v_aceite CHAR(1);
        v_valor_documento NUMBER;
        v_sacado_nome VARCHAR2(200);
        v_sacado_doc VARCHAR2(18);
        v_sacado_end VARCHAR2(1000);
        v_instrucoes CLOB;
        v_demonstrativo CLOB;
    BEGIN
        -- Buscar dados do boleto
        SELECT
            bb.codigo_banco,
            bb.nome_banco,
            b.codigo_barras,
            b.linha_digitavel,
            b.local_pagamento,
            b.data_vencimento,
            ce.nome,
            ce.documento,
            ce.endereco_completo,
            bc.agencia,
            bc.agencia_dv,
            bc.conta,
            bc.conta_dv,
            bc.carteira,
            b.nosso_numero,
            b.numero_documento,
            b.data_documento,
            b.data_processamento,
            b.especie_documento,
            b.aceite,
            b.valor_documento,
            sa.nome,
            sa.documento,
            sa.endereco_completo,
            b.instrucoes,
            b.demonstrativo
        INTO
            v_codigo_banco,
            v_nome_banco,
            v_codigo_barras,
            v_linha_digitavel,
            v_local_pagamento,
            v_data_vencimento,
            v_cedente_nome,
            v_cedente_doc,
            v_cedente_end,
            v_agencia,
            v_agencia_dv,
            v_conta,
            v_conta_dv,
            v_carteira,
            v_nosso_numero,
            v_numero_documento,
            v_data_documento,
            v_data_processamento,
            v_especie,
            v_aceite,
            v_valor_documento,
            v_sacado_nome,
            v_sacado_doc,
            v_sacado_end,
            v_instrucoes,
            v_demonstrativo
        FROM boletos b
        JOIN boleto_contas bc ON b.id_conta = bc.id_conta
        JOIN boleto_cedentes ce ON bc.id_cedente = ce.id_cedente
        JOIN boleto_sacados sa ON b.id_sacado = sa.id_sacado
        JOIN boleto_bancos bb ON bc.id_banco = bb.id_banco
        WHERE b.id_boleto = p_id_boleto;

        -- Gerar barcode SVG
        v_barcode_svg := gerar_barcode_svg(v_codigo_barras);

        -- Montar HTML
        v_html := '<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Boleto Bancário - ' || v_numero_documento || '</title>
    ' || get_css || '
</head>
<body>
    <div class="boleto-container">

        <!-- Recibo do Sacado -->
        <div class="corte">✂ Recibo do Sacado</div>

        <div class="header">
            <div class="banco-nome">' || v_nome_banco || '</div>
            <div class="banco-codigo">' || v_codigo_banco || '-9</div>
            <div class="linha-digitavel">' || v_linha_digitavel || '</div>
        </div>

        <table>
            <tr>
                <td style="width: 70%;">
                    <div class="label">Local de Pagamento</div>
                    <div class="value">' || v_local_pagamento || '</div>
                </td>
                <td style="width: 30%;">
                    <div class="label">Vencimento</div>
                    <div class="value">' || TO_CHAR(v_data_vencimento, 'DD/MM/YYYY') || '</div>
                </td>
            </tr>
            <tr>
                <td>
                    <div class="label">Cedente</div>
                    <div class="value">' || v_cedente_nome || '</div>
                    <div>' || v_cedente_doc || '</div>
                </td>
                <td>
                    <div class="label">Agência/Código Cedente</div>
                    <div class="value">' || v_agencia ||
                        CASE WHEN v_agencia_dv IS NOT NULL THEN '-' || v_agencia_dv END ||
                        ' / ' || v_conta ||
                        CASE WHEN v_conta_dv IS NOT NULL THEN '-' || v_conta_dv END ||
                    '</div>
                </td>
            </tr>
            <tr>
                <td style="width: 25%;">
                    <div class="label">Data do Documento</div>
                    <div class="value">' || TO_CHAR(v_data_documento, 'DD/MM/YYYY') || '</div>
                </td>
                <td style="width: 25%;">
                    <div class="label">Nº do Documento</div>
                    <div class="value">' || v_numero_documento || '</div>
                </td>
                <td style="width: 25%;">
                    <div class="label">Espécie Doc.</div>
                    <div class="value">' || v_especie || '</div>
                </td>
                <td style="width: 25%;">
                    <div class="label">Aceite</div>
                    <div class="value">' || v_aceite || '</div>
                </td>
            </tr>
            <tr>
                <td style="width: 25%;">
                    <div class="label">Data Processamento</div>
                    <div class="value">' || TO_CHAR(v_data_processamento, 'DD/MM/YYYY') || '</div>
                </td>
                <td style="width: 25%;">
                    <div class="label">Nosso Número</div>
                    <div class="value">' || v_nosso_numero || '</div>
                </td>
                <td style="width: 25%;">
                    <div class="label">Carteira</div>
                    <div class="value">' || v_carteira || '</div>
                </td>
                <td style="width: 25%;">
                    <div class="label">Valor do Documento</div>
                    <div class="value">R$ ' || TO_CHAR(v_valor_documento, 'FM999G999G999D00') || '</div>
                </td>
            </tr>
        </table>

        <div class="instrucoes">
            <div class="titulo-secao">Instruções (Texto de responsabilidade do cedente)</div>
            <div>' || REPLACE(v_instrucoes, CHR(10), '<br>') || '</div>
        </div>

        <table>
            <tr>
                <td>
                    <div class="label">Sacado</div>
                    <div class="value">' || v_sacado_nome || '</div>
                    <div>' || v_sacado_doc || '</div>
                    <div>' || v_sacado_end || '</div>
                </td>
            </tr>
        </table>

        <!-- Ficha de Compensação -->
        <div class="corte">✂ Ficha de Compensação</div>

        <div class="header">
            <div class="banco-nome">' || v_nome_banco || '</div>
            <div class="banco-codigo">' || v_codigo_banco || '-9</div>
            <div class="linha-digitavel">' || v_linha_digitavel || '</div>
        </div>

        <table>
            <tr>
                <td style="width: 70%;">
                    <div class="label">Local de Pagamento</div>
                    <div class="value">' || v_local_pagamento || '</div>
                </td>
                <td style="width: 30%;">
                    <div class="label">Vencimento</div>
                    <div class="value">' || TO_CHAR(v_data_vencimento, 'DD/MM/YYYY') || '</div>
                </td>
            </tr>
            <tr>
                <td>
                    <div class="label">Cedente</div>
                    <div class="value">' || v_cedente_nome || '</div>
                </td>
                <td>
                    <div class="label">Agência/Código Cedente</div>
                    <div class="value">' || v_agencia ||
                        CASE WHEN v_agencia_dv IS NOT NULL THEN '-' || v_agencia_dv END ||
                        ' / ' || v_conta ||
                        CASE WHEN v_conta_dv IS NOT NULL THEN '-' || v_conta_dv END ||
                    '</div>
                </td>
            </tr>
            <tr>
                <td colspan="2">
                    <div class="label">Demonstrativo</div>
                    <div>' || REPLACE(v_demonstrativo, CHR(10), '<br>') || '</div>
                </td>
            </tr>
        </table>

        <div class="barcode">
            ' || v_barcode_svg || '
            <div style="font-family: monospace; font-size: 10pt; margin-top: 5px;">' ||
                v_codigo_barras || '
            </div>
        </div>

        <table>
            <tr>
                <td>
                    <div class="label">Sacado</div>
                    <div class="value">' || v_sacado_nome || '</div>
                    <div>' || v_sacado_doc || '</div>
                    <div>' || v_sacado_end || '</div>
                </td>
            </tr>
        </table>

    </div>
</body>
</html>';

        RETURN v_html;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20301, 'Boleto não encontrado');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20302, 'Erro ao gerar HTML: ' || SQLERRM);
    END gerar_html;

    -- ========================================================================
    -- FUNCTION: gerar_html_lote
    -- Gera HTML com múltiplos boletos (carnê)
    -- ========================================================================
    FUNCTION gerar_html_lote(p_ids_boletos IN VARCHAR2) RETURN CLOB IS
        v_html CLOB;
        v_id_boleto NUMBER;
        v_pos NUMBER;
        v_ids VARCHAR2(4000) := p_ids_boletos || ',';
        v_boleto_html CLOB;
    BEGIN
        v_html := '<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Carnê de Boletos</title>
    ' || get_css || '
</head>
<body>';

        LOOP
            v_pos := INSTR(v_ids, ',');
            EXIT WHEN v_pos = 0;

            v_id_boleto := TO_NUMBER(SUBSTR(v_ids, 1, v_pos - 1));
            v_boleto_html := gerar_html(v_id_boleto);

            -- Extrai apenas o corpo do boleto
            v_html := v_html || REGEXP_SUBSTR(v_boleto_html, '<div class="boleto-container">.*?</div>', 1, 1, 'n');

            v_ids := SUBSTR(v_ids, v_pos + 1);
        END LOOP;

        v_html := v_html || '
</body>
</html>';

        RETURN v_html;
    END gerar_html_lote;

END pkg_boleto_html;
/
