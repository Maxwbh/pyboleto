# API de Geração de Boletos - PyBoleto

API REST Flask para geração de boletos bancários brasileiros em PDF ou HTML, retornando linha digitável e código de barras.

## 📋 Características

- ✅ Gera boletos em PDF ou HTML
- ✅ Retorna linha digitável e código de barras
- ✅ Suporta 9 bancos brasileiros
- ✅ Retorna boleto em Base64 ou como arquivo
- ✅ Validação de dados
- ✅ CORS habilitado
- ✅ Pronto para integração com Oracle ou qualquer sistema

## 🏦 Bancos Suportados

| Código | Banco |
|--------|-------|
| 001 | Banco do Brasil |
| 033 | Santander |
| 041 | Banrisul |
| 070 | BRB (Banco de Brasília) |
| 104 | Caixa Econômica |
| 237 | Bradesco |
| 341 | Itaú |
| 356 | Banco Real |
| 399 | HSBC |

## 🚀 Instalação

### 1. Instalar dependências

```bash
pip install -r requirements_api.txt
```

### 2. Executar em desenvolvimento

```bash
python api_boleto.py
```

A API estará disponível em: `http://localhost:5000`

### 3. Executar em produção (recomendado)

```bash
gunicorn -w 4 -b 0.0.0.0:5000 api_boleto:app
```

## 📡 Endpoints

### 1. Health Check

**GET** `/health`

Verifica se a API está funcionando.

**Resposta:**
```json
{
  "status": "ok",
  "servico": "API de Geração de Boletos",
  "versao": "1.0.0"
}
```

### 2. Listar Bancos Disponíveis

**GET** `/bancos`

Retorna lista de todos os bancos suportados.

**Resposta:**
```json
{
  "sucesso": true,
  "bancos": [
    {
      "codigo": "001",
      "nome": "Banco do Brasil"
    },
    {
      "codigo": "237",
      "nome": "Bradesco"
    }
  ]
}
```

### 3. Gerar Boleto (Base64)

**POST** `/boleto/gerar`

Gera boleto e retorna em Base64 junto com linha digitável e código de barras.

**Requisição:**
```json
{
  "formato": "pdf",
  "codigo_banco": "237",
  "cedente": "Empresa ACME LTDA",
  "cedente_documento": "12.345.678/0001-90",
  "cedente_endereco": "Rua Exemplo, 123 - Centro - São Paulo/SP - CEP: 01234-567",
  "agencia_cedente": "1234-5",
  "conta_cedente": "56789-0",
  "carteira": "06",
  "nosso_numero": "12345678",
  "numero_documento": "12345678",
  "data_vencimento": "2024-12-31",
  "valor_documento": 100.50,
  "sacado_nome": "Cliente Exemplo",
  "sacado_documento": "123.456.789-00",
  "sacado_endereco": "Rua do Cliente, 456",
  "sacado_bairro": "Centro",
  "sacado_cidade": "São Paulo",
  "sacado_uf": "SP",
  "sacado_cep": "01234-567",
  "instrucoes": [
    "Não receber após o vencimento",
    "Multa de 2% após o vencimento"
  ]
}
```

**Resposta:**
```json
{
  "sucesso": true,
  "linha_digitavel": "23790.12345 67800.000019 23456.789005 4 98765432100050",
  "codigo_barras": "23794987654321000501234567800000192345678900",
  "formato": "pdf",
  "boleto_base64": "JVBERi0xLjQKJeLjz9MKMyAwIG9iago8PC9GaWx0ZXIvRmxhdGVEZWNvZGUvTGVuZ3RoIDQ5Nj4+c3RyZWFtCn...",
  "banco": "Bradesco",
  "codigo_banco": "237",
  "nosso_numero": "06/12345678-0",
  "valor_documento": "100.50",
  "data_vencimento": "31/12/2024"
}
```

### 4. Gerar Boleto (Arquivo para Download)

**POST** `/boleto/gerar/arquivo`

Gera boleto e retorna como arquivo para download direto.

**Requisição:** Mesma estrutura do endpoint `/boleto/gerar`

**Resposta:** Arquivo PDF ou HTML para download

### 5. Validar Boleto

**POST** `/boleto/validar`

Valida os dados do boleto sem gerar o arquivo. Retorna apenas linha digitável e código de barras.

**Requisição:** Mesma estrutura do endpoint `/boleto/gerar`

**Resposta:**
```json
{
  "sucesso": true,
  "linha_digitavel": "23790.12345 67800.000019 23456.789005 4 98765432100050",
  "codigo_barras": "23794987654321000501234567800000192345678900",
  "nosso_numero": "06/12345678-0",
  "banco": "Bradesco",
  "codigo_banco": "237",
  "valor_documento": "100.50",
  "data_vencimento": "31/12/2024"
}
```

## 📝 Campos da Requisição

### Campos Obrigatórios

| Campo | Tipo | Descrição | Exemplo |
|-------|------|-----------|---------|
| `codigo_banco` | string | Código do banco (3 dígitos) | "237" |
| `cedente` | string | Nome do beneficiário | "Empresa ACME LTDA" |
| `cedente_documento` | string | CPF/CNPJ do beneficiário | "12.345.678/0001-90" |
| `cedente_endereco` | string | Endereço do beneficiário | "Rua Exemplo, 123" |
| `agencia_cedente` | string | Agência do beneficiário | "1234-5" |
| `conta_cedente` | string | Conta do beneficiário | "56789-0" |
| `carteira` | string | Carteira do banco | "06" |
| `nosso_numero` | string | Nosso número | "12345678" |
| `numero_documento` | string | Número do documento | "12345678" |
| `data_vencimento` | string | Data de vencimento | "2024-12-31" ou "31/12/2024" |
| `valor_documento` | number | Valor do boleto | 100.50 |

### Campos Opcionais

| Campo | Tipo | Descrição | Padrão |
|-------|------|-----------|--------|
| `formato` | string | "pdf" ou "html" | "pdf" |
| `data_documento` | string | Data do documento | Hoje |
| `data_processamento` | string | Data de processamento | Hoje |
| `sacado_nome` | string | Nome do pagador | - |
| `sacado_documento` | string | CPF/CNPJ do pagador | - |
| `sacado_endereco` | string | Endereço do pagador | - |
| `sacado_bairro` | string | Bairro do pagador | - |
| `sacado_cidade` | string | Cidade do pagador | - |
| `sacado_uf` | string | UF do pagador | - |
| `sacado_cep` | string | CEP do pagador | - |
| `instrucoes` | array | Lista de instruções (até 7 linhas) | [] |
| `demonstrativo` | array | Lista de demonstrativo (até 12 linhas) | [] |
| `local_pagamento` | string | Local de pagamento | - |
| `aceite` | string | "A" ou "N" | "N" |
| `especie` | string | Espécie do título | "R$" |
| `especie_documento` | string | Tipo do documento | - |

### Campos Específicos por Banco

#### Banco do Brasil (001)
| Campo | Tipo | Descrição | Padrão |
|-------|------|-----------|--------|
| `format_convenio` | number | Formato do convênio (6, 7 ou 8) | 7 |
| `format_nnumero` | number | Formato nosso número (1 ou 2) | 1 |
| `convenio` | string | Número do convênio | - |

#### Outros Bancos
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `convenio` | string | Número do convênio (BRB e outros) |

## 💡 Exemplos de Uso

### Exemplo 1: Gerar Boleto Bradesco em PDF

```bash
curl -X POST http://localhost:5000/boleto/gerar \
  -H "Content-Type: application/json" \
  -d '{
    "formato": "pdf",
    "codigo_banco": "237",
    "cedente": "Empresa ACME LTDA",
    "cedente_documento": "12.345.678/0001-90",
    "cedente_endereco": "Rua Exemplo, 123 - Centro - São Paulo/SP",
    "agencia_cedente": "0278-0",
    "conta_cedente": "0039232-4",
    "carteira": "06",
    "nosso_numero": "2125525",
    "numero_documento": "2125525",
    "data_vencimento": "2024-12-31",
    "valor_documento": 8280.00,
    "sacado_nome": "João da Silva",
    "sacado_documento": "123.456.789-00",
    "sacado_endereco": "Rua do Cliente, 456",
    "sacado_bairro": "Centro",
    "sacado_cidade": "São Paulo",
    "sacado_uf": "SP",
    "sacado_cep": "01234-567"
  }'
```

### Exemplo 2: Gerar Boleto BRB em HTML

```bash
curl -X POST http://localhost:5000/boleto/gerar \
  -H "Content-Type: application/json" \
  -d '{
    "formato": "html",
    "codigo_banco": "070",
    "cedente": "Empresa XYZ LTDA",
    "cedente_documento": "01.689.998/0001-02",
    "cedente_endereco": "RUA XXXXXX BAIRRO YYYY BRASILIA",
    "agencia_cedente": "106",
    "conta_cedente": "6000970",
    "carteira": "1",
    "nosso_numero": "082983",
    "numero_documento": "8466",
    "convenio": "1",
    "data_vencimento": "2024-12-31",
    "valor_documento": 203.70,
    "especie_documento": "NP",
    "sacado_nome": "Maria Santos",
    "sacado_documento": "987.654.321-00",
    "sacado_endereco": "Av. Principal, 789",
    "sacado_bairro": "Asa Norte",
    "sacado_cidade": "Brasília",
    "sacado_uf": "DF",
    "sacado_cep": "70000-000",
    "instrucoes": [
      "Não receber após o vencimento",
      "Multa de 2% após o vencimento",
      "Juros de 1% ao mês"
    ]
  }'
```

### Exemplo 3: Python - Consumir a API

```python
import requests
import base64

url = "http://localhost:5000/boleto/gerar"

dados = {
    "formato": "pdf",
    "codigo_banco": "237",
    "cedente": "Empresa ACME LTDA",
    "cedente_documento": "12.345.678/0001-90",
    "cedente_endereco": "Rua Exemplo, 123",
    "agencia_cedente": "1234-5",
    "conta_cedente": "56789-0",
    "carteira": "06",
    "nosso_numero": "12345678",
    "numero_documento": "12345678",
    "data_vencimento": "2024-12-31",
    "valor_documento": 100.50,
    "sacado_nome": "Cliente Exemplo",
    "sacado_documento": "123.456.789-00",
    "sacado_endereco": "Rua do Cliente, 456",
    "sacado_bairro": "Centro",
    "sacado_cidade": "São Paulo",
    "sacado_uf": "SP",
    "sacado_cep": "01234-567"
}

response = requests.post(url, json=dados)
resultado = response.json()

if resultado['sucesso']:
    print(f"Linha Digitável: {resultado['linha_digitavel']}")
    print(f"Código de Barras: {resultado['codigo_barras']}")

    # Salvar PDF
    pdf_bytes = base64.b64decode(resultado['boleto_base64'])
    with open('boleto.pdf', 'wb') as f:
        f.write(pdf_bytes)
    print("Boleto salvo em boleto.pdf")
else:
    print(f"Erro: {resultado['erro']}")
```

### Exemplo 4: Oracle PL/SQL - Consumir a API

```sql
DECLARE
  l_request   UTL_HTTP.REQ;
  l_response  UTL_HTTP.RESP;
  l_json      CLOB;
  l_response_json CLOB;
  l_linha_digitavel VARCHAR2(100);
  l_codigo_barras VARCHAR2(100);
  l_boleto_base64 CLOB;

BEGIN
  -- Preparar JSON da requisição
  l_json := '{
    "formato": "pdf",
    "codigo_banco": "237",
    "cedente": "Empresa ACME LTDA",
    "cedente_documento": "12.345.678/0001-90",
    "cedente_endereco": "Rua Exemplo, 123",
    "agencia_cedente": "1234-5",
    "conta_cedente": "56789-0",
    "carteira": "06",
    "nosso_numero": "12345678",
    "numero_documento": "12345678",
    "data_vencimento": "2024-12-31",
    "valor_documento": 100.50,
    "sacado_nome": "Cliente Exemplo",
    "sacado_documento": "123.456.789-00",
    "sacado_endereco": "Rua do Cliente, 456",
    "sacado_bairro": "Centro",
    "sacado_cidade": "São Paulo",
    "sacado_uf": "SP",
    "sacado_cep": "01234-567"
  }';

  -- Fazer requisição
  l_request := UTL_HTTP.BEGIN_REQUEST(
    'http://localhost:5000/boleto/gerar',
    'POST',
    'HTTP/1.1'
  );

  UTL_HTTP.SET_HEADER(l_request, 'Content-Type', 'application/json');
  UTL_HTTP.SET_HEADER(l_request, 'Content-Length', LENGTH(l_json));

  UTL_HTTP.WRITE_TEXT(l_request, l_json);

  l_response := UTL_HTTP.GET_RESPONSE(l_request);

  -- Ler resposta
  LOOP
    UTL_HTTP.READ_TEXT(l_response, l_response_json);
  END LOOP;

  UTL_HTTP.END_RESPONSE(l_response);

  -- Parsear JSON (usando JSON_TABLE ou APEX_JSON)
  -- Exemplo com JSON_TABLE (Oracle 12c+)
  SELECT linha_digitavel, codigo_barras, boleto_base64
  INTO l_linha_digitavel, l_codigo_barras, l_boleto_base64
  FROM JSON_TABLE(l_response_json, '$'
    COLUMNS(
      linha_digitavel VARCHAR2(100) PATH '$.linha_digitavel',
      codigo_barras VARCHAR2(100) PATH '$.codigo_barras',
      boleto_base64 CLOB PATH '$.boleto_base64'
    )
  );

  DBMS_OUTPUT.PUT_LINE('Linha Digitável: ' || l_linha_digitavel);
  DBMS_OUTPUT.PUT_LINE('Código de Barras: ' || l_codigo_barras);

  -- Salvar boleto em BLOB
  -- INSERT INTO tb_boletos (linha_digitavel, codigo_barras, pdf_base64)
  -- VALUES (l_linha_digitavel, l_codigo_barras, l_boleto_base64);

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Erro: ' || SQLERRM);
    UTL_HTTP.END_RESPONSE(l_response);
END;
```

## 🔧 Configuração para Produção

### 1. Usar Gunicorn

```bash
# Instalar
pip install gunicorn

# Executar com 4 workers
gunicorn -w 4 -b 0.0.0.0:5000 api_boleto:app

# Com timeout aumentado (para boletos grandes)
gunicorn -w 4 -b 0.0.0.0:5000 --timeout 120 api_boleto:app
```

### 2. Usar com Nginx (Proxy Reverso)

```nginx
server {
    listen 80;
    server_name boletos.exemplo.com;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 3. Usar com Docker

```dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements_api.txt .
RUN pip install --no-cache-dir -r requirements_api.txt

COPY . .

EXPOSE 5000

CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "api_boleto:app"]
```

```bash
# Build
docker build -t api-boleto .

# Run
docker run -p 5000:5000 api-boleto
```

## 🐛 Tratamento de Erros

A API retorna erros no formato:

```json
{
  "sucesso": false,
  "erro": "Descrição do erro"
}
```

### Códigos HTTP

- `200` - Sucesso
- `400` - Erro de validação (dados inválidos)
- `404` - Endpoint não encontrado
- `500` - Erro interno do servidor

## 📊 Decodificar Base64

### Python
```python
import base64

pdf_bytes = base64.b64decode(resultado['boleto_base64'])
with open('boleto.pdf', 'wb') as f:
    f.write(pdf_bytes)
```

### JavaScript/Node.js
```javascript
const fs = require('fs');

const pdfBuffer = Buffer.from(resultado.boleto_base64, 'base64');
fs.writeFileSync('boleto.pdf', pdfBuffer);
```

### PHP
```php
$pdf_bytes = base64_decode($resultado['boleto_base64']);
file_put_contents('boleto.pdf', $pdf_bytes);
```

## 📚 Referências

- [PyBoleto - Documentação](https://github.com/eduardocereto/pyboleto)
- [FEBRABAN - Padrão de Boletos](https://portal.febraban.org.br/)

## 📞 Suporte

Para dúvidas ou problemas:
1. Verifique os logs da aplicação
2. Teste com o endpoint `/health`
3. Valide o JSON da requisição
4. Consulte a documentação do banco específico

## 🔐 Segurança

**Recomendações para produção:**
- Use HTTPS
- Implemente autenticação (JWT, API Key, etc.)
- Configure rate limiting
- Valide todos os inputs
- Mantenha logs de acesso
- Use firewall para limitar acesso

## 📝 Licença

Este projeto utiliza a biblioteca PyBoleto. Consulte a licença original do projeto.
