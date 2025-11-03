# 🚀 Início Rápido - API de Boletos

Guia rápido para começar a usar a API de geração de boletos em 5 minutos.

## Opção 1: Executar Localmente (Python)

### 1. Instalar dependências

```bash
pip install -r requirements_api.txt
```

### 2. Executar a API

```bash
python api_boleto.py
```

A API estará disponível em: `http://localhost:5000`

### 3. Testar a API

```bash
# Em outro terminal
python teste_api.py
```

## Opção 2: Executar com Docker

### 1. Build e executar

```bash
docker-compose up -d
```

### 2. Verificar logs

```bash
docker-compose logs -f
```

### 3. Parar o serviço

```bash
docker-compose down
```

## Opção 3: Executar com Docker manualmente

```bash
# Build
docker build -t api-boleto .

# Run
docker run -p 5000:5000 api-boleto
```

## 📝 Primeiro Teste Manual

### 1. Verificar se a API está funcionando

```bash
curl http://localhost:5000/health
```

**Resposta esperada:**
```json
{
  "status": "ok",
  "servico": "API de Geração de Boletos",
  "versao": "1.0.0"
}
```

### 2. Listar bancos disponíveis

```bash
curl http://localhost:5000/bancos
```

### 3. Gerar seu primeiro boleto

Crie um arquivo `teste_boleto.json`:

```json
{
  "formato": "pdf",
  "codigo_banco": "237",
  "cedente": "Minha Empresa LTDA",
  "cedente_documento": "12.345.678/0001-90",
  "cedente_endereco": "Rua Exemplo, 123 - São Paulo/SP",
  "agencia_cedente": "1234",
  "conta_cedente": "56789-0",
  "carteira": "06",
  "nosso_numero": "1234567",
  "numero_documento": "1234567",
  "data_vencimento": "2024-12-31",
  "valor_documento": 100.50,
  "sacado_nome": "João da Silva",
  "sacado_documento": "123.456.789-00",
  "sacado_endereco": "Rua do Cliente, 456",
  "sacado_bairro": "Centro",
  "sacado_cidade": "São Paulo",
  "sacado_uf": "SP",
  "sacado_cep": "01234-567"
}
```

Execute:

```bash
curl -X POST http://localhost:5000/boleto/gerar \
  -H "Content-Type: application/json" \
  -d @teste_boleto.json
```

**Resposta:** JSON com linha digitável, código de barras e boleto em Base64.

### 4. Salvar o PDF

Use este script Python para decodificar o Base64:

```python
import requests
import base64
import json

# Ler arquivo de teste
with open('teste_boleto.json', 'r') as f:
    dados = json.load(f)

# Fazer requisição
response = requests.post('http://localhost:5000/boleto/gerar', json=dados)
resultado = response.json()

# Verificar sucesso
if resultado['sucesso']:
    print(f"Linha Digitável: {resultado['linha_digitavel']}")
    print(f"Código de Barras: {resultado['codigo_barras']}")

    # Decodificar e salvar PDF
    pdf_bytes = base64.b64decode(resultado['boleto_base64'])
    with open('meu_boleto.pdf', 'wb') as f:
        f.write(pdf_bytes)
    print("PDF salvo em: meu_boleto.pdf")
else:
    print(f"Erro: {resultado['erro']}")
```

## 🔍 Endpoints Principais

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/health` | Verificar status da API |
| GET | `/bancos` | Listar bancos disponíveis |
| POST | `/boleto/gerar` | Gerar boleto (retorna Base64) |
| POST | `/boleto/gerar/arquivo` | Gerar boleto (download direto) |
| POST | `/boleto/validar` | Validar dados sem gerar arquivo |

## 📋 Campos Mínimos Obrigatórios

```json
{
  "codigo_banco": "237",
  "cedente": "Nome da Empresa",
  "cedente_documento": "12.345.678/0001-90",
  "cedente_endereco": "Endereço completo",
  "agencia_cedente": "1234",
  "conta_cedente": "56789-0",
  "carteira": "06",
  "nosso_numero": "1234567",
  "numero_documento": "1234567",
  "data_vencimento": "2024-12-31",
  "valor_documento": 100.00
}
```

## 🏦 Códigos dos Bancos

| Código | Banco |
|--------|-------|
| 001 | Banco do Brasil |
| 033 | Santander |
| 041 | Banrisul |
| 070 | BRB |
| 104 | Caixa |
| 237 | Bradesco |
| 341 | Itaú |
| 356 | Real |
| 399 | HSBC |

## 🔧 Produção

Para produção, use Gunicorn:

```bash
# 4 workers, timeout de 2 minutos
gunicorn -w 4 -b 0.0.0.0:5000 --timeout 120 api_boleto:app
```

## 📚 Documentação Completa

Para mais detalhes, consulte:
- **[README_API.md](README_API.md)** - Documentação completa
- **[exemplos_requisicao.json](exemplos_requisicao.json)** - Exemplos para cada banco

## 💡 Dicas

1. **Formato de Data:** Use `YYYY-MM-DD` ou `DD/MM/YYYY`
2. **Formato de Saída:** `pdf` ou `html`
3. **Base64:** O boleto é retornado em Base64 para facilitar integração
4. **Validação:** Use `/boleto/validar` para testar dados sem gerar arquivo
5. **Erros:** A API retorna mensagens claras em português

## 🐛 Problemas Comuns

### API não conecta
```bash
# Verificar se está rodando
curl http://localhost:5000/health

# Se não estiver, iniciar
python api_boleto.py
```

### Erro ao instalar dependências
```bash
# Atualizar pip
pip install --upgrade pip

# Instalar novamente
pip install -r requirements_api.txt
```

### Boleto com dados incorretos
```bash
# Validar primeiro
curl -X POST http://localhost:5000/boleto/validar \
  -H "Content-Type: application/json" \
  -d @teste_boleto.json
```

## 📞 Suporte

Verifique os logs para detalhes de erros:
- Desenvolvimento: Console do Python
- Docker: `docker-compose logs -f`
- Produção: `/app/logs/error.log`

---

**Pronto!** Agora você tem uma API completa de geração de boletos funcionando! 🎉
