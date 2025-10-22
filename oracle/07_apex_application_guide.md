# Oracle APEX 24.2 - Guia de Criação da Aplicação de Boletos

## Visão Geral

Este guia fornece instruções detalhadas para criar uma aplicação Oracle APEX 24.2 para gerenciamento de boletos bancários.

## Pré-requisitos

- Oracle Database 23i instalado e configurado
- Oracle APEX 24.2 instalado
- Oracle REST Data Services (ORDS) 24.x configurado
- Scripts SQL (01-06) executados com sucesso
- Workspace APEX criado

## Passo 1: Criar Nova Aplicação

1. Acesse o Oracle APEX Workspace
2. Clique em "App Builder" > "Create"
3. Selecione "New Application"
4. Configure:
   - **Name**: Sistema de Boletos
   - **Schema**: [Seu schema com as tabelas]
   - **Features**: Marque "Include Getting Started"

## Passo 2: Criar Páginas da Aplicação

### 2.1 Página Home (Página 1)

**Tipo**: Normal Page

**Componentes**:
- Region: "Dashboard"
  - Type: Cards
  - SQL Query:
```sql
SELECT
    'Total de Boletos' AS card_title,
    COUNT(*) AS card_value,
    'fa-file-text' AS card_icon,
    'is-info' AS card_color
FROM boletos
UNION ALL
SELECT
    'Boletos Vencidos',
    COUNT(*),
    'fa-exclamation-triangle',
    'is-danger'
FROM boletos
WHERE data_vencimento < SYSDATE
  AND status = 'GERADO'
UNION ALL
SELECT
    'Boletos a Vencer',
    COUNT(*),
    'fa-calendar',
    'is-warning'
FROM boletos
WHERE data_vencimento >= SYSDATE
  AND status = 'GERADO'
UNION ALL
SELECT
    'Total Recebido (R$)',
    TO_CHAR(SUM(valor_pago), 'FM999G999G999D00'),
    'fa-dollar',
    'is-success'
FROM boletos
WHERE status = 'PAGO';
```

### 2.2 Páginas de Cadastro

#### Página: Bancos (Página 10)

**Tipo**: Interactive Report with Form

1. Create Page > "Form" > "Report and Form"
2. Configure:
   - **Page Name**: Bancos
   - **Table**: BOLETO_BANCOS
   - **Report Type**: Interactive Report

**Form Page - Itens**:
- P10_ID_BANCO (Hidden, Primary Key)
- P10_CODIGO_BANCO (Text Field, Required)
- P10_NOME_BANCO (Text Field, Required)
- P10_LOGO_PATH (File Browse)
- P10_ATIVO (Radio Group: S/N)

#### Página: Cedentes (Página 20)

**Tipo**: Interactive Report with Form

**Tabela**: BOLETO_CEDENTES

**Form Page - Itens**:
- P20_ID_CEDENTE (Hidden, Primary Key)
- P20_NOME (Text Field, Required)
- P20_DOCUMENTO (Text Field with Mask: 999.999.999-99)
- P20_TIPO_DOCUMENTO (Select List: CPF/CNPJ)
- P20_LOGRADOURO (Text Field)
- P20_BAIRRO (Text Field)
- P20_CIDADE (Text Field)
- P20_UF (Select List - LOV)
- P20_CEP (Text Field with Mask: 99999-999)

**LOV para UF**:
```sql
SELECT DISTINCT uf AS display_value, uf AS return_value
FROM (
  SELECT 'AC' AS uf FROM dual UNION ALL
  SELECT 'AL' FROM dual UNION ALL
  SELECT 'AP' FROM dual UNION ALL
  SELECT 'AM' FROM dual UNION ALL
  SELECT 'BA' FROM dual UNION ALL
  SELECT 'CE' FROM dual UNION ALL
  SELECT 'DF' FROM dual UNION ALL
  SELECT 'ES' FROM dual UNION ALL
  SELECT 'GO' FROM dual UNION ALL
  SELECT 'MA' FROM dual UNION ALL
  SELECT 'MT' FROM dual UNION ALL
  SELECT 'MS' FROM dual UNION ALL
  SELECT 'MG' FROM dual UNION ALL
  SELECT 'PA' FROM dual UNION ALL
  SELECT 'PB' FROM dual UNION ALL
  SELECT 'PR' FROM dual UNION ALL
  SELECT 'PE' FROM dual UNION ALL
  SELECT 'PI' FROM dual UNION ALL
  SELECT 'RJ' FROM dual UNION ALL
  SELECT 'RN' FROM dual UNION ALL
  SELECT 'RS' FROM dual UNION ALL
  SELECT 'RO' FROM dual UNION ALL
  SELECT 'RR' FROM dual UNION ALL
  SELECT 'SC' FROM dual UNION ALL
  SELECT 'SP' FROM dual UNION ALL
  SELECT 'SE' FROM dual UNION ALL
  SELECT 'TO' FROM dual
)
ORDER BY uf;
```

#### Página: Sacados (Página 30)

**Tipo**: Interactive Report with Form

**Tabela**: BOLETO_SACADOS

Mesmo formato da página de Cedentes.

#### Página: Contas Bancárias (Página 40)

**Tipo**: Interactive Report with Form

**Tabela**: BOLETO_CONTAS

**Form Page - Itens**:
- P40_ID_CONTA (Hidden, Primary Key)
- P40_ID_CEDENTE (Select List - LOV)
- P40_ID_BANCO (Select List - LOV)
- P40_AGENCIA (Text Field, Required)
- P40_AGENCIA_DV (Text Field)
- P40_CONTA (Text Field, Required)
- P40_CONTA_DV (Text Field)
- P40_CARTEIRA (Text Field)
- P40_CONVENIO (Text Field)
- P40_ATIVO (Radio Group: S/N)

**LOV para Cedentes**:
```sql
SELECT nome AS display_value, id_cedente AS return_value
FROM boleto_cedentes
ORDER BY nome;
```

**LOV para Bancos**:
```sql
SELECT codigo_banco || ' - ' || nome_banco AS display_value, id_banco AS return_value
FROM boleto_bancos
WHERE ativo = 'S'
ORDER BY nome_banco;
```

### 2.3 Página Principal: Boletos (Página 50)

#### Report Page (Página 50)

**Tipo**: Interactive Report

**SQL Query**:
```sql
SELECT
    b.id_boleto,
    b.numero_documento,
    b.nosso_numero,
    TO_CHAR(b.data_vencimento, 'DD/MM/YYYY') AS data_vencimento,
    TO_CHAR(b.valor_documento, 'FM999G999G999D00') AS valor_documento,
    b.status,
    bb.codigo_banco || ' - ' || bb.nome_banco AS banco,
    ce.nome AS cedente,
    sa.nome AS sacado,
    b.linha_digitavel,
    b.codigo_barras
FROM boletos b
JOIN boleto_contas bc ON b.id_conta = bc.id_conta
JOIN boleto_cedentes ce ON bc.id_cedente = ce.id_cedente
JOIN boleto_sacados sa ON b.id_sacado = sa.id_sacado
JOIN boleto_bancos bb ON bc.id_banco = bb.id_banco
ORDER BY b.created_at DESC;
```

**Actions**:
1. Link Column: ID_BOLETO -> Página Form (51)
2. Custom Actions:
   - **Visualizar HTML**: Link para página de visualização (52)
   - **Gerar PDF**: Download do boleto em PDF
   - **Cancelar**: Processo PL/SQL
   - **Registrar Pagamento**: Modal Dialog

**Report Attributes**:
- Column: STATUS
  - Display as: Badge
  - Badge Label: &STATUS.
  - Badge State Expression:
```sql
CASE :STATUS
  WHEN 'GERADO' THEN 'info'
  WHEN 'ENVIADO' THEN 'warning'
  WHEN 'PAGO' THEN 'success'
  WHEN 'CANCELADO' THEN 'danger'
  WHEN 'VENCIDO' THEN 'danger'
END
```

#### Form Page (Página 51)

**Tipo**: Form

**Tabela**: BOLETOS

**Form Items**:
- P51_ID_BOLETO (Hidden, Primary Key)
- P51_ID_CONTA (Select List - LOV, Required)
- P51_ID_SACADO (Select List - LOV, Required)
- P51_NUMERO_DOCUMENTO (Text Field, Required)
- P51_NOSSO_NUMERO (Text Field, Required)
- P51_DATA_DOCUMENTO (Date Picker, Required)
- P51_DATA_VENCIMENTO (Date Picker, Required)
- P51_VALOR_DOCUMENTO (Number Field, Required)
- P51_ESPECIE_DOCUMENTO (Text Field, Default: DM)
- P51_ACEITE (Radio Group: S/N, Default: N)
- P51_LOCAL_PAGAMENTO (Text Field)
- P51_INSTRUCOES (Textarea, Height: 5)
- P51_DEMONSTRATIVO (Textarea, Height: 5)
- P51_CODIGO_BARRAS (Display Only)
- P51_LINHA_DIGITAVEL (Display Only)
- P51_STATUS (Display Only)

**LOV para Contas**:
```sql
SELECT
    ce.nome || ' - ' || bb.codigo_banco || ' Ag: ' || bc.agencia || ' Cc: ' || bc.conta AS display_value,
    bc.id_conta AS return_value
FROM boleto_contas bc
JOIN boleto_cedentes ce ON bc.id_cedente = ce.id_cedente
JOIN boleto_bancos bb ON bc.id_banco = bb.id_banco
WHERE bc.ativo = 'S'
ORDER BY ce.nome;
```

**LOV para Sacados**:
```sql
SELECT nome AS display_value, id_sacado AS return_value
FROM boleto_sacados
ORDER BY nome;
```

**Processos**:

1. **After Submit - Generate Barcode**:
```sql
BEGIN
    pkg_boleto_manager.gerar_boleto(:P51_ID_BOLETO);
END;
```

2. **Before Display - Load Data**:
```sql
SELECT codigo_barras, linha_digitavel, status
INTO :P51_CODIGO_BARRAS, :P51_LINHA_DIGITAVEL, :P51_STATUS
FROM boletos
WHERE id_boleto = :P51_ID_BOLETO;
```

### 2.4 Página de Visualização HTML (Página 52)

**Tipo**: Blank Page

**Region**:
- Type: Static Content
- Source: PL/SQL Function Body returning CLOB

**PL/SQL Source**:
```sql
DECLARE
    v_html CLOB;
BEGIN
    v_html := pkg_boleto_html.gerar_html(:P52_ID_BOLETO);
    RETURN v_html;
END;
```

**Page Items**:
- P52_ID_BOLETO (Hidden, set via link from Report)

### 2.5 Modal Dialog: Registrar Pagamento (Página 53)

**Tipo**: Modal Dialog

**Form Items**:
- P53_ID_BOLETO (Hidden)
- P53_DATA_PAGAMENTO (Date Picker, Required, Default: SYSDATE)
- P53_VALOR_PAGO (Number Field, Required)

**Process - After Submit**:
```sql
BEGIN
    pkg_boleto_manager.registrar_pagamento(
        p_id_boleto => :P53_ID_BOLETO,
        p_data_pagamento => :P53_DATA_PAGAMENTO,
        p_valor_pago => :P53_VALOR_PAGO
    );
END;
```

**Buttons**:
- Confirmar (Create)
- Cancelar (Cancel)

## Passo 3: Criar Navegação

### Menu de Navegação

1. Shared Components > Navigation > Lists > Desktop Navigation Menu
2. Adicionar itens:
   - **Home** -> Página 1
   - **Boletos** -> Página 50
   - **Cadastros** (Parent Entry)
     - **Bancos** -> Página 10
     - **Cedentes** -> Página 20
     - **Sacados** -> Página 30
     - **Contas Bancárias** -> Página 40
   - **Relatórios** (Parent Entry)
     - **Boletos Gerados**
     - **Boletos Pagos**
     - **Boletos Vencidos**

## Passo 4: Configurar Autenticação e Autorização

### Autenticação

1. Shared Components > Security > Authentication Schemes
2. Criar novo scheme:
   - **Name**: Boletos Authentication
   - **Scheme Type**: Oracle APEX Accounts
   - **Settings**: Configure conforme necessário

### Autorização

1. Shared Components > Security > Authorization Schemes
2. Criar schemes:
   - **Admin**: Para administradores
   - **User**: Para usuários comuns

## Passo 5: Configurar Temas e Aparência

### Theme

1. Shared Components > User Interface > Themes
2. Selecione: Universal Theme - 42
3. Customize:
   - **Theme Style**: Vita
   - **Primary Color**: Azul (#0076CE)
   - **Accent Color**: Verde (#28A745)

### Logo

1. Shared Components > Static Application Files
2. Upload logo da aplicação
3. Configure em Shared Components > User Interface Attributes

## Passo 6: Criar Processos Automatizados

### Atualizar Status de Boletos Vencidos

1. Shared Components > Automation
2. Create Automation:
   - **Name**: Atualizar Boletos Vencidos
   - **Type**: Database Action
   - **Schedule**: Daily at 00:00
   - **Source**:
```sql
UPDATE boletos
SET status = 'VENCIDO'
WHERE data_vencimento < SYSDATE
  AND status = 'GERADO';
COMMIT;
```

## Passo 7: Relatórios e Gráficos

### Relatório de Boletos por Status

**Página 60**: Report Page

```sql
SELECT
    status,
    COUNT(*) AS quantidade,
    TO_CHAR(SUM(valor_documento), 'FM999G999G999D00') AS valor_total
FROM boletos
GROUP BY status
ORDER BY
    CASE status
        WHEN 'GERADO' THEN 1
        WHEN 'ENVIADO' THEN 2
        WHEN 'PAGO' THEN 3
        WHEN 'VENCIDO' THEN 4
        WHEN 'CANCELADO' THEN 5
    END;
```

**Chart Region**:
- Type: Donut Chart
- Series: QUANTIDADE
- Label: STATUS

## Passo 8: Integrações REST

### Consumir API REST via APEX

**Web Source Module**:

1. Shared Components > Web Source Modules
2. Create Web Source Module:
   - **Name**: Boletos API
   - **URL Endpoint**: http://localhost:8080/ords/schema/api/v1/boletos/
   - **Authentication**: No Authentication

**Operations**:
- GET - List Boletos
- POST - Create Boleto
- GET - Get Boleto by ID
- PUT - Update Boleto
- DELETE - Cancel Boleto

## Passo 9: Testes

### Testes Funcionais

1. Criar cedente teste
2. Criar sacado teste
3. Criar conta bancária teste
4. Criar boleto teste
5. Visualizar boleto HTML
6. Registrar pagamento
7. Cancelar boleto

### Testes de Performance

1. Criar lote de 1000 boletos
2. Verificar tempo de geração
3. Verificar tempo de consulta
4. Otimizar índices se necessário

## Passo 10: Deploy

### Exportar Aplicação

1. App Builder > Export/Import
2. Export Application
3. Include: All Components
4. Save .sql file

### Importar em Produção

1. Acesse workspace de produção
2. App Builder > Import
3. Upload arquivo .sql
4. Install Application

## Recursos Adicionais

### Plugins Recomendados

1. **APEX Office Print** - Para geração de PDFs
2. **Oracle JET Charts** - Para gráficos avançados
3. **APEX Card Region** - Para cards no dashboard

### Segurança

1. Configurar HTTPS no ORDS
2. Implementar rate limiting
3. Configurar CORS policies
4. Habilitar Session Timeout
5. Implementar Audit Trail

### Monitoramento

1. APEX Monitor (Shared Components > Monitoring)
2. Configurar notificações de erro
3. Criar alertas para boletos vencidos

## Conclusão

Esta aplicação APEX fornece uma interface completa para gerenciamento de boletos bancários, integrada com as APIs REST e packages PL/SQL criados anteriormente.

Para suporte adicional, consulte:
- [Oracle APEX Documentation](https://docs.oracle.com/en/database/oracle/apex/)
- [Oracle REST Data Services](https://www.oracle.com/database/technologies/appdev/rest.html)
