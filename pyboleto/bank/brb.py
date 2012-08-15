#-*- coding: utf-8 -*-
from ..data import BoletoData, custom_property


class BoletoBrb(BoletoData):
    '''
        Gera Dados necessários para criação de boleto para o banco Brb
        

    '''

    agencia_cedente = custom_property('agencia_cedente', 3)
    
    conta_cedente = custom_property('conta_cedente', 7)

    nosso_numero = custom_property('nosso_numero', 6)

    def __init__(self):
        super(BoletoBrb, self).__init__()

        self.codigo_banco = "070"
        self.logo_image = "logo_bancobrb.jpg"
        '''
        convenio 1: Cobrança Direta Sem Registro
        convenio 2: Cobrança Direta Com Registro
        convenio 3: Cobrança Convencional Agência
        '''
        self.convenio = 1
        self.uso_banco ='Sem Reg.'
        
        self.especie = 'REAL'
        self.carteira = 'COB'

    @property
    def dv_nosso_numero(self):
        
        s ='%s%s%s%s%s%s' % (
                             '000',
                             self.agencia_cedente,
                             self.conta_cedente,
                             self.convenio,
                             self.nosso_numero,
                             self.codigo_banco,
                             )
        resto2 = self.modulo10(s)
        
        if resto2 == 10:
            dv1 = 0
        else:
            dv1 = resto2
        
        dv2 = None
        while True:
            s1 = '%s%s'%(s,dv1)
            resto2 = self.modulo11(s1,7,1)
            if resto2  == 0:
                dv2 = 0
                break
            elif resto2 > 1:
                dv2 = 11 - resto2
                break
            else:
                
                dv1 += 1
                if dv1 == 10 :
                    dv1 = 0
    
        ret = '%s%s'%(dv1,dv2)
        return ret             

    @property
    def campo_livre(self):
        
        content = "%3s%3s%7s%1s%6s%3s%2s" % ('000',
            self.agencia_cedente,
            self.conta_cedente,
            self.convenio,
            self.nosso_numero,
            self.codigo_banco,
            self.dv_nosso_numero)
        return content

    def format_nosso_numero(self):
        
        return "%s%s%s%s" % (
            self.convenio,
            self.nosso_numero,
            self.codigo_banco,
            self.dv_nosso_numero
        )
    