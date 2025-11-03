#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Script de teste para a API de Geração de Boletos
Demonstra como consumir a API e processar os resultados
"""

import requests
import base64
import json
import sys
from datetime import datetime, timedelta


def colorir(texto, cor):
    """Adiciona cores ao texto no terminal"""
    cores = {
        'verde': '\033[92m',
        'vermelho': '\033[91m',
        'amarelo': '\033[93m',
        'azul': '\033[94m',
        'reset': '\033[0m'
    }
    return f"{cores.get(cor, '')}{texto}{cores['reset']}"


def testar_health():
    """Testa o endpoint de health check"""
    print(colorir("\n=== Testando Health Check ===", 'azul'))

    try:
        response = requests.get('http://localhost:5000/health')
        if response.status_code == 200:
            resultado = response.json()
            print(colorir("✓ API está funcionando!", 'verde'))
            print(f"  Serviço: {resultado['servico']}")
            print(f"  Versão: {resultado['versao']}")
            return True
        else:
            print(colorir("✗ API retornou erro", 'vermelho'))
            return False
    except requests.exceptions.ConnectionError:
        print(colorir("✗ Não foi possível conectar à API", 'vermelho'))
        print(colorir("  Certifique-se de que a API está rodando: python api_boleto.py", 'amarelo'))
        return False
    except Exception as e:
        print(colorir(f"✗ Erro: {str(e)}", 'vermelho'))
        return False


def testar_listar_bancos():
    """Testa o endpoint de listagem de bancos"""
    print(colorir("\n=== Testando Listagem de Bancos ===", 'azul'))

    try:
        response = requests.get('http://localhost:5000/bancos')
        if response.status_code == 200:
            resultado = response.json()
            print(colorir(f"✓ {len(resultado['bancos'])} bancos disponíveis:", 'verde'))
            for banco in resultado['bancos']:
                print(f"  [{banco['codigo']}] {banco['nome']}")
            return True
        else:
            print(colorir("✗ Erro ao listar bancos", 'vermelho'))
            return False
    except Exception as e:
        print(colorir(f"✗ Erro: {str(e)}", 'vermelho'))
        return False


def testar_gerar_boleto_bradesco():
    """Testa geração de boleto Bradesco em PDF"""
    print(colorir("\n=== Testando Geração de Boleto Bradesco (PDF) ===", 'azul'))

    # Data de vencimento: 30 dias a partir de hoje
    data_vencimento = (datetime.now() + timedelta(days=30)).strftime('%Y-%m-%d')

    dados = {
        "formato": "pdf",
        "codigo_banco": "237",
        "cedente": "Empresa ACME LTDA",
        "cedente_documento": "12.345.678/0001-90",
        "cedente_endereco": "Rua Exemplo, 123 - Centro - São Paulo/SP - CEP: 01234-567",
        "agencia_cedente": "0278-0",
        "conta_cedente": "0039232-4",
        "carteira": "06",
        "nosso_numero": "2125525",
        "numero_documento": "2125525",
        "data_vencimento": data_vencimento,
        "valor_documento": 8280.00,
        "sacado_nome": "João da Silva - TESTE",
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

    try:
        response = requests.post('http://localhost:5000/boleto/gerar', json=dados)

        if response.status_code == 200:
            resultado = response.json()

            if resultado['sucesso']:
                print(colorir("✓ Boleto gerado com sucesso!", 'verde'))
                print(f"  Banco: {resultado['banco']}")
                print(f"  Linha Digitável: {colorir(resultado['linha_digitavel'], 'amarelo')}")
                print(f"  Código de Barras: {resultado['codigo_barras']}")
                print(f"  Nosso Número: {resultado['nosso_numero']}")
                print(f"  Valor: R$ {resultado['valor_documento']}")
                print(f"  Vencimento: {resultado['data_vencimento']}")

                # Salvar PDF
                pdf_bytes = base64.b64decode(resultado['boleto_base64'])
                nome_arquivo = 'boleto_bradesco_teste.pdf'
                with open(nome_arquivo, 'wb') as f:
                    f.write(pdf_bytes)
                print(f"  Arquivo salvo: {colorir(nome_arquivo, 'verde')}")

                return True
            else:
                print(colorir(f"✗ Erro: {resultado['erro']}", 'vermelho'))
                return False
        else:
            print(colorir(f"✗ HTTP {response.status_code}", 'vermelho'))
            print(response.text)
            return False

    except Exception as e:
        print(colorir(f"✗ Erro: {str(e)}", 'vermelho'))
        return False


def testar_gerar_boleto_brb_html():
    """Testa geração de boleto BRB em HTML"""
    print(colorir("\n=== Testando Geração de Boleto BRB (HTML) ===", 'azul'))

    data_vencimento = (datetime.now() + timedelta(days=30)).strftime('%Y-%m-%d')

    dados = {
        "formato": "html",
        "codigo_banco": "070",
        "cedente": "Empresa XYZ LTDA",
        "cedente_documento": "01.689.998/0001-02",
        "cedente_endereco": "SCS Quadra 06 Bloco A - Brasília/DF",
        "agencia_cedente": "106",
        "conta_cedente": "6000970",
        "carteira": "1",
        "convenio": "1",
        "nosso_numero": "082983",
        "numero_documento": "8466",
        "especie_documento": "NP",
        "data_vencimento": data_vencimento,
        "valor_documento": 203.70,
        "sacado_nome": "Maria Santos - TESTE",
        "sacado_documento": "987.654.321-00",
        "sacado_endereco": "Av. Principal, 789",
        "sacado_bairro": "Asa Norte",
        "sacado_cidade": "Brasília",
        "sacado_uf": "DF",
        "sacado_cep": "70000-000",
        "instrucoes": [
            "Protestar após 5 dias",
            "Juros de 2% ao mês"
        ]
    }

    try:
        response = requests.post('http://localhost:5000/boleto/gerar', json=dados)

        if response.status_code == 200:
            resultado = response.json()

            if resultado['sucesso']:
                print(colorir("✓ Boleto gerado com sucesso!", 'verde'))
                print(f"  Banco: {resultado['banco']}")
                print(f"  Linha Digitável: {colorir(resultado['linha_digitavel'], 'amarelo')}")
                print(f"  Código de Barras: {resultado['codigo_barras']}")

                # Salvar HTML
                html_bytes = base64.b64decode(resultado['boleto_base64'])
                nome_arquivo = 'boleto_brb_teste.html'
                with open(nome_arquivo, 'wb') as f:
                    f.write(html_bytes)
                print(f"  Arquivo salvo: {colorir(nome_arquivo, 'verde')}")

                return True
            else:
                print(colorir(f"✗ Erro: {resultado['erro']}", 'vermelho'))
                return False
        else:
            print(colorir(f"✗ HTTP {response.status_code}", 'vermelho'))
            return False

    except Exception as e:
        print(colorir(f"✗ Erro: {str(e)}", 'vermelho'))
        return False


def testar_validar_boleto():
    """Testa validação de boleto sem gerar arquivo"""
    print(colorir("\n=== Testando Validação de Boleto ===", 'azul'))

    dados = {
        "codigo_banco": "237",
        "cedente": "Empresa ACME LTDA",
        "cedente_documento": "12.345.678/0001-90",
        "cedente_endereco": "Rua Exemplo, 123",
        "agencia_cedente": "0278-0",
        "conta_cedente": "0039232-4",
        "carteira": "06",
        "nosso_numero": "2125525",
        "numero_documento": "2125525",
        "data_vencimento": "2024-12-31",
        "valor_documento": 100.00
    }

    try:
        response = requests.post('http://localhost:5000/boleto/validar', json=dados)

        if response.status_code == 200:
            resultado = response.json()

            if resultado['sucesso']:
                print(colorir("✓ Boleto validado com sucesso!", 'verde'))
                print(f"  Linha Digitável: {colorir(resultado['linha_digitavel'], 'amarelo')}")
                print(f"  Código de Barras: {resultado['codigo_barras']}")
                return True
            else:
                print(colorir(f"✗ Erro: {resultado['erro']}", 'vermelho'))
                return False
        else:
            print(colorir(f"✗ HTTP {response.status_code}", 'vermelho'))
            return False

    except Exception as e:
        print(colorir(f"✗ Erro: {str(e)}", 'vermelho'))
        return False


def testar_erro_banco_invalido():
    """Testa tratamento de erro com banco inválido"""
    print(colorir("\n=== Testando Tratamento de Erro (Banco Inválido) ===", 'azul'))

    dados = {
        "formato": "pdf",
        "codigo_banco": "999",  # Banco inválido
        "cedente": "Empresa",
        "cedente_documento": "12.345.678/0001-90",
        "cedente_endereco": "Rua X",
        "agencia_cedente": "1234",
        "conta_cedente": "56789",
        "carteira": "06",
        "nosso_numero": "123",
        "numero_documento": "123",
        "data_vencimento": "2024-12-31",
        "valor_documento": 100.00
    }

    try:
        response = requests.post('http://localhost:5000/boleto/gerar', json=dados)

        if response.status_code == 400:
            resultado = response.json()
            if not resultado['sucesso']:
                print(colorir("✓ Erro tratado corretamente!", 'verde'))
                print(f"  Mensagem: {resultado['erro']}")
                return True
        else:
            print(colorir("✗ Erro não foi tratado adequadamente", 'vermelho'))
            return False

    except Exception as e:
        print(colorir(f"✗ Erro: {str(e)}", 'vermelho'))
        return False


def main():
    """Executa todos os testes"""
    print(colorir("\n" + "="*60, 'azul'))
    print(colorir("  TESTE DA API DE GERAÇÃO DE BOLETOS", 'azul'))
    print(colorir("="*60, 'azul'))

    testes = [
        ("Health Check", testar_health),
        ("Listar Bancos", testar_listar_bancos),
        ("Gerar Boleto Bradesco PDF", testar_gerar_boleto_bradesco),
        ("Gerar Boleto BRB HTML", testar_gerar_boleto_brb_html),
        ("Validar Boleto", testar_validar_boleto),
        ("Tratamento de Erro", testar_erro_banco_invalido)
    ]

    resultados = []

    for nome, funcao in testes:
        try:
            resultado = funcao()
            resultados.append((nome, resultado))
        except Exception as e:
            print(colorir(f"\n✗ Erro ao executar teste '{nome}': {str(e)}", 'vermelho'))
            resultados.append((nome, False))

    # Resumo
    print(colorir("\n" + "="*60, 'azul'))
    print(colorir("  RESUMO DOS TESTES", 'azul'))
    print(colorir("="*60, 'azul'))

    passou = sum(1 for _, resultado in resultados if resultado)
    total = len(resultados)

    for nome, resultado in resultados:
        status = colorir("✓ PASSOU", 'verde') if resultado else colorir("✗ FALHOU", 'vermelho')
        print(f"{nome:.<40} {status}")

    print(colorir("\n" + "="*60, 'azul'))
    print(f"Total: {passou}/{total} testes passaram")

    if passou == total:
        print(colorir("✓ TODOS OS TESTES PASSARAM!", 'verde'))
        return 0
    else:
        print(colorir(f"✗ {total - passou} teste(s) falharam", 'vermelho'))
        return 1


if __name__ == '__main__':
    sys.exit(main())
