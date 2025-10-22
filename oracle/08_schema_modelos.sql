-- ============================================================================
-- Extensão do Schema - Modelos de Boleto e Armazenamento de Conteúdo
-- ============================================================================

PROMPT =========================================================
PROMPT Criando estrutura para Modelos de Boleto
PROMPT =========================================================

-- Tabela de Modelos de Boleto
CREATE TABLE boleto_modelos (
    id_modelo               NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome_modelo             VARCHAR2(100) NOT NULL UNIQUE,
    descricao               VARCHAR2(500),
    tipo_saida              VARCHAR2(20) NOT NULL CHECK (tipo_saida IN ('HTML', 'PDF', 'TXT')),
    template_path           VARCHAR2(500),
    formato_pagina          VARCHAR2(20) DEFAULT 'A4',  -- A4, Letter, Carnê
    orientacao              VARCHAR2(20) DEFAULT 'PORTRAIT', -- PORTRAIT, LANDSCAPE
    quantidade_por_pagina   NUMBER DEFAULT 1 CHECK (quantidade_por_pagina IN (1, 2, 3)),
    estilo_css              CLOB,
    parametros_json         CLOB CHECK (parametros_json IS JSON),
    ativo                   CHAR(1) DEFAULT 'S' CHECK (ativo IN ('S', 'N')),
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Trigger para atualizar updated_at
CREATE OR REPLACE TRIGGER trg_modelos_updated
BEFORE UPDATE ON boleto_modelos
FOR EACH ROW
BEGIN
    :NEW.updated_at := CURRENT_TIMESTAMP;
END;
/

-- Adicionar colunas na tabela boletos
ALTER TABLE boletos ADD (
    id_modelo               NUMBER,
    conteudo_html           CLOB,
    conteudo_pdf            BLOB,
    metadata_geracao        CLOB CHECK (metadata_geracao IS JSON),
    data_geracao_html       TIMESTAMP,
    data_geracao_pdf        TIMESTAMP,
    CONSTRAINT fk_boleto_modelo FOREIGN KEY (id_modelo)
        REFERENCES boleto_modelos(id_modelo)
);

-- Índices
CREATE INDEX idx_boleto_modelo ON boletos(id_modelo);
CREATE INDEX idx_boleto_data_geracao ON boletos(data_geracao_html);

-- Inserir modelos padrão
INSERT INTO boleto_modelos (
    nome_modelo,
    descricao,
    tipo_saida,
    formato_pagina,
    orientacao,
    quantidade_por_pagina,
    ativo
) VALUES (
    'PADRAO_HTML',
    'Modelo padrão HTML para impressão',
    'HTML',
    'A4',
    'PORTRAIT',
    1,
    'S'
);

INSERT INTO boleto_modelos (
    nome_modelo,
    descricao,
    tipo_saida,
    formato_pagina,
    orientacao,
    quantidade_por_pagina,
    ativo
) VALUES (
    'CARNE_HTML',
    'Modelo carnê com 2 boletos por página',
    'HTML',
    'A4',
    'LANDSCAPE',
    2,
    'S'
);

INSERT INTO boleto_modelos (
    nome_modelo,
    descricao,
    tipo_saida,
    formato_pagina,
    orientacao,
    quantidade_por_pagina,
    ativo
) VALUES (
    'PADRAO_PDF',
    'Modelo padrão PDF para impressão',
    'PDF',
    'A4',
    'PORTRAIT',
    1,
    'S'
);

INSERT INTO boleto_modelos (
    nome_modelo,
    descricao,
    tipo_saida,
    formato_pagina,
    orientacao,
    quantidade_por_pagina,
    ativo
) VALUES (
    'CARNE_PDF',
    'Modelo carnê PDF com 2 boletos por página',
    'PDF',
    'A4',
    'LANDSCAPE',
    2,
    'S'
);

COMMIT;

-- View para consulta de boletos com modelo
CREATE OR REPLACE VIEW vw_boletos_completo AS
SELECT
    b.id_boleto,
    b.numero_documento,
    b.nosso_numero,
    b.data_vencimento,
    b.valor_documento,
    b.status,
    b.codigo_barras,
    b.linha_digitavel,
    bm.nome_modelo,
    bm.tipo_saida,
    bm.formato_pagina,
    b.data_geracao_html,
    b.data_geracao_pdf,
    bb.codigo_banco,
    bb.nome_banco,
    ce.nome AS cedente_nome,
    sa.nome AS sacado_nome,
    CASE
        WHEN b.conteudo_html IS NOT NULL THEN 'S'
        ELSE 'N'
    END AS tem_html,
    CASE
        WHEN b.conteudo_pdf IS NOT NULL THEN 'S'
        ELSE 'N'
    END AS tem_pdf
FROM boletos b
LEFT JOIN boleto_modelos bm ON b.id_modelo = bm.id_modelo
JOIN boleto_contas bc ON b.id_conta = bc.id_conta
JOIN boleto_cedentes ce ON bc.id_cedente = ce.id_cedente
JOIN boleto_sacados sa ON b.id_sacado = sa.id_sacado
JOIN boleto_bancos bb ON bc.id_banco = bb.id_banco;

PROMPT
PROMPT Estrutura de modelos criada com sucesso!
PROMPT
PROMPT Modelos disponíveis:
SELECT nome_modelo, tipo_saida, formato_pagina, quantidade_por_pagina
FROM boleto_modelos
ORDER BY nome_modelo;

PROMPT
PROMPT =========================================================
