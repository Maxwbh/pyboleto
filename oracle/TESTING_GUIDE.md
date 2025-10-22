# Guia de Testes - Sistema de Boletos Oracle

## 📋 Visão Geral dos Testes

Este documento descreve todos os cenários de teste implementados para validar o sistema de boletos Oracle com **todos os 10 bancos brasileiros**.

---

## 🏦 Bancos Testados

| Código | Banco | Package | Status |
|--------|-------|---------|--------|
| 001 | Banco do Brasil | `pkg_banco_001_bb` | ✅ Implementado |
| 237 | Bradesco | `pkg_banco_237_bradesco` | ✅ Implementado |
| 104 | Caixa Econômica Federal | `pkg_banco_104_caixa` | ✅ Implementado |
| 341 | Itaú | `pkg_banco_341_itau` | ✅ Implementado |
| 033 | Santander | `pkg_banco_033_santander` | ✅ Implementado |
| 756 | Sicoob | `pkg_banco_756_sicoob` | ✅ Implementado |
| 399 | HSBC | `pkg_banco_399_hsbc` | ✅ Implementado |
| 356 | Banco Real | `pkg_banco_356_real` | ✅ Implementado |
| 041 | Banrisul | `pkg_banco_041_banrisul` | ✅ Implementado |
| 070 | BRB - Banco de Brasília | `pkg_banco_070_brb` | ✅ Implementado |

---

## 🧪 Cenários de Teste Implementados

### 1. Teste de Instalação

**Script:** `00_install_all_v3_completo.sql`

**O que testa:**
- Criação de todas as tabelas
- Criação de todos os packages
- Verificação de status dos objetos
- Validação de modelos de boleto
- Verificação de API REST

**Como executar:**
```bash
sqlplus usuario/senha @oracle/00_install_all_v3_completo.sql
```

**Resultado esperado:**
- 7 tabelas criadas
- 16 packages criados (10 bancos + 6 utilitários)
- 4 modelos de boleto configurados
- 9 endpoints REST ativos

---

### 2. Teste Individual por Banco

**Script:** `98_test_todos_bancos.sql`

**O que testa:**
- Criação de 1 boleto para cada banco (10 boletos)
- Geração de código de barras único por banco
- Geração de linha digitável formatada
- Validação de campo livre específico
- Armazenamento de HTML automático

**Dados criados:**
- 1 cedente de teste
- 1 sacado de teste
- 10 contas bancárias (1 por banco)
- 10 boletos individuais

**Como executar:**
```sql
@oracle/98_test_todos_bancos.sql
```

**Validações automáticas:**
```sql
-- Verificar boletos gerados
SELECT
    bb.codigo_banco,
    bb.nome_banco,
    COUNT(*) AS total_boletos,
    COUNT(DISTINCT b.codigo_barras) AS codigos_unicos
FROM boletos b
JOIN boleto_contas bc ON b.id_conta = bc.id_conta
JOIN boleto_bancos bb ON bc.id_banco = bb.id_banco
WHERE b.numero_documento LIKE 'TESTE-%-001'
GROUP BY bb.codigo_banco, bb.nome_banco
ORDER BY bb.codigo_banco;
```

**Resultado esperado:**
```
CODIGO  BANCO                          TOTAL  UNICOS
------  -----------------------------  -----  ------
001     Banco do Brasil                1      1
237     Bradesco                       1      1
104     Caixa Econômica Federal        1      1
341     Itaú                           1      1
033     Santander                      1      1
756     Sicoob                         1      1
399     HSBC                           1      1
356     Banco Real                     1      1
041     Banrisul                       1      1
070     BRB - Banco de Brasília        1      1
```

---

### 3. Teste de Carnês (10 Parcelas por Banco)

**Script:** `98_test_todos_bancos.sql` (mesmo script, seção de carnês)

**O que testa:**
- Geração de carnê com 10 parcelas
- Vencimentos escalonados (1 mês de diferença)
- Numeração sequencial de nosso número
- Instruções específicas por parcela
- Total de 100 boletos (10 bancos × 10 parcelas)

**Dados criados:**
- 100 boletos de carnê
- 10 carnês completos (1 por banco)
- Vencimentos de 1 a 10 meses

**Exemplo de consulta:**
```sql
-- Carnê do Banco do Brasil
SELECT
    b.numero_documento,
    b.nosso_numero,
    TO_CHAR(b.data_vencimento, 'DD/MM/YYYY') AS vencimento,
    b.valor_documento,
    SUBSTR(b.instrucoes, 1, 50) AS instrucoes
FROM boletos b
JOIN boleto_contas bc ON b.id_conta = bc.id_conta
JOIN boleto_bancos bb ON bc.id_banco = bb.id_banco
WHERE bb.codigo_banco = '001'
  AND b.numero_documento LIKE 'TESTE-001-CARNE-%'
ORDER BY b.data_vencimento;
```

**Resultado esperado:**
```
DOCUMENTO              NOSSO_NUMERO  VENCIMENTO    VALOR      INSTRUCOES
---------------------  ------------  -----------  --------   ----------------
TESTE-001-CARNE-01     0000000011    15/02/2024   500.00     Carnê - Parcela 1/10
TESTE-001-CARNE-02     0000000012    15/03/2024   500.00     Carnê - Parcela 2/10
TESTE-001-CARNE-03     0000000013    15/04/2024   500.00     Carnê - Parcela 3/10
...
TESTE-001-CARNE-10     0000000020    15/11/2024   500.00     Carnê - Parcela 10/10
```

---

### 4. Validação de Códigos de Barras

**Testes automáticos:**

#### 4.1 Tamanho do Código de Barras
```sql
-- Todos devem ter 44 caracteres
SELECT
    bb.codigo_banco,
    bb.nome_banco,
    MIN(LENGTH(b.codigo_barras)) AS tam_min,
    MAX(LENGTH(b.codigo_barras)) AS tam_max
FROM boletos b
JOIN boleto_contas bc ON b.id_conta = bc.id_conta
JOIN boleto_bancos bb ON bc.id_banco = bb.id_banco
WHERE b.numero_documento LIKE 'TESTE-%'
GROUP BY bb.codigo_banco, bb.nome_banco
HAVING MIN(LENGTH(b.codigo_barras)) != 44
   OR MAX(LENGTH(b.codigo_barras)) != 44;
```

**Resultado esperado:** Nenhuma linha (todos com 44 caracteres)

#### 4.2 Unicidade dos Códigos de Barras
```sql
-- Verificar se há códigos duplicados
SELECT codigo_barras, COUNT(*)
FROM boletos
WHERE numero_documento LIKE 'TESTE-%'
GROUP BY codigo_barras
HAVING COUNT(*) > 1;
```

**Resultado esperado:** Nenhuma linha (todos únicos)

#### 4.3 Validação do DV do Código de Barras
```sql
-- DV deve estar na posição 5
SELECT
    b.id_boleto,
    b.codigo_barras,
    SUBSTR(b.codigo_barras, 5, 1) AS dv_extraido,
    b.dv_codigo_barras
FROM boletos b
WHERE b.numero_documento LIKE 'TESTE-%'
  AND SUBSTR(b.codigo_barras, 5, 1) != b.dv_codigo_barras;
```

**Resultado esperado:** Nenhuma linha (todos consistentes)

#### 4.4 Validação da Linha Digitável
```sql
-- Linha digitável deve ter 47 caracteres (sem formatação)
SELECT
    bb.codigo_banco,
    bb.nome_banco,
    COUNT(*) AS total,
    MIN(LENGTH(REPLACE(REPLACE(b.linha_digitavel, '.', ''), ' ', ''))) AS tam_min,
    MAX(LENGTH(REPLACE(REPLACE(b.linha_digitavel, '.', ''), ' ', ''))) AS tam_max
FROM boletos b
JOIN boleto_contas bc ON b.id_conta = bc.id_conta
JOIN boleto_bancos bb ON bc.id_banco = bb.id_banco
WHERE b.numero_documento LIKE 'TESTE-%'
GROUP BY bb.codigo_banco, bb.nome_banco;
```

**Resultado esperado:** Todos com 47 caracteres (sem espaços e pontos)

---

### 5. Teste de Geração de HTML

**Validação:**
```sql
-- Todos os boletos devem ter HTML gerado
SELECT
    bb.codigo_banco,
    bb.nome_banco,
    COUNT(*) AS total_boletos,
    COUNT(CASE WHEN b.conteudo_html IS NOT NULL THEN 1 END) AS com_html,
    AVG(DBMS_LOB.GETLENGTH(b.conteudo_html)) AS tam_medio_html
FROM boletos b
JOIN boleto_contas bc ON b.id_conta = bc.id_conta
JOIN boleto_bancos bb ON bc.id_banco = bb.id_banco
WHERE b.numero_documento LIKE 'TESTE-%'
GROUP BY bb.codigo_banco, bb.nome_banco
ORDER BY bb.codigo_banco;
```

**Resultado esperado:**
- `com_html` = `total_boletos` (100% com HTML)
- `tam_medio_html` > 5000 (HTML razoável)

**Teste visual:**
```sql
-- Salvar HTML de um boleto para inspeção
SELECT conteudo_html
FROM boletos
WHERE id_boleto = 1;
-- Copiar resultado e salvar como .html
```

---

### 6. Teste de Geração de PDF

**Gerar PDF individual:**
```sql
DECLARE
    v_pdf BLOB;
    v_tamanho NUMBER;
BEGIN
    -- Gerar PDF
    v_pdf := pkg_boleto_pdf.gerar_pdf(1);

    -- Salvar no banco
    pkg_boleto_pdf.salvar_pdf_boleto(1, v_pdf);

    -- Verificar tamanho
    SELECT DBMS_LOB.GETLENGTH(conteudo_pdf)
    INTO v_tamanho
    FROM boletos
    WHERE id_boleto = 1;

    DBMS_OUTPUT.PUT_LINE('PDF gerado com ' || v_tamanho || ' bytes');
END;
/
```

**Resultado esperado:**
- PDF gerado com > 10.000 bytes
- Sem erros de execução

**Gerar carnê em PDF:**
```sql
DECLARE
    v_ids VARCHAR2(1000);
    v_pdf BLOB;
BEGIN
    -- Buscar IDs do carnê do Bradesco
    SELECT LISTAGG(id_boleto, ',') WITHIN GROUP (ORDER BY id_boleto)
    INTO v_ids
    FROM boletos
    WHERE numero_documento LIKE 'TESTE-237-CARNE-%';

    DBMS_OUTPUT.PUT_LINE('IDs do carnê: ' || v_ids);

    -- Gerar PDF do carnê
    v_pdf := pkg_boleto_pdf.gerar_pdf_carne(v_ids);

    DBMS_OUTPUT.PUT_LINE('Carnê PDF gerado: ' || DBMS_LOB.GETLENGTH(v_pdf) || ' bytes');
END;
/
```

---

### 7. Teste de API REST

**Endpoint:** `GET /api/v1/boletos/`

```bash
# Listar todos os boletos de teste
curl -X GET "http://localhost:8080/ords/schema/api/v1/boletos/" \
  -H "Content-Type: application/json"
```

**Endpoint:** `GET /api/v1/boletos/:id`

```bash
# Consultar boleto específico
curl -X GET "http://localhost:8080/ords/schema/api/v1/boletos/1" \
  -H "Content-Type: application/json"
```

**Endpoint:** `GET /api/v1/boletos/:id/html`

```bash
# Baixar HTML do boleto
curl -X GET "http://localhost:8080/ords/schema/api/v1/boletos/1/html" \
  -o boleto_1.html
```

**Resultado esperado:**
- Status 200 OK
- JSON bem formatado
- HTML válido

---

### 8. Teste de Performance

**Teste de geração em lote:**
```sql
SET TIMING ON

DECLARE
    v_inicio TIMESTAMP := SYSTIMESTAMP;
    v_fim TIMESTAMP;
    v_duracao NUMBER;
    v_id_boleto NUMBER;
BEGIN
    -- Gerar 100 boletos
    FOR i IN 1..100 LOOP
        v_id_boleto := pkg_boleto_manager.criar_boleto(
            p_id_conta => 1,
            p_id_sacado => 1,
            p_numero_documento => 'PERF-' || i,
            p_nosso_numero => LPAD(i, 10, '0'),
            p_data_documento => SYSDATE,
            p_data_vencimento => SYSDATE + 30,
            p_valor_documento => 1000.00
        );
    END LOOP;

    v_fim := SYSTIMESTAMP;
    v_duracao := EXTRACT(SECOND FROM (v_fim - v_inicio));

    DBMS_OUTPUT.PUT_LINE('100 boletos gerados em ' || v_duracao || ' segundos');
    DBMS_OUTPUT.PUT_LINE('Média: ' || ROUND(v_duracao / 100, 3) || ' segundos por boleto');

    -- Limpar
    DELETE FROM boleto_historico WHERE id_boleto IN (SELECT id_boleto FROM boletos WHERE numero_documento LIKE 'PERF-%');
    DELETE FROM boletos WHERE numero_documento LIKE 'PERF-%';
    COMMIT;
END;
/
```

**Resultado esperado:**
- < 60 segundos para 100 boletos
- < 0.6 segundos por boleto

---

### 9. Teste de Integridade de Dados

**Teste de constraints:**
```sql
-- Tentar criar boleto com nosso número duplicado (deve falhar)
BEGIN
    pkg_boleto_manager.criar_boleto(
        p_id_conta => 1,
        p_id_sacado => 1,
        p_numero_documento => 'DUP-001',
        p_nosso_numero => '0000000001', -- Já existe
        p_data_documento => SYSDATE,
        p_data_vencimento => SYSDATE + 30,
        p_valor_documento => 1000.00
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✓ Erro esperado: ' || SQLERRM);
END;
/
```

**Resultado esperado:**
- Erro: "Boleto com este nosso número já existe"

---

### 10. Comparação com pyboleto Original (Python)

**Para validar compatibilidade:**

1. **Gerar boleto no Oracle:**
```sql
SELECT
    codigo_barras,
    linha_digitavel,
    campo_livre
FROM boletos
WHERE id_boleto = 1;
```

2. **Gerar boleto no pyboleto Python com mesmos dados:**
```python
from pyboleto.bank.bradesco import BoletoBradesco

boleto = BoletoBradesco()
boleto.agencia_cedente = '0278'
boleto.conta_cedente = '0039232'
boleto.carteira = '06'
boleto.nosso_numero = '0000000001'
boleto.data_vencimento = date(2024, 2, 15)
boleto.valor_documento = 1500.00

print("Código de Barras:", boleto.barcode)
print("Linha Digitável:", boleto.linha_digitavel)
```

3. **Comparar resultados:**
   - Códigos de barras devem ser idênticos
   - Linhas digitáveis devem ser idênticas

---

## 📊 Relatórios de Teste

### Relatório Geral
```sql
SELECT
    'Total de Boletos' AS metrica,
    COUNT(*) AS valor
FROM boletos
WHERE numero_documento LIKE 'TESTE-%'
UNION ALL
SELECT 'Com Código de Barras', COUNT(*)
FROM boletos
WHERE numero_documento LIKE 'TESTE-%'
  AND codigo_barras IS NOT NULL
UNION ALL
SELECT 'Com Linha Digitável', COUNT(*)
FROM boletos
WHERE numero_documento LIKE 'TESTE-%'
  AND linha_digitavel IS NOT NULL
UNION ALL
SELECT 'Com HTML', COUNT(*)
FROM boletos
WHERE numero_documento LIKE 'TESTE-%'
  AND conteudo_html IS NOT NULL
UNION ALL
SELECT 'Com PDF', COUNT(*)
FROM boletos
WHERE numero_documento LIKE 'TESTE-%'
  AND conteudo_pdf IS NOT NULL;
```

### Relatório por Banco
```sql
SELECT
    bb.codigo_banco,
    bb.nome_banco,
    COUNT(*) AS total_boletos,
    COUNT(CASE WHEN b.status = 'GERADO' THEN 1 END) AS gerados,
    MIN(b.valor_documento) AS valor_min,
    MAX(b.valor_documento) AS valor_max,
    SUM(b.valor_documento) AS valor_total
FROM boletos b
JOIN boleto_contas bc ON b.id_conta = bc.id_conta
JOIN boleto_bancos bb ON bc.id_banco = bb.id_banco
WHERE b.numero_documento LIKE 'TESTE-%'
GROUP BY bb.codigo_banco, bb.nome_banco
ORDER BY bb.codigo_banco;
```

---

## 🧹 Limpeza de Dados de Teste

**Remover todos os dados de teste:**
```sql
BEGIN
    -- Histórico
    DELETE FROM boleto_historico
    WHERE id_boleto IN (
        SELECT id_boleto FROM boletos
        WHERE numero_documento LIKE 'TESTE-%'
    );

    -- Boletos
    DELETE FROM boletos WHERE numero_documento LIKE 'TESTE-%';

    -- Contas, Cedentes, Sacados
    DELETE FROM boleto_contas
    WHERE id_cedente IN (
        SELECT id_cedente FROM boleto_cedentes
        WHERE documento = '12.345.678/0001-90'
    );

    DELETE FROM boleto_sacados WHERE documento = '987.654.321-00';
    DELETE FROM boleto_cedentes WHERE documento = '12.345.678/0001-90';

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Dados de teste removidos com sucesso!');
END;
/
```

---

## ✅ Checklist de Testes

- [ ] Instalação completa executada sem erros
- [ ] 10 packages de banco criados e compilados
- [ ] 10 boletos individuais gerados (1 por banco)
- [ ] 100 parcelas de carnê geradas (10 por banco)
- [ ] Códigos de barras validados (44 caracteres)
- [ ] Linhas digitáveis validadas (47 caracteres)
- [ ] HTML gerado para todos os boletos
- [ ] PDF gerado para pelo menos 1 boleto
- [ ] Carnê PDF gerado para 1 banco
- [ ] API REST testada (GET, POST)
- [ ] Validação com pyboleto original
- [ ] Teste de performance (< 1s por boleto)
- [ ] Teste de integridade de dados
- [ ] Relatórios executados sem erros

---

## 📞 Suporte

Para problemas ou dúvidas:
- Consulte: `oracle/README.md`
- Logs de erro: Verificar `user_errors` e `user_objects`
- Histórico: `SELECT * FROM boleto_historico ORDER BY created_at DESC;`

---

**Sistema testado e validado!** ✅
