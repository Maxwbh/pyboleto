#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
API Flask para Geração de Boletos
Gera boletos bancários em PDF ou HTML e retorna linha digitável e código de barras
"""

from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import datetime
import tempfile
import os
import base64
from decimal import Decimal
import io

from pyboleto.bank.bancodobrasil import BoletoBB
from pyboleto.bank.bradesco import BoletoBradesco
from pyboleto.bank.brb import BoletoBrb
from pyboleto.bank.caixa import BoletoCaixa
from pyboleto.bank.itau import BoletoItau
from pyboleto.bank.santander import BoletoSantander
from pyboleto.bank.banrisul import BoletoBanrisul
from pyboleto.bank.real import BoletoReal
from pyboleto.bank.hsbc import BoletoHsbc
from pyboleto.pdf import BoletoPDF
from pyboleto.html import BoletoHTML

app = Flask(__name__)
CORS(app)

# Mapeamento de bancos disponíveis
BANCOS_DISPONIVEIS = {
    '001': {'nome': 'Banco do Brasil', 'classe': BoletoBB},
    '237': {'nome': 'Bradesco', 'classe': BoletoBradesco},
    '070': {'nome': 'BRB', 'classe': BoletoBrb},
    '104': {'nome': 'Caixa Econômica', 'classe': BoletoCaixa},
    '341': {'nome': 'Itaú', 'classe': BoletoItau},
    '033': {'nome': 'Santander', 'classe': BoletoSantander},
    '041': {'nome': 'Banrisul', 'classe': BoletoBanrisul},
    '356': {'nome': 'Banco Real', 'classe': BoletoReal},
    '399': {'nome': 'HSBC', 'classe': BoletoHsbc},
}


def parse_data(data_str):
    """Converte string de data (YYYY-MM-DD ou DD/MM/YYYY) para datetime.date"""
    try:
        if '/' in data_str:
            # Formato DD/MM/YYYY
            dia, mes, ano = data_str.split('/')
            return datetime.date(int(ano), int(mes), int(dia))
        else:
            # Formato YYYY-MM-DD
            ano, mes, dia = data_str.split('-')
            return datetime.date(int(ano), int(mes), int(dia))
    except Exception as e:
        raise ValueError(f"Formato de data inválido: {data_str}. Use YYYY-MM-DD ou DD/MM/YYYY")


def criar_boleto(dados):
    """Cria objeto de boleto baseado nos dados recebidos"""

    # Validar banco
    codigo_banco = dados.get('codigo_banco', '').strip()
    if not codigo_banco:
        raise ValueError("código_banco é obrigatório")

    if codigo_banco not in BANCOS_DISPONIVEIS:
        bancos_validos = ', '.join(f"{k} ({v['nome']})" for k, v in BANCOS_DISPONIVEIS.items())
        raise ValueError(f"Banco não suportado: {codigo_banco}. Bancos disponíveis: {bancos_validos}")

    # Criar instância do boleto
    banco_classe = BANCOS_DISPONIVEIS[codigo_banco]['classe']

    # Banco do Brasil requer parâmetros especiais
    if codigo_banco == '001':
        format_convenio = dados.get('format_convenio', 7)
        format_nnumero = dados.get('format_nnumero', 1)
        boleto = banco_classe(format_convenio, format_nnumero)
    else:
        boleto = banco_classe()

    # Dados do Cedente (Beneficiário)
    boleto.cedente = dados.get('cedente', '')
    boleto.cedente_documento = dados.get('cedente_documento', '')
    boleto.cedente_endereco = dados.get('cedente_endereco', '')

    # Alguns bancos usam endereço completo, outros usam campos separados
    if 'cedente_logradouro' in dados:
        boleto.cedente_logradouro = dados['cedente_logradouro']
        boleto.cedente_bairro = dados.get('cedente_bairro', '')
        boleto.cedente_cidade = dados.get('cedente_cidade', '')
        boleto.cedente_uf = dados.get('cedente_uf', '')
        boleto.cedente_cep = dados.get('cedente_cep', '')

    boleto.agencia_cedente = dados.get('agencia_cedente', '')
    boleto.conta_cedente = dados.get('conta_cedente', '')

    # Dados do Boleto
    boleto.carteira = dados.get('carteira', '')
    boleto.nosso_numero = dados.get('nosso_numero', '')
    boleto.numero_documento = dados.get('numero_documento', '')

    # Datas
    if 'data_vencimento' in dados:
        boleto.data_vencimento = parse_data(dados['data_vencimento'])

    if 'data_documento' in dados:
        boleto.data_documento = parse_data(dados['data_documento'])
    else:
        boleto.data_documento = datetime.date.today()

    if 'data_processamento' in dados:
        boleto.data_processamento = parse_data(dados['data_processamento'])
    else:
        boleto.data_processamento = datetime.date.today()

    # Valor
    if 'valor_documento' in dados:
        valor = dados['valor_documento']
        if isinstance(valor, (int, float)):
            boleto.valor_documento = Decimal(str(valor))
        else:
            boleto.valor_documento = valor

    # Dados do Sacado (Pagador)
    if 'sacado_nome' in dados:
        boleto.sacado_nome = dados['sacado_nome']
        boleto.sacado_documento = dados.get('sacado_documento', '')
        boleto.sacado_endereco = dados.get('sacado_endereco', '')
        boleto.sacado_bairro = dados.get('sacado_bairro', '')
        boleto.sacado_cidade = dados.get('sacado_cidade', '')
        boleto.sacado_uf = dados.get('sacado_uf', '')
        boleto.sacado_cep = dados.get('sacado_cep', '')
    elif 'sacado' in dados:
        # Formato alternativo: lista de strings
        boleto.sacado = dados['sacado']

    # Campos opcionais
    if 'instrucoes' in dados:
        boleto.instrucoes = dados['instrucoes']

    if 'demonstrativo' in dados:
        boleto.demonstrativo = dados['demonstrativo']

    if 'local_pagamento' in dados:
        boleto.local_pagamento = dados['local_pagamento']

    if 'aceite' in dados:
        boleto.aceite = dados['aceite']

    if 'especie' in dados:
        boleto.especie = dados['especie']

    if 'especie_documento' in dados:
        boleto.especie_documento = dados['especie_documento']

    # Campos específicos de alguns bancos
    if 'convenio' in dados:
        boleto.convenio = dados['convenio']

    return boleto


@app.route('/health', methods=['GET'])
def health():
    """Endpoint de health check"""
    return jsonify({
        'status': 'ok',
        'servico': 'API de Geração de Boletos',
        'versao': '1.0.0'
    })


@app.route('/bancos', methods=['GET'])
def listar_bancos():
    """Lista todos os bancos disponíveis"""
    bancos = []
    for codigo, info in BANCOS_DISPONIVEIS.items():
        bancos.append({
            'codigo': codigo,
            'nome': info['nome']
        })

    return jsonify({
        'sucesso': True,
        'bancos': bancos
    })


@app.route('/boleto/gerar', methods=['POST'])
def gerar_boleto():
    """
    Gera boleto e retorna PDF/HTML em base64, linha digitável e código de barras

    Formato de entrada (JSON):
    {
        "formato": "pdf",  // ou "html"
        "codigo_banco": "237",
        "cedente": "Empresa ACME LTDA",
        "cedente_documento": "12.345.678/0001-90",
        "cedente_endereco": "Rua Exemplo, 123",
        "agencia_cedente": "1234",
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

    Retorno:
    {
        "sucesso": true,
        "linha_digitavel": "23790.27804 60000.212559 25003.923205 4 48690000828000",
        "codigo_barras": "23794486900008280000278060000212552500392320",
        "formato": "pdf",
        "boleto_base64": "JVBERi0xLjQKJeLj...",
        "banco": "Bradesco"
    }
    """
    try:
        # Obter dados da requisição
        dados = request.get_json()

        if not dados:
            return jsonify({
                'sucesso': False,
                'erro': 'Nenhum dado foi enviado'
            }), 400

        # Formato de saída (PDF ou HTML)
        formato = dados.get('formato', 'pdf').lower()
        if formato not in ['pdf', 'html']:
            return jsonify({
                'sucesso': False,
                'erro': f'Formato inválido: {formato}. Use "pdf" ou "html"'
            }), 400

        # Criar boleto
        try:
            boleto = criar_boleto(dados)
        except ValueError as e:
            return jsonify({
                'sucesso': False,
                'erro': f'Erro ao criar boleto: {str(e)}'
            }), 400

        # Gerar arquivo temporário
        temp_file = tempfile.NamedTemporaryFile(
            delete=False,
            suffix=f'.{formato}'
        )
        temp_file.close()

        try:
            # Gerar boleto no formato solicitado
            if formato == 'pdf':
                boleto_gen = BoletoPDF(temp_file.name)
                boleto_gen.drawBoleto(boleto)
                boleto_gen.save()
            else:  # html
                boleto_gen = BoletoHTML(temp_file.name)
                boleto_gen.drawBoleto(boleto)
                boleto_gen.save()

            # Ler arquivo e converter para base64
            with open(temp_file.name, 'rb') as f:
                boleto_bytes = f.read()
                boleto_base64 = base64.b64encode(boleto_bytes).decode('utf-8')

            # Preparar resposta
            resposta = {
                'sucesso': True,
                'linha_digitavel': boleto.linha_digitavel,
                'codigo_barras': boleto.barcode,
                'formato': formato,
                'boleto_base64': boleto_base64,
                'banco': BANCOS_DISPONIVEIS[dados['codigo_banco']]['nome'],
                'codigo_banco': dados['codigo_banco'],
                'nosso_numero': boleto.format_nosso_numero(),
                'valor_documento': str(boleto.valor_documento),
                'data_vencimento': boleto.data_vencimento.strftime('%d/%m/%Y')
            }

            return jsonify(resposta)

        finally:
            # Limpar arquivo temporário
            if os.path.exists(temp_file.name):
                os.unlink(temp_file.name)

    except Exception as e:
        return jsonify({
            'sucesso': False,
            'erro': f'Erro interno: {str(e)}'
        }), 500


@app.route('/boleto/gerar/arquivo', methods=['POST'])
def gerar_boleto_arquivo():
    """
    Gera boleto e retorna como arquivo para download
    Aceita os mesmos parâmetros do endpoint /boleto/gerar
    """
    try:
        dados = request.get_json()

        if not dados:
            return jsonify({
                'sucesso': False,
                'erro': 'Nenhum dado foi enviado'
            }), 400

        formato = dados.get('formato', 'pdf').lower()
        if formato not in ['pdf', 'html']:
            return jsonify({
                'sucesso': False,
                'erro': f'Formato inválido: {formato}'
            }), 400

        # Criar boleto
        try:
            boleto = criar_boleto(dados)
        except ValueError as e:
            return jsonify({
                'sucesso': False,
                'erro': str(e)
            }), 400

        # Gerar em memória
        if formato == 'pdf':
            temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.pdf')
            temp_file.close()

            boleto_gen = BoletoPDF(temp_file.name)
            boleto_gen.drawBoleto(boleto)
            boleto_gen.save()

            mimetype = 'application/pdf'
            download_name = f'boleto_{boleto.numero_documento}.pdf'
        else:
            temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.html')
            temp_file.close()

            boleto_gen = BoletoHTML(temp_file.name)
            boleto_gen.drawBoleto(boleto)
            boleto_gen.save()

            mimetype = 'text/html'
            download_name = f'boleto_{boleto.numero_documento}.html'

        return send_file(
            temp_file.name,
            mimetype=mimetype,
            as_attachment=True,
            download_name=download_name
        )

    except Exception as e:
        return jsonify({
            'sucesso': False,
            'erro': str(e)
        }), 500


@app.route('/boleto/validar', methods=['POST'])
def validar_boleto():
    """
    Valida os dados do boleto sem gerar o arquivo
    Retorna linha digitável e código de barras
    """
    try:
        dados = request.get_json()

        if not dados:
            return jsonify({
                'sucesso': False,
                'erro': 'Nenhum dado foi enviado'
            }), 400

        # Criar boleto
        try:
            boleto = criar_boleto(dados)
        except ValueError as e:
            return jsonify({
                'sucesso': False,
                'erro': str(e)
            }), 400

        # Retornar apenas os dados
        return jsonify({
            'sucesso': True,
            'linha_digitavel': boleto.linha_digitavel,
            'codigo_barras': boleto.barcode,
            'nosso_numero': boleto.format_nosso_numero(),
            'banco': BANCOS_DISPONIVEIS[dados['codigo_banco']]['nome'],
            'codigo_banco': dados['codigo_banco'],
            'valor_documento': str(boleto.valor_documento),
            'data_vencimento': boleto.data_vencimento.strftime('%d/%m/%Y')
        })

    except Exception as e:
        return jsonify({
            'sucesso': False,
            'erro': str(e)
        }), 500


@app.errorhandler(404)
def not_found(error):
    return jsonify({
        'sucesso': False,
        'erro': 'Endpoint não encontrado'
    }), 404


@app.errorhandler(500)
def internal_error(error):
    return jsonify({
        'sucesso': False,
        'erro': 'Erro interno do servidor'
    }), 500


if __name__ == '__main__':
    # Executar em modo desenvolvimento
    # Para produção, use um servidor WSGI como Gunicorn ou uWSGI
    app.run(
        host='0.0.0.0',
        port=5000,
        debug=True
    )
