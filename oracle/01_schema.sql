-- ============================================================================
-- Schema para Sistema de Boletos - Oracle 23i
-- Conversão do pyboleto (Python) para Oracle
-- ============================================================================

-- Tabela de Bancos
CREATE TABLE boleto_bancos (
    id_banco                NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo_banco            VARCHAR2(3) NOT NULL UNIQUE,
    nome_banco              VARCHAR2(100) NOT NULL,
    logo_path               VARCHAR2(500),
    ativo                   CHAR(1) DEFAULT 'S' CHECK (ativo IN ('S', 'N')),
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Cedentes (Beneficiários)
CREATE TABLE boleto_cedentes (
    id_cedente              NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome                    VARCHAR2(200) NOT NULL,
    documento               VARCHAR2(18) NOT NULL, -- CPF ou CNPJ
    tipo_documento          VARCHAR2(10) CHECK (tipo_documento IN ('CPF', 'CNPJ')),
    logradouro              VARCHAR2(500),
    bairro                  VARCHAR2(100),
    cidade                  VARCHAR2(100),
    uf                      VARCHAR2(2),
    cep                     VARCHAR2(9),
    endereco_completo       VARCHAR2(1000),
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Sacados (Pagadores)
CREATE TABLE boleto_sacados (
    id_sacado               NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome                    VARCHAR2(200) NOT NULL,
    documento               VARCHAR2(18), -- CPF ou CNPJ
    tipo_documento          VARCHAR2(10) CHECK (tipo_documento IN ('CPF', 'CNPJ')),
    logradouro              VARCHAR2(500),
    bairro                  VARCHAR2(100),
    cidade                  VARCHAR2(100),
    uf                      VARCHAR2(2),
    cep                     VARCHAR2(9),
    endereco_completo       VARCHAR2(1000),
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Contas Bancárias do Cedente
CREATE TABLE boleto_contas (
    id_conta                NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_cedente              NUMBER NOT NULL REFERENCES boleto_cedentes(id_cedente),
    id_banco                NUMBER NOT NULL REFERENCES boleto_bancos(id_banco),
    agencia                 VARCHAR2(10) NOT NULL,
    agencia_dv              VARCHAR2(2),
    conta                   VARCHAR2(20) NOT NULL,
    conta_dv                VARCHAR2(2),
    carteira                VARCHAR2(10),
    convenio                VARCHAR2(20),
    variacao_carteira       VARCHAR2(10),
    ativo                   CHAR(1) DEFAULT 'S' CHECK (ativo IN ('S', 'N')),
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_conta UNIQUE (id_cedente, id_banco, agencia, conta)
);

-- Tabela Principal de Boletos
CREATE TABLE boletos (
    id_boleto               NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_conta                NUMBER NOT NULL REFERENCES boleto_contas(id_conta),
    id_sacado               NUMBER NOT NULL REFERENCES boleto_sacados(id_sacado),

    -- Identificação
    numero_documento        VARCHAR2(50) NOT NULL,
    nosso_numero            VARCHAR2(20) NOT NULL,

    -- Datas
    data_documento          DATE NOT NULL,
    data_vencimento         DATE NOT NULL,
    data_processamento      DATE DEFAULT SYSDATE,

    -- Valores
    valor_documento         NUMBER(15,2) NOT NULL,
    valor_mora              NUMBER(15,2),
    valor_desconto          NUMBER(15,2),
    valor_abatimento        NUMBER(15,2),
    valor_pago              NUMBER(15,2),

    -- Configurações
    especie_documento       VARCHAR2(10) DEFAULT 'DM',
    aceite                  CHAR(1) DEFAULT 'N' CHECK (aceite IN ('S', 'N')),
    local_pagamento         VARCHAR2(200) DEFAULT 'Pagável em qualquer banco até o vencimento',

    -- Instruções
    instrucoes              CLOB,
    demonstrativo           CLOB,

    -- Campos calculados (preenchidos via trigger ou procedure)
    codigo_barras           VARCHAR2(44),
    linha_digitavel         VARCHAR2(54),
    dv_codigo_barras        VARCHAR2(1),

    -- Campos específicos por banco
    ios                     VARCHAR2(20), -- Santander
    campo_livre             VARCHAR2(25),

    -- Status e controle
    status                  VARCHAR2(20) DEFAULT 'GERADO'
                            CHECK (status IN ('GERADO', 'ENVIADO', 'PAGO', 'CANCELADO', 'VENCIDO')),
    data_pagamento          DATE,

    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uk_boleto UNIQUE (id_conta, nosso_numero)
);

-- Tabela de Instruções Padrão
CREATE TABLE boleto_instrucoes (
    id_instrucao            NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_banco                NUMBER REFERENCES boleto_bancos(id_banco),
    codigo_instrucao        VARCHAR2(10),
    descricao               VARCHAR2(500) NOT NULL,
    ativo                   CHAR(1) DEFAULT 'S' CHECK (ativo IN ('S', 'N')),
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Histórico de Geração
CREATE TABLE boleto_historico (
    id_historico            NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_boleto               NUMBER NOT NULL REFERENCES boletos(id_boleto),
    tipo_evento             VARCHAR2(50) NOT NULL,
    descricao               VARCHAR2(1000),
    formato_gerado          VARCHAR2(10), -- PDF, HTML, JSON
    ip_origem               VARCHAR2(50),
    usuario                 VARCHAR2(100),
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para performance
CREATE INDEX idx_boleto_vencimento ON boletos(data_vencimento);
CREATE INDEX idx_boleto_status ON boletos(status);
CREATE INDEX idx_boleto_sacado ON boletos(id_sacado);
CREATE INDEX idx_boleto_conta ON boletos(id_conta);
CREATE INDEX idx_boleto_numero_doc ON boletos(numero_documento);
CREATE INDEX idx_boleto_nosso_numero ON boletos(nosso_numero);

-- Trigger para atualizar updated_at
CREATE OR REPLACE TRIGGER trg_boletos_updated
BEFORE UPDATE ON boletos
FOR EACH ROW
BEGIN
    :NEW.updated_at := CURRENT_TIMESTAMP;
END;
/

CREATE OR REPLACE TRIGGER trg_cedentes_updated
BEFORE UPDATE ON boleto_cedentes
FOR EACH ROW
BEGIN
    :NEW.updated_at := CURRENT_TIMESTAMP;
END;
/

CREATE OR REPLACE TRIGGER trg_sacados_updated
BEFORE UPDATE ON boleto_sacados
FOR EACH ROW
BEGIN
    :NEW.updated_at := CURRENT_TIMESTAMP;
END;
/

CREATE OR REPLACE TRIGGER trg_contas_updated
BEFORE UPDATE ON boleto_contas
FOR EACH ROW
BEGIN
    :NEW.updated_at := CURRENT_TIMESTAMP;
END;
/

-- Inserir dados dos bancos brasileiros
INSERT INTO boleto_bancos (codigo_banco, nome_banco, logo_path, ativo) VALUES ('001', 'Banco do Brasil', '/logos/bancodobrasil.jpg', 'S');
INSERT INTO boleto_bancos (codigo_banco, nome_banco, logo_path, ativo) VALUES ('237', 'Bradesco', '/logos/bradesco.jpg', 'S');
INSERT INTO boleto_bancos (codigo_banco, nome_banco, logo_path, ativo) VALUES ('104', 'Caixa Econômica Federal', '/logos/caixa.jpg', 'S');
INSERT INTO boleto_bancos (codigo_banco, nome_banco, logo_path, ativo) VALUES ('341', 'Itaú', '/logos/itau.jpg', 'S');
INSERT INTO boleto_bancos (codigo_banco, nome_banco, logo_path, ativo) VALUES ('033', 'Santander', '/logos/santander.jpg', 'S');
INSERT INTO boleto_bancos (codigo_banco, nome_banco, logo_path, ativo) VALUES ('399', 'HSBC', '/logos/hsbc.jpg', 'S');
INSERT INTO boleto_bancos (codigo_banco, nome_banco, logo_path, ativo) VALUES ('356', 'Banco Real', '/logos/real.jpg', 'S');
INSERT INTO boleto_bancos (codigo_banco, nome_banco, logo_path, ativo) VALUES ('041', 'Banrisul', '/logos/banrisul.jpg', 'S');
INSERT INTO boleto_bancos (codigo_banco, nome_banco, logo_path, ativo) VALUES ('070', 'Banco de Brasília - BRB', '/logos/brb.jpg', 'S');
INSERT INTO boleto_bancos (codigo_banco, nome_banco, logo_path, ativo) VALUES ('756', 'Sicoob', '/logos/sicoob.jpg', 'S');

COMMIT;
