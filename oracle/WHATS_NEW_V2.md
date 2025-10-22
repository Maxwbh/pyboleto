# 🆕 O que há de novo na V2

## 📋 Resumo das Melhorias

A versão 2 do sistema de boletos Oracle implementa **arquitetura modular por banco**, **armazenamento de conteúdo gerado** e **geração de PDF nativa**.

---

## 🏗️ Arquitetura Modular por Banco

### ❌ **Antes (V1)**: Funções em um único package

```sql
-- Tudo em PKG_BOLETO_BARCODE
FUNCTION campo_livre_bb(...) RETURN VARCHAR2;
FUNCTION campo_livre_bradesco(...) RETURN VARCHAR2;
FUNCTION campo_livre_caixa(...) RETURN VARCHAR2;
-- ... etc
```

**Problemas:**
- Difícil manutenção
- Um package gigante com 2000+ linhas
- Lógica de todos os bancos misturada
- Dificulta testes unitários por banco

### ✅ **Agora (V2)**: Package dedicado por banco

```sql
-- Cada banco tem seu próprio package
PKG_BANCO_001_BB        -- Banco do Brasil
PKG_BANCO_237_BRADESCO  -- Bradesco
PKG_BANCO_104_CAIXA     -- Caixa
PKG_BANCO_341_ITAU      -- Itaú
PKG_BANCO_033_SANTANDER -- Santander
PKG_BANCO_756_SICOOB    -- Sicoob
```

**Vantagens:**
- ✅ **Modular**: Cada banco isolado
- ✅ **Manutenível**: Fácil atualizar regras específicas
- ✅ **Testável**: Testar banco independentemente
- ✅ **Extensível**: Adicionar novos bancos sem impactar existentes
- ✅ **Organizado**: Código limpo e estruturado

### Exemplo: Package do Bradesco

```sql
CREATE OR REPLACE PACKAGE pkg_banco_237_bradesco AS
    -- Constantes do banco
    C_CODIGO_BANCO CONSTANT VARCHAR2(3) := '237';
    C_NOME_BANCO CONSTANT VARCHAR2(100) := 'Bradesco';

    -- Funções específicas do Bradesco
    FUNCTION calcular_dv_nosso_numero(...) RETURN VARCHAR2;
    FUNCTION formatar_nosso_numero(...) RETURN VARCHAR2;
    FUNCTION calcular_campo_livre(...) RETURN VARCHAR2;
    FUNCTION gerar_codigo_barras(...) RETURN pkg_boleto_barcode.t_boleto_calculado;
END;
```

---

## 📄 Armazenamento de Conteúdo Gerado

### Nova Estrutura: Tabela `boleto_modelos`

```sql
CREATE TABLE boleto_modelos (
    id_modelo               NUMBER PRIMARY KEY,
    nome_modelo             VARCHAR2(100) NOT NULL,  -- 'PADRAO_HTML', 'CARNE_PDF'
    descricao               VARCHAR2(500),
    tipo_saida              VARCHAR2(20),            -- 'HTML', 'PDF'
    formato_pagina          VARCHAR2(20),            -- 'A4', 'Letter'
    orientacao              VARCHAR2(20),            -- 'PORTRAIT', 'LANDSCAPE'
    quantidade_por_pagina   NUMBER,                  -- 1, 2 (carnê)
    estilo_css              CLOB,
    ativo                   CHAR(1)
);
```

**Modelos padrão incluídos:**
- `PADRAO_HTML`: Boleto simples em HTML
- `CARNE_HTML`: Carnê com 2 boletos por página
- `PADRAO_PDF`: PDF padrão
- `CARNE_PDF`: PDF carnê landscape

### Extensão da Tabela `boletos`

```sql
ALTER TABLE boletos ADD (
    id_modelo               NUMBER,              -- Modelo usado
    conteudo_html           CLOB,                -- HTML gerado
    conteudo_pdf            BLOB,                -- PDF gerado
    metadata_geracao        CLOB CHECK (IS JSON),-- Metadados
    data_geracao_html       TIMESTAMP,
    data_geracao_pdf        TIMESTAMP
);
```

**Benefícios:**
- ✅ **Histórico**: Conteúdo do boleto preservado
- ✅ **Cache**: Não precisa regerar toda vez
- ✅ **Auditoria**: Saber quando foi gerado
- ✅ **Flexibilidade**: Múltiplos modelos por boleto
- ✅ **Performance**: Rápido acesso ao conteúdo já gerado

### Como Funciona

```sql
-- Criar boleto (HTML gerado automaticamente)
DECLARE
    v_id NUMBER;
BEGIN
    v_id := pkg_boleto_manager.criar_boleto(
        p_id_conta => 1,
        p_id_sacado => 1,
        p_numero_documento => 'DOC-001',
        p_nosso_numero => '000001',
        p_data_documento => SYSDATE,
        p_data_vencimento => SYSDATE + 30,
        p_valor_documento => 1500.00
    );
    -- HTML já está gravado em boletos.conteudo_html!
END;
/

-- Obter HTML gerado
SELECT conteudo_html FROM boletos WHERE id_boleto = 1;

-- Gerar PDF e gravar
DECLARE
    v_pdf BLOB;
BEGIN
    v_pdf := pkg_boleto_pdf.gerar_pdf(1);
    pkg_boleto_pdf.salvar_pdf_boleto(1, v_pdf);
END;
/

-- Obter PDF gerado
SELECT conteudo_pdf FROM boletos WHERE id_boleto = 1;
```

---

## 🖨️ Package de Geração de PDF (PKG_BOLETO_PDF)

### Inspirado no `pdf.py` do pyboleto

```python
# Python original (pdf.py)
class BoletoPDF(object):
    def __init__(self, file_):
        self.width = 666
        self.heightLine = 14

    def drawBoleto(self, boleto):
        # Gera PDF usando ReportLab
        pass
```

### Implementação Oracle

```sql
CREATE OR REPLACE PACKAGE pkg_boleto_pdf AS
    -- Constantes de layout
    C_WIDTH_A4 CONSTANT NUMBER := 595;
    C_HEIGHT_A4 CONSTANT NUMBER := 842;
    C_HEIGHT_LINE CONSTANT NUMBER := 14;

    -- Type para configuração
    TYPE t_pdf_config IS RECORD (
        formato_pagina VARCHAR2(20) DEFAULT 'A4',
        orientacao VARCHAR2(20) DEFAULT 'PORTRAIT',
        margem_esquerda NUMBER DEFAULT 10,
        fonte_padrao VARCHAR2(50) DEFAULT 'Helvetica'
    );

    -- Gerar PDF de um boleto
    FUNCTION gerar_pdf(
        p_id_boleto IN NUMBER,
        p_config IN t_pdf_config DEFAULT NULL
    ) RETURN BLOB;

    -- Gerar carnê (múltiplos boletos)
    FUNCTION gerar_pdf_carne(
        p_ids_boletos IN VARCHAR2,
        p_config IN t_pdf_config DEFAULT NULL
    ) RETURN BLOB;

    -- Gerar barcode em SVG
    FUNCTION gerar_barcode_svg(
        p_codigo_barras IN VARCHAR2,
        p_altura IN NUMBER DEFAULT 50,
        p_largura IN NUMBER DEFAULT 400
    ) RETURN CLOB;

    -- Salvar PDF no banco
    PROCEDURE salvar_pdf_boleto(
        p_id_boleto IN NUMBER,
        p_pdf_blob IN BLOB
    );

    -- Obter PDF já gerado
    FUNCTION obter_pdf_boleto(
        p_id_boleto IN NUMBER
    ) RETURN BLOB;
END;
```

### Funcionalidades

1. **Conversão HTML → PDF**: Usa APEX_UTIL ou BI Publisher
2. **Código de barras SVG**: Geração nativa de barcode em vetorial
3. **Cache automático**: PDF gravado no banco
4. **Configuração flexível**: Formato, orientação, margens
5. **Carnê**: Múltiplos boletos em uma página

### Exemplo de Uso

```sql
-- Gerar PDF simples
DECLARE
    v_pdf BLOB;
BEGIN
    v_pdf := pkg_boleto_pdf.gerar_pdf(
        p_id_boleto => 1
    );
    pkg_boleto_pdf.salvar_pdf_boleto(1, v_pdf);
END;
/

-- Gerar carnê em PDF
DECLARE
    v_pdf BLOB;
    v_config pkg_boleto_pdf.t_pdf_config;
BEGIN
    v_config.orientacao := 'LANDSCAPE';
    v_config.formato_pagina := 'A4';

    v_pdf := pkg_boleto_pdf.gerar_pdf_carne(
        p_ids_boletos => '1,2,3,4',
        p_config => v_config
    );
END;
/

-- Download (se APEX disponível)
EXEC download_boleto_pdf(1, 'meu_boleto.pdf');
```

---

## 🔄 Fluxo Completo Atualizado

### V1: Geração sob demanda
```
Criar Boleto → Gerar Código de Barras → [Usuário solicita HTML] → Gerar HTML
```

### V2: Geração automática com cache
```
Criar Boleto → Gerar Código de Barras → Gerar HTML → Gravar no banco
                                       ↓
                         [Usuário solicita PDF] → Gerar PDF → Gravar no banco
                                                              ↓
                                          [Próxima solicitação] → Retornar cache
```

---

## 📊 Comparação V1 vs V2

| Característica | V1 | V2 |
|----------------|----|----|
| **Arquitetura** | Monolítica | Modular por banco |
| **Packages** | 6 packages | 12+ packages |
| **Linhas de código** | ~4.900 | ~8.500 |
| **Armazenamento HTML** | ❌ | ✅ No banco |
| **Armazenamento PDF** | ❌ | ✅ No banco |
| **Geração PDF** | ❌ | ✅ Nativa |
| **Modelos configuráveis** | ❌ | ✅ Tabela de modelos |
| **Cache de conteúdo** | ❌ | ✅ Automático |
| **Metadados** | ❌ | ✅ JSON |
| **Histórico de geração** | Parcial | ✅ Completo |
| **Testes por banco** | Difícil | ✅ Fácil |
| **Manutenção** | Complexa | ✅ Simples |
| **Extensibilidade** | Limitada | ✅ Alta |

---

## 🎯 Casos de Uso Melhorados

### 1. Gerar Boleto e Enviar por Email

```sql
DECLARE
    v_id_boleto NUMBER;
    v_pdf BLOB;
BEGIN
    -- Criar boleto (HTML gerado automaticamente)
    v_id_boleto := pkg_boleto_manager.criar_boleto(...);

    -- Gerar PDF
    v_pdf := pkg_boleto_pdf.gerar_pdf(v_id_boleto);

    -- Enviar email com PDF anexo
    UTL_MAIL.SEND_ATTACH_RAW(
        sender => 'boletos@empresa.com',
        recipients => 'cliente@email.com',
        subject => 'Seu Boleto',
        message => 'Segue boleto em anexo',
        attachment => v_pdf,
        att_filename => 'boleto_' || v_id_boleto || '.pdf'
    );
END;
/
```

### 2. Gerar Carnê Mensal

```sql
DECLARE
    v_ids VARCHAR2(1000);
    v_pdf BLOB;
BEGIN
    -- Criar 12 boletos (mensalidades)
    FOR i IN 1..12 LOOP
        v_ids := v_ids || pkg_boleto_manager.criar_boleto(
            p_valor_documento => 500.00,
            p_data_vencimento => ADD_MONTHS(SYSDATE, i),
            ...
        ) || ',';
    END LOOP;

    -- Gerar carnê em PDF (landscape, 2 por página)
    v_pdf := pkg_boleto_pdf.gerar_pdf_carne(
        p_ids_boletos => RTRIM(v_ids, ',')
    );

    -- Disponibilizar para download
    pkg_boleto_pdf.salvar_pdf_boleto(1, v_pdf);
END;
/
```

### 3. Consultar Boletos com Conteúdo

```sql
-- View completa
SELECT
    id_boleto,
    numero_documento,
    valor_documento,
    status,
    nome_modelo,
    CASE WHEN conteudo_html IS NOT NULL THEN 'SIM' ELSE 'NÃO' END AS tem_html,
    CASE WHEN conteudo_pdf IS NOT NULL THEN 'SIM' ELSE 'NÃO' END AS tem_pdf,
    data_geracao_html,
    data_geracao_pdf
FROM vw_boletos_completo
WHERE status = 'GERADO';
```

---

## 🚀 Migração de V1 para V2

### Para usuários existentes:

1. **Execute scripts adicionais:**
```bash
sqlplus user/pass @08_schema_modelos.sql
sqlplus user/pass @09_pkg_banco_001_bb.sql
sqlplus user/pass @10_pkg_banco_237_bradesco.sql
sqlplus user/pass @12_pkg_bancos_complementares.sql
sqlplus user/pass @11_pkg_boleto_pdf.sql
sqlplus user/pass @13_update_barcode_manager.sql
```

2. **Ou reinstale completo:**
```bash
sqlplus user/pass @00_install_all_v2.sql
```

3. **Código existente continua funcionando!**
   - V2 é retrocompatível
   - Funções antigas mantidas por compatibilidade
   - Migração gradual possível

---

## 📦 Arquivos Novos

```
oracle/
├── 08_schema_modelos.sql          # Tabela de modelos + extensão de boletos
├── 09_pkg_banco_001_bb.sql        # Package Banco do Brasil
├── 10_pkg_banco_237_bradesco.sql  # Package Bradesco
├── 11_pkg_boleto_pdf.sql          # Package geração PDF
├── 12_pkg_bancos_complementares.sql # Packages Caixa, Itaú, Santander, Sicoob
├── 13_update_barcode_manager.sql  # Atualização packages existentes
├── 00_install_all_v2.sql          # Script instalação V2
└── WHATS_NEW_V2.md                # Este documento
```

---

## 🎓 Próximos Passos

### Funcionalidades Futuras (V3)

- [ ] **Remessa CNAB 240/400**: Geração de arquivos para bancos
- [ ] **Retorno CNAB**: Processamento de arquivos de retorno
- [ ] **Webhook API**: Notificações automáticas de pagamento
- [ ] **Integração PIX**: QR Code PIX + boleto
- [ ] **Assinatura Digital**: PDF assinado digitalmente
- [ ] **Templates Customizáveis**: Editor visual de layouts
- [ ] **Multi-idioma**: Boletos em inglês/espanhol
- [ ] **App Mobile**: Progressive Web App (PWA) via APEX
- [ ] **Dashboard Analytics**: Métricas em tempo real
- [ ] **Machine Learning**: Previsão de inadimplência

---

## 📞 Suporte

Para dúvidas sobre a V2:
- Documentação completa: `oracle/README.md`
- Guia de conversão: `oracle/CONVERSION_GUIDE.md`
- Guia APEX: `oracle/07_apex_application_guide.md`

---

**Desenvolvido com ❤️ usando Oracle 23i + APEX 24.2**

*Versão 2.0 - Dezembro 2024*
