# -*- coding: utf-8 -*-
import unittest
import datetime

from pyboleto.bank.brb import BoletoBrb

from .testutils import BoletoTestCase


class TestBancoBrb(BoletoTestCase):
    def setUp(self):
        self.dados = []
        for i in range(3):
            d = BoletoBrb()
            

            d.convenio = '1'
            d.especie_documento = 'NP'
            
            d.cedente = 'SUN COLOR'
            d.cedente_documento = "01.689.995/0001-02"
            d.cedente_endereco = "RUA XXXXXX BAIRRO YYYY BRASILIA YYYYYYY"
            d.agencia_cedente = '106'
            d.conta_cedente = '6000970'
        
            d.instrucoes = [
                "- Instruções de Responsabilidade do Cedente",
                "- Protestar após 5 dias de vencido,",
                "- Juros de Mora de 2,00 % ao Mês,",
                "- Cobrar multa de 2,00% após o vencimento.",
               
                ]
        
        
            ########## Boleto    #########
            d.numero_documento = '8466'    
            d.nosso_numero = '082983'
            
            d.data_vencimento = datetime.date(2012, 8, 21)
            d.data_documento = datetime.date(2012, 7, 28)
            d.data_processamento = datetime.date(2012, 8, 1)
        
            d.demonstrativo = [
                "- Venda Nro. 38310 FASEP ",
                "- Sol Formaturas 3233-9898"
                ]
            d.valor_documento = 203.70
        
            d.sacado = [
                "Cliente Teste xxxxxxxxxx" ,
                "Rua Desconhecida, 00/0000 - Não Sei - Cidade - Cep. 00000-000",
                ""
                ]
        
        
    
            d.numero_documento =  str(int(d.numero_documento ) + i)
            d.nosso_numero = str(int(d.nosso_numero) + i)
            
            
            d.sacado = [
            "Cliente Teste xx %02d x ( %s )x-- (%s ) ---" %(i, d.numero_documento, d.nosso_numero),
            "Rua Desconhecida, 00/0000 - Não Sei - Cidade - Cep. 00000-000",
            ""
            ]




            self.dados.append(d)

    def test_linha_digitavel(self):
        self.assertEqual(self.dados[0].linha_digitavel,
            '07090.00103 66000.970104 82983.070523 3 54320000020370'
        )
        self.assertEqual(self.dados[1].linha_digitavel,
            '07090.00103 66000.970104 82984.070498 7 54320000020370'
        )

    def test_codigo_de_barras(self):
        self.assertEqual(self.dados[0].barcode,
            '07093543200000203700001066000970108298307052'
        )



suite = unittest.TestLoader().loadTestsFromTestCase(TestBancoBrb)


if __name__ == '__main__':
    unittest.main()
