# Sistema de Boletos - Oracle 23i + APEX 24.2 + REST API

## 📋 Visão Geral

Conversão completa do **pyboleto** (Python) para **Oracle Database 23i** com **Oracle APEX 24.2** e **API REST** usando **ORDS**.

Este sistema fornece:
- ✅ Geração de boletos bancários brasileiros
- ✅ Suporte a 10 bancos (BB, Bradesco, Caixa, Itaú, Santander, HSBC, Real, Banrisul, BRB, Sicoob)
- ✅ Cálculo automático de código de barras e linha digitável
- ✅ API REST completa para integração
- ✅ Interface web no Oracle APEX
- ✅ Geração de HTML para impressão
- ✅ Validação de CPF/CNPJ
- ✅ Histórico de operações

---

## 🚀 Instalação Rápida

### Pré-requisitos

- Oracle Database 23i
- Oracle APEX 24.2
- Oracle REST Data Services (ORDS) 24.x
- SQL*Plus ou SQL Developer

### Passo 1: Criar Schema

```sql
-- Como SYSDBA
CREATE USER boletos IDENTIFIED BY SenhaSegura123;
GRANT CONNECT, RESOURCE, UNLIMITED TABLESPACE TO boletos;
GRANT CREATE VIEW, CREATE SYNONYM TO boletos;

-- Habilitar ORDS
BEGIN
    ORDS.ENABLE_SCHEMA(
        p_enabled => TRUE,
        p_schema => 'BOLETOS',
        p_url_mapping_type => 'BASE_PATH',
        p_url_mapping_pattern => 'boletos'
    );
END;
/
```

### Passo 2: Executar Scripts

```bash
cd oracle/

# Conecte-se como usuário BOLETOS
sqlplus boletos/SenhaSegura123@localhost/FREEPDB1

# Execute os scripts na ordem:
@01_schema.sql
@02_pkg_boleto_utils.sql
@03_pkg_boleto_barcode.sql
@04_pkg_boleto_manager.sql
@05_ords_rest_api.sql
@06_pkg_boleto_html.sql
```

### Passo 3: Verificar Instalação

```sql
-- Verificar tabelas
SELECT table_name FROM user_tables WHERE table_name LIKE 'BOLETO%';

-- Verificar packages
SELECT object_name, status FROM user_objects WHERE object_type = 'PACKAGE';

-- Verificar módulos ORDS
SELECT name, uri_prefix, status FROM user_ords_modules;
```

### Passo 4: Testar API

```bash
# URL base (ajuste conforme sua configuração)
BASE_URL="http://localhost:8080/ords/boletos/api/v1"

# Listar bancos
curl "$BASE_URL/bancos/"
```

---

## 📚 Estrutura do Projeto

```
oracle/
├── 01_schema.sql              # Tabelas, índices, triggers
├── 02_pkg_boleto_utils.sql    # Funções utilitárias (módulo 10/11, formatação)
├── 03_pkg_boleto_barcode.sql  # Geração de código de barras por banco
├── 04_pkg_boleto_manager.sql  # CRUD e gerenciamento de boletos
├── 05_ords_rest_api.sql       # Definições da API REST
├── 06_pkg_boleto_html.sql     # Geração de HTML
├── 07_apex_application_guide.md # Guia para criar aplicação APEX
└── README.md                  # Este arquivo
```

---

## 🗃️ Modelo de Dados

### Tabelas Principais

| Tabela | Descrição |
|--------|-----------|
| `boleto_bancos` | Cadastro de bancos suportados |
| `boleto_cedentes` | Beneficiários/Empresas |
| `boleto_sacados` | Pagadores/Clientes |
| `boleto_contas` | Contas bancárias dos cedentes |
| `boletos` | Boletos gerados |
| `boleto_instrucoes` | Instruções padrão por banco |
| `boleto_historico` | Histórico de operações |

### Diagrama Simplificado

```
boleto_bancos (1) ----< (N) boleto_contas
                              |
boleto_cedentes (1) ----< (N) |
                              |
                            (N) boletos (N) >---- (1) boleto_sacados
```

---

## 🔌 API REST

### Base URL

```
http://<servidor>:<porta>/ords/<schema>/api/v1/
```

Exemplo:
```
http://localhost:8080/ords/boletos/api/v1/
```

### Endpoints Disponíveis

#### 1. Listar Bancos

```http
GET /bancos/
```

**Response:**
```json
[
    {
        "id_banco": 1,
        "codigo_banco": "001",
        "nome_banco": "Banco do Brasil",
        "logo_path": "/logos/bancodobrasil.jpg",
        "ativo": "S"
    }
]
```

#### 2. Criar Boleto

```http
POST /boletos/
Content-Type: application/json
```

**Request Body:**
```json
{
    "id_conta": 1,
    "id_sacado": 1,
    "numero_documento": "12345",
    "nosso_numero": "0000001",
    "data_documento": "2024-01-15",
    "data_vencimento": "2024-02-15",
    "valor_documento": 1500.00,
    "instrucoes": "Não receber após o vencimento",
    "demonstrativo": "Referente ao serviço XYZ",
    "especie_documento": "DM",
    "aceite": "N"
}
```

**Response (201 Created):**
```json
{
    "id_boleto": 1,
    "numero_documento": "12345",
    "nosso_numero": "0000001",
    "data_vencimento": "2024-02-15",
    "valor_documento": 1500.00,
    "status": "GERADO",
    "codigo_barras": "00190000000001500123456789012345678901234",
    "linha_digitavel": "00190.00009 00000.150011 23456.789019 2 34567890123450",
    "banco": {
        "codigo": "001",
        "nome": "Banco do Brasil"
    },
    "cedente": {
        "nome": "Empresa ACME LTDA",
        "documento": "12.345.678/0001-90",
        "agencia": "1234",
        "conta": "56789-0"
    },
    "sacado": {
        "nome": "Cliente Exemplo",
        "documento": "123.456.789-09",
        "endereco": "Rua Exemplo, 123 - São Paulo - SP"
    }
}
```

#### 3. Consultar Boleto

```http
GET /boletos/:id
```

**Response:**
```json
{
    "id_boleto": 1,
    "numero_documento": "12345",
    "nosso_numero": "0000001",
    "data_documento": "2024-01-15",
    "data_vencimento": "2024-02-15",
    "valor_documento": 1500.00,
    "status": "GERADO",
    "codigo_barras": "00190000000001500123456789012345678901234",
    "linha_digitavel": "00190.00009 00000.150011 23456.789019 2 34567890123450"
}
```

#### 4. Listar Boletos

```http
GET /boletos/?status=GERADO&limit=10&offset=0
```

**Query Parameters:**
- `id_cedente`: Filtrar por cedente
- `id_sacado`: Filtrar por sacado
- `data_vencimento_inicio`: Data inicial (YYYY-MM-DD)
- `data_vencimento_fim`: Data final (YYYY-MM-DD)
- `status`: GERADO, ENVIADO, PAGO, CANCELADO, VENCIDO
- `limit`: Número de registros (padrão: 100)
- `offset`: Offset para paginação (padrão: 0)

#### 5. Atualizar Boleto

```http
PUT /boletos/:id
Content-Type: application/json
```

**Request Body:**
```json
{
    "valor_documento": 1800.00,
    "data_vencimento": "2024-03-15",
    "instrucoes": "Nova instrução"
}
```

#### 6. Registrar Pagamento

```http
POST /boletos/:id/pagamento
Content-Type: application/json
```

**Request Body:**
```json
{
    "data_pagamento": "2024-02-10",
    "valor_pago": 1500.00
}
```

#### 7. Cancelar Boleto

```http
DELETE /boletos/:id
```

**Response (204 No Content)**

#### 8. Gerar HTML do Boleto

```http
GET /boletos/:id/html
```

**Response:** HTML completo para impressão

#### 9. Consultar por Nosso Número

```http
GET /boletos/consulta/nosso-numero?id_conta=1&nosso_numero=0000001
```

---

## 💻 Exemplos de Uso

### cURL

#### Criar Boleto Completo

```bash
curl -X POST "http://localhost:8080/ords/boletos/api/v1/boletos/" \
  -H "Content-Type: application/json" \
  -d '{
    "id_conta": 1,
    "id_sacado": 1,
    "numero_documento": "12345",
    "nosso_numero": "0000001",
    "data_documento": "2024-01-15",
    "data_vencimento": "2024-02-15",
    "valor_documento": 1500.00,
    "instrucoes": "Não receber após o vencimento\nMulta de 2% ao mês\nJuros de 1% ao mês",
    "demonstrativo": "Referente ao serviço de consultoria\nMês 01/2024",
    "especie_documento": "DM",
    "aceite": "N",
    "local_pagamento": "Pagável em qualquer banco até o vencimento"
  }'
```

#### Baixar HTML do Boleto

```bash
curl "http://localhost:8080/ords/boletos/api/v1/boletos/1/html" > boleto.html
```

### Python

```python
import requests
import json

BASE_URL = "http://localhost:8080/ords/boletos/api/v1"

# Criar boleto
boleto_data = {
    "id_conta": 1,
    "id_sacado": 1,
    "numero_documento": "12345",
    "nosso_numero": "0000001",
    "data_documento": "2024-01-15",
    "data_vencimento": "2024-02-15",
    "valor_documento": 1500.00,
    "instrucoes": "Não receber após o vencimento",
    "demonstrativo": "Referente ao serviço XYZ"
}

response = requests.post(
    f"{BASE_URL}/boletos/",
    json=boleto_data,
    headers={"Content-Type": "application/json"}
)

if response.status_code == 201:
    boleto = response.json()
    print(f"Boleto criado: ID {boleto['id_boleto']}")
    print(f"Código de barras: {boleto['codigo_barras']}")
    print(f"Linha digitável: {boleto['linha_digitavel']}")
else:
    print(f"Erro: {response.text}")

# Consultar boleto
boleto_id = 1
response = requests.get(f"{BASE_URL}/boletos/{boleto_id}")
boleto = response.json()
print(json.dumps(boleto, indent=2))

# Baixar HTML
response = requests.get(f"{BASE_URL}/boletos/{boleto_id}/html")
with open(f"boleto_{boleto_id}.html", "w", encoding="utf-8") as f:
    f.write(response.text)
```

### JavaScript (Node.js)

```javascript
const axios = require('axios');

const BASE_URL = 'http://localhost:8080/ords/boletos/api/v1';

// Criar boleto
async function criarBoleto() {
    try {
        const response = await axios.post(`${BASE_URL}/boletos/`, {
            id_conta: 1,
            id_sacado: 1,
            numero_documento: "12345",
            nosso_numero: "0000001",
            data_documento: "2024-01-15",
            data_vencimento: "2024-02-15",
            valor_documento: 1500.00,
            instrucoes: "Não receber após o vencimento",
            demonstrativo: "Referente ao serviço XYZ"
        });

        console.log('Boleto criado:', response.data);
        return response.data.id_boleto;
    } catch (error) {
        console.error('Erro:', error.response.data);
    }
}

// Listar boletos
async function listarBoletos() {
    try {
        const response = await axios.get(`${BASE_URL}/boletos/`, {
            params: {
                status: 'GERADO',
                limit: 10
            }
        });

        console.log('Boletos:', response.data);
    } catch (error) {
        console.error('Erro:', error.message);
    }
}

criarBoleto().then(listarBoletos);
```

### PL/SQL Direto

```sql
-- Criar boleto
DECLARE
    v_id_boleto NUMBER;
BEGIN
    v_id_boleto := pkg_boleto_manager.criar_boleto(
        p_id_conta => 1,
        p_id_sacado => 1,
        p_numero_documento => '12345',
        p_nosso_numero => '0000001',
        p_data_documento => TO_DATE('15/01/2024', 'DD/MM/YYYY'),
        p_data_vencimento => TO_DATE('15/02/2024', 'DD/MM/YYYY'),
        p_valor_documento => 1500.00,
        p_instrucoes => 'Não receber após o vencimento',
        p_demonstrativo => 'Referente ao serviço XYZ'
    );

    DBMS_OUTPUT.PUT_LINE('Boleto criado: ' || v_id_boleto);
END;
/

-- Consultar boleto
SELECT
    id_boleto,
    numero_documento,
    codigo_barras,
    linha_digitavel,
    status
FROM boletos
WHERE id_boleto = 1;

-- Gerar HTML
DECLARE
    v_html CLOB;
BEGIN
    v_html := pkg_boleto_html.gerar_html(1);
    DBMS_OUTPUT.PUT_LINE(SUBSTR(v_html, 1, 1000));
END;
/
```

---

## 🏦 Bancos Suportados

| Código | Banco | Status | Campo Livre |
|--------|-------|--------|-------------|
| 001 | Banco do Brasil | ✅ | Convênio 6/7/8 dígitos |
| 237 | Bradesco | ✅ | Agência + Carteira + Nosso Número |
| 104 | Caixa Econômica Federal | ✅ | Nosso Número + Agência + Modalidade |
| 341 | Itaú | ✅ | Carteira + Nosso Número + Agência/Conta |
| 033 | Santander | ✅ | Nosso Número + IOS |
| 399 | HSBC | ✅ | Nosso Número + Data Juliana |
| 356 | Banco Real | ✅ | Similar ao Santander |
| 041 | Banrisul | ✅ | Agência + Nosso Número |
| 070 | BRB | ✅ | Agência + Carteira + Nosso Número |
| 756 | Sicoob | ✅ | Carteira + Agência + Cooperativa |

---

## 🔧 Configurações Específicas por Banco

### Banco do Brasil (001)

**Convênio de 6 dígitos:**
```sql
INSERT INTO boleto_contas (id_cedente, id_banco, agencia, conta, carteira, convenio)
VALUES (1, 1, '1234', '56789-0', '18', '123456');
```

**Convênio de 7 dígitos:**
```sql
INSERT INTO boleto_contas (id_cedente, id_banco, agencia, conta, carteira, convenio)
VALUES (1, 1, '1234', '56789-0', '18', '1234567');
```

### Bradesco (237)

```sql
INSERT INTO boleto_contas (id_cedente, id_banco, agencia, conta, carteira)
VALUES (1, 2, '0278', '0039232-4', '06');
```

### Caixa (104)

```sql
INSERT INTO boleto_contas (id_cedente, id_banco, agencia, conta, carteira)
VALUES (1, 3, '1234', '12345678-9', '14'); -- 14 = RG (Rápida com Registro)
```

### Itaú (341)

```sql
INSERT INTO boleto_contas (id_cedente, id_banco, agencia, conta, carteira)
VALUES (1, 4, '0123', '12345-6', '175');
```

### Santander (033)

```sql
INSERT INTO boleto_contas (id_cedente, id_banco, agencia, conta, carteira)
VALUES (1, 5, '1234', '12345678-9', '101');

-- O campo IOS é preenchido automaticamente no boleto
UPDATE boletos SET ios = '0' WHERE id_boleto = 1;
```

---

## 📊 Monitoramento e Manutenção

### Consultas Úteis

```sql
-- Dashboard de boletos
SELECT
    status,
    COUNT(*) AS quantidade,
    TO_CHAR(SUM(valor_documento), 'FM999G999G999D00') AS valor_total
FROM boletos
GROUP BY status;

-- Boletos vencidos hoje
SELECT
    b.id_boleto,
    b.numero_documento,
    b.valor_documento,
    ce.nome AS cedente,
    sa.nome AS sacado
FROM boletos b
JOIN boleto_contas bc ON b.id_conta = bc.id_conta
JOIN boleto_cedentes ce ON bc.id_cedente = ce.id_cedente
JOIN boleto_sacados sa ON b.id_sacado = sa.id_sacado
WHERE b.data_vencimento = TRUNC(SYSDATE)
  AND b.status = 'GERADO';

-- Top 10 cedentes com mais boletos
SELECT
    ce.nome,
    COUNT(b.id_boleto) AS total_boletos,
    SUM(b.valor_documento) AS valor_total
FROM boleto_cedentes ce
JOIN boleto_contas bc ON ce.id_cedente = bc.id_cedente
JOIN boletos b ON bc.id_conta = b.id_conta
GROUP BY ce.nome
ORDER BY COUNT(b.id_boleto) DESC
FETCH FIRST 10 ROWS ONLY;

-- Histórico de um boleto
SELECT
    h.tipo_evento,
    h.descricao,
    h.created_at,
    h.usuario
FROM boleto_historico h
WHERE h.id_boleto = 1
ORDER BY h.created_at DESC;
```

### Atualizar Status de Boletos Vencidos

```sql
-- Job automático (executar diariamente)
BEGIN
    UPDATE boletos
    SET status = 'VENCIDO'
    WHERE data_vencimento < TRUNC(SYSDATE)
      AND status = 'GERADO';

    COMMIT;
END;
/
```

### Criar Job no Oracle

```sql
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
        job_name => 'JOB_ATUALIZAR_BOLETOS_VENCIDOS',
        job_type => 'PLSQL_BLOCK',
        job_action => 'BEGIN
            UPDATE boletos
            SET status = ''VENCIDO''
            WHERE data_vencimento < TRUNC(SYSDATE)
              AND status = ''GERADO'';
            COMMIT;
        END;',
        start_date => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY; BYHOUR=0; BYMINUTE=0; BYSECOND=0',
        enabled => TRUE,
        comments => 'Atualiza status de boletos vencidos diariamente'
    );
END;
/
```

---

## 🔒 Segurança

### Autenticação na API REST

Para produção, configure autenticação OAuth2 no ORDS:

```sql
BEGIN
    OAUTH.CREATE_CLIENT(
        p_name => 'boletos_client',
        p_grant_type => 'client_credentials',
        p_owner => 'Boletos API Client',
        p_description => 'Cliente para API de Boletos',
        p_support_email => 'suporte@example.com',
        p_privilege_names => 'boletos.api'
    );
END;
/
```

### Rate Limiting

Configure no ORDS:

```sql
BEGIN
    ORDS.DEFINE_PRIVILEGE(
        p_privilege_name => 'boletos.api.rate_limit',
        p_roles => NULL,
        p_label => 'Rate Limit para API Boletos',
        p_description => 'Limite de 100 requisições por minuto'
    );
END;
/
```

### Audit Trail

```sql
-- Criar trigger de auditoria
CREATE OR REPLACE TRIGGER trg_audit_boletos
AFTER INSERT OR UPDATE OR DELETE ON boletos
FOR EACH ROW
DECLARE
    v_operation VARCHAR2(10);
BEGIN
    v_operation := CASE
        WHEN INSERTING THEN 'INSERT'
        WHEN UPDATING THEN 'UPDATE'
        WHEN DELETING THEN 'DELETE'
    END;

    INSERT INTO boleto_historico (
        id_boleto,
        tipo_evento,
        descricao,
        usuario
    ) VALUES (
        COALESCE(:NEW.id_boleto, :OLD.id_boleto),
        'AUDIT_' || v_operation,
        'Operação: ' || v_operation,
        USER
    );
END;
/
```

---

## 🚀 Performance

### Índices Recomendados

```sql
-- Já criados no script 01_schema.sql
CREATE INDEX idx_boleto_vencimento ON boletos(data_vencimento);
CREATE INDEX idx_boleto_status ON boletos(status);
CREATE INDEX idx_boleto_sacado ON boletos(id_sacado);
CREATE INDEX idx_boleto_conta ON boletos(id_conta);

-- Índices adicionais para queries específicas
CREATE INDEX idx_boleto_status_vencimento ON boletos(status, data_vencimento);
CREATE INDEX idx_boleto_created_at ON boletos(created_at DESC);
```

### Particionamento (Opcional para grandes volumes)

```sql
-- Particionar tabela de boletos por ano
ALTER TABLE boletos MODIFY
PARTITION BY RANGE (data_vencimento)
INTERVAL(NUMTOYMINTERVAL(1, 'YEAR'))
(
    PARTITION p_2024 VALUES LESS THAN (TO_DATE('01-JAN-2025', 'DD-MON-YYYY'))
);
```

---

## 📱 Integração com Aplicações

### Integração com Aplicação Web (React/Vue/Angular)

```javascript
// boleto-service.js
import axios from 'axios';

const API_BASE_URL = process.env.VUE_APP_API_URL;

export const boletoService = {
    async criarBoleto(boleto) {
        const response = await axios.post(`${API_BASE_URL}/boletos/`, boleto);
        return response.data;
    },

    async consultarBoleto(id) {
        const response = await axios.get(`${API_BASE_URL}/boletos/${id}`);
        return response.data;
    },

    async listarBoletos(filtros) {
        const response = await axios.get(`${API_BASE_URL}/boletos/`, {
            params: filtros
        });
        return response.data;
    },

    async gerarHTML(id) {
        const response = await axios.get(`${API_BASE_URL}/boletos/${id}/html`, {
            responseType: 'text'
        });
        return response.data;
    },

    async registrarPagamento(id, pagamento) {
        const response = await axios.post(
            `${API_BASE_URL}/boletos/${id}/pagamento`,
            pagamento
        );
        return response.data;
    }
};
```

---

## 🐛 Troubleshooting

### Erro: "Código de barras inválido"

Verifique:
1. Data de vencimento não pode ser anterior a 07/10/1997
2. Valor do boleto deve ser maior que 0
3. Dados da conta bancária estão corretos

### Erro: "Boleto com este nosso número já existe"

O nosso número deve ser único por conta bancária. Use:
```sql
SELECT MAX(TO_NUMBER(nosso_numero)) + 1
FROM boletos
WHERE id_conta = 1;
```

### API retorna 404

Verifique:
1. ORDS está rodando: `http://localhost:8080/ords`
2. Schema está habilitado no ORDS
3. Módulos ORDS foram criados corretamente

```sql
SELECT name, uri_prefix, status FROM user_ords_modules;
```

### Performance lenta

1. Verificar estatísticas:
```sql
EXEC DBMS_STATS.GATHER_SCHEMA_STATS('BOLETOS');
```

2. Analisar planos de execução:
```sql
EXPLAIN PLAN FOR
SELECT * FROM boletos WHERE status = 'GERADO';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
```

---

## 📞 Suporte

Para dúvidas e suporte:
- **Documentação Oracle APEX**: https://docs.oracle.com/en/database/oracle/apex/
- **Documentação ORDS**: https://docs.oracle.com/en/database/oracle/oracle-rest-data-services/
- **FEBRABAN**: https://portal.febraban.org.br/

---

## 📄 Licença

Este projeto é uma conversão do [pyboleto](https://github.com/eduardocereto/pyboleto) para Oracle.

---

## ✅ Checklist de Implementação

- [x] Schema de banco de dados
- [x] Packages PL/SQL utilitários
- [x] Cálculo de código de barras
- [x] Implementação por banco
- [x] API REST completa
- [x] Geração de HTML
- [x] Guia APEX
- [x] Documentação completa
- [ ] Testes automatizados
- [ ] Geração de PDF (BI Publisher)
- [ ] Integração com correios (remessa/retorno)
- [ ] App mobile (APEX PWA)

---

## 🎯 Próximos Passos

1. **Testes de Carga**: Testar com 10.000+ boletos
2. **CI/CD**: Automatizar deploy com scripts
3. **Backup**: Configurar RMAN
4. **Monitoring**: Integrar com Oracle Enterprise Manager
5. **Documentação**: Adicionar mais exemplos de integração
6. **Mobile**: Criar aplicação móvel com APEX

---

**Desenvolvido com ❤️ usando Oracle 23i + APEX 24.2**
