-- ============================================================================
-- ORDS REST API Configuration for Boleto System
-- Oracle REST Data Services (ORDS) 24.x
-- ============================================================================

-- Habilitar ORDS no schema (executar como ADMIN ou schema owner)
BEGIN
    ORDS.ENABLE_SCHEMA(
        p_enabled => TRUE,
        p_schema => USER,
        p_url_mapping_type => 'BASE_PATH',
        p_url_mapping_pattern => 'boletos',
        p_auto_rest_auth => FALSE
    );
    COMMIT;
END;
/

-- ============================================================================
-- Módulo: Boletos API
-- ============================================================================
BEGIN
    ORDS.DEFINE_MODULE(
        p_module_name => 'boletos.api',
        p_base_path => '/api/v1/boletos/',
        p_items_per_page => 25,
        p_status => 'PUBLISHED',
        p_comments => 'API REST para gerenciamento de boletos bancários'
    );
    COMMIT;
END;
/

-- ============================================================================
-- ENDPOINT: POST /api/v1/boletos/
-- Criar novo boleto
-- ============================================================================
BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'boletos.api',
        p_pattern => '',
        p_priority => 0,
        p_etag_type => 'HASH',
        p_etag_query => NULL,
        p_comments => 'Criar novo boleto'
    );

    ORDS.DEFINE_HANDLER(
        p_module_name => 'boletos.api',
        p_pattern => '',
        p_method => 'POST',
        p_source_type => 'plsql/block',
        p_mimes_allowed => '',
        p_comments => 'Criar novo boleto',
        p_source => q'[
DECLARE
    v_id_boleto NUMBER;
    v_json CLOB;
BEGIN
    -- Criar boleto
    v_id_boleto := pkg_boleto_manager.criar_boleto(
        p_id_conta => :id_conta,
        p_id_sacado => :id_sacado,
        p_numero_documento => :numero_documento,
        p_nosso_numero => :nosso_numero,
        p_data_documento => TO_DATE(:data_documento, 'YYYY-MM-DD'),
        p_data_vencimento => TO_DATE(:data_vencimento, 'YYYY-MM-DD'),
        p_valor_documento => :valor_documento,
        p_instrucoes => :instrucoes,
        p_demonstrativo => :demonstrativo,
        p_especie_documento => NVL(:especie_documento, 'DM'),
        p_aceite => NVL(:aceite, 'N'),
        p_local_pagamento => :local_pagamento
    );

    -- Retornar dados do boleto criado
    v_json := pkg_boleto_manager.consultar_boleto(v_id_boleto);

    :status := 201;
    :content_type := 'application/json';
    HTP.PRN(v_json);
EXCEPTION
    WHEN OTHERS THEN
        :status := 400;
        :content_type := 'application/json';
        HTP.PRN(JSON_OBJECT(
            'success' VALUE FALSE,
            'error' VALUE SQLERRM
        ));
END;
]'
    );
    COMMIT;
END;
/

-- ============================================================================
-- ENDPOINT: GET /api/v1/boletos/
-- Listar boletos
-- ============================================================================
BEGIN
    ORDS.DEFINE_HANDLER(
        p_module_name => 'boletos.api',
        p_pattern => '',
        p_method => 'GET',
        p_source_type => 'plsql/block',
        p_mimes_allowed => '',
        p_comments => 'Listar boletos com filtros',
        p_source => q'[
DECLARE
    v_json CLOB;
BEGIN
    v_json := pkg_boleto_manager.listar_boletos(
        p_id_cedente => :id_cedente,
        p_id_sacado => :id_sacado,
        p_data_vencimento_inicio => TO_DATE(:data_vencimento_inicio, 'YYYY-MM-DD'),
        p_data_vencimento_fim => TO_DATE(:data_vencimento_fim, 'YYYY-MM-DD'),
        p_status => :status,
        p_limit => NVL(:limit, 100),
        p_offset => NVL(:offset, 0)
    );

    :content_type := 'application/json';
    HTP.PRN(v_json);
EXCEPTION
    WHEN OTHERS THEN
        :status := 500;
        :content_type := 'application/json';
        HTP.PRN(JSON_OBJECT(
            'success' VALUE FALSE,
            'error' VALUE SQLERRM
        ));
END;
]'
    );
    COMMIT;
END;
/

-- ============================================================================
-- ENDPOINT: GET /api/v1/boletos/:id
-- Consultar boleto por ID
-- ============================================================================
BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'boletos.api',
        p_pattern => ':id',
        p_priority => 0,
        p_etag_type => 'HASH',
        p_etag_query => NULL,
        p_comments => 'Consultar boleto por ID'
    );

    ORDS.DEFINE_HANDLER(
        p_module_name => 'boletos.api',
        p_pattern => ':id',
        p_method => 'GET',
        p_source_type => 'plsql/block',
        p_mimes_allowed => '',
        p_comments => 'Consultar boleto por ID',
        p_source => q'[
DECLARE
    v_json CLOB;
BEGIN
    v_json := pkg_boleto_manager.consultar_boleto(:id);

    :content_type := 'application/json';
    HTP.PRN(v_json);
EXCEPTION
    WHEN OTHERS THEN
        :status := 404;
        :content_type := 'application/json';
        HTP.PRN(JSON_OBJECT(
            'success' VALUE FALSE,
            'error' VALUE 'Boleto não encontrado'
        ));
END;
]'
    );
    COMMIT;
END;
/

-- ============================================================================
-- ENDPOINT: PUT /api/v1/boletos/:id
-- Atualizar boleto
-- ============================================================================
BEGIN
    ORDS.DEFINE_HANDLER(
        p_module_name => 'boletos.api',
        p_pattern => ':id',
        p_method => 'PUT',
        p_source_type => 'plsql/block',
        p_mimes_allowed => '',
        p_comments => 'Atualizar boleto',
        p_source => q'[
DECLARE
    v_json CLOB;
BEGIN
    pkg_boleto_manager.atualizar_boleto(
        p_id_boleto => :id,
        p_data_vencimento => TO_DATE(:data_vencimento, 'YYYY-MM-DD'),
        p_valor_documento => :valor_documento,
        p_instrucoes => :instrucoes,
        p_demonstrativo => :demonstrativo
    );

    v_json := pkg_boleto_manager.consultar_boleto(:id);

    :content_type := 'application/json';
    HTP.PRN(v_json);
EXCEPTION
    WHEN OTHERS THEN
        :status := 400;
        :content_type := 'application/json';
        HTP.PRN(JSON_OBJECT(
            'success' VALUE FALSE,
            'error' VALUE SQLERRM
        ));
END;
]'
    );
    COMMIT;
END;
/

-- ============================================================================
-- ENDPOINT: DELETE /api/v1/boletos/:id
-- Cancelar boleto
-- ============================================================================
BEGIN
    ORDS.DEFINE_HANDLER(
        p_module_name => 'boletos.api',
        p_pattern => ':id',
        p_method => 'DELETE',
        p_source_type => 'plsql/block',
        p_mimes_allowed => '',
        p_comments => 'Cancelar boleto',
        p_source => q'[
BEGIN
    pkg_boleto_manager.cancelar_boleto(:id);

    :status := 204;
    :content_type := 'application/json';
    HTP.PRN(JSON_OBJECT(
        'success' VALUE TRUE,
        'message' VALUE 'Boleto cancelado com sucesso'
    ));
EXCEPTION
    WHEN OTHERS THEN
        :status := 400;
        :content_type := 'application/json';
        HTP.PRN(JSON_OBJECT(
            'success' VALUE FALSE,
            'error' VALUE SQLERRM
        ));
END;
]'
    );
    COMMIT;
END;
/

-- ============================================================================
-- ENDPOINT: POST /api/v1/boletos/:id/pagamento
-- Registrar pagamento
-- ============================================================================
BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'boletos.api',
        p_pattern => ':id/pagamento',
        p_priority => 0,
        p_etag_type => 'HASH',
        p_etag_query => NULL,
        p_comments => 'Registrar pagamento de boleto'
    );

    ORDS.DEFINE_HANDLER(
        p_module_name => 'boletos.api',
        p_pattern => ':id/pagamento',
        p_method => 'POST',
        p_source_type => 'plsql/block',
        p_mimes_allowed => '',
        p_comments => 'Registrar pagamento',
        p_source => q'[
DECLARE
    v_json CLOB;
BEGIN
    pkg_boleto_manager.registrar_pagamento(
        p_id_boleto => :id,
        p_data_pagamento => TO_DATE(:data_pagamento, 'YYYY-MM-DD'),
        p_valor_pago => :valor_pago
    );

    v_json := pkg_boleto_manager.consultar_boleto(:id);

    :content_type := 'application/json';
    HTP.PRN(v_json);
EXCEPTION
    WHEN OTHERS THEN
        :status := 400;
        :content_type := 'application/json';
        HTP.PRN(JSON_OBJECT(
            'success' VALUE FALSE,
            'error' VALUE SQLERRM
        ));
END;
]'
    );
    COMMIT;
END;
/

-- ============================================================================
-- ENDPOINT: GET /api/v1/boletos/:id/html
-- Gerar HTML do boleto
-- ============================================================================
BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'boletos.api',
        p_pattern => ':id/html',
        p_priority => 0,
        p_etag_type => 'HASH',
        p_etag_query => NULL,
        p_comments => 'Gerar HTML do boleto'
    );

    ORDS.DEFINE_HANDLER(
        p_module_name => 'boletos.api',
        p_pattern => ':id/html',
        p_method => 'GET',
        p_source_type => 'plsql/block',
        p_mimes_allowed => '',
        p_comments => 'Gerar HTML do boleto',
        p_source => q'[
DECLARE
    v_html CLOB;
BEGIN
    -- Gerar HTML será implementado no próximo package
    v_html := pkg_boleto_html.gerar_html(:id);

    :content_type := 'text/html; charset=utf-8';
    HTP.PRN(v_html);
EXCEPTION
    WHEN OTHERS THEN
        :status := 500;
        :content_type := 'application/json';
        HTP.PRN(JSON_OBJECT(
            'success' VALUE FALSE,
            'error' VALUE SQLERRM
        ));
END;
]'
    );
    COMMIT;
END;
/

-- ============================================================================
-- ENDPOINT: GET /api/v1/boletos/consulta/nosso-numero
-- Consultar por nosso número
-- ============================================================================
BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'boletos.api',
        p_pattern => 'consulta/nosso-numero',
        p_priority => 0,
        p_etag_type => 'HASH',
        p_etag_query => NULL,
        p_comments => 'Consultar boleto por nosso número'
    );

    ORDS.DEFINE_HANDLER(
        p_module_name => 'boletos.api',
        p_pattern => 'consulta/nosso-numero',
        p_method => 'GET',
        p_source_type => 'plsql/block',
        p_mimes_allowed => '',
        p_comments => 'Consultar por nosso número',
        p_source => q'[
DECLARE
    v_json CLOB;
BEGIN
    v_json := pkg_boleto_manager.consultar_por_nosso_numero(
        p_id_conta => :id_conta,
        p_nosso_numero => :nosso_numero
    );

    :content_type := 'application/json';
    HTP.PRN(v_json);
EXCEPTION
    WHEN OTHERS THEN
        :status := 404;
        :content_type := 'application/json';
        HTP.PRN(JSON_OBJECT(
            'success' VALUE FALSE,
            'error' VALUE 'Boleto não encontrado'
        ));
END;
]'
    );
    COMMIT;
END;
/

-- ============================================================================
-- ENDPOINT: GET /api/v1/bancos/
-- Listar bancos disponíveis
-- ============================================================================
BEGIN
    ORDS.DEFINE_MODULE(
        p_module_name => 'bancos.api',
        p_base_path => '/api/v1/bancos/',
        p_items_per_page => 25,
        p_status => 'PUBLISHED',
        p_comments => 'API REST para consulta de bancos'
    );

    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'bancos.api',
        p_pattern => '',
        p_priority => 0,
        p_etag_type => 'HASH',
        p_etag_query => NULL,
        p_comments => 'Listar bancos'
    );

    ORDS.DEFINE_HANDLER(
        p_module_name => 'bancos.api',
        p_pattern => '',
        p_method => 'GET',
        p_source_type => 'json/collection',
        p_mimes_allowed => '',
        p_comments => 'Listar todos os bancos',
        p_source => q'[
SELECT
    id_banco,
    codigo_banco,
    nome_banco,
    logo_path,
    ativo
FROM boleto_bancos
WHERE ativo = 'S'
ORDER BY nome_banco
]'
    );
    COMMIT;
END;
/

-- ============================================================================
-- Verificar módulos criados
-- ============================================================================
SELECT
    name AS module_name,
    uri_prefix,
    status,
    comments
FROM user_ords_modules
WHERE name LIKE '%.api'
ORDER BY name;

-- ============================================================================
-- Exemplo de curl para testar a API
-- ============================================================================
/*
# Criar boleto
curl -X POST "http://localhost:8080/ords/schema/api/v1/boletos/" \
  -H "Content-Type: application/json" \
  -d '{
    "id_conta": 1,
    "id_sacado": 1,
    "numero_documento": "12345",
    "nosso_numero": "0000001",
    "data_documento": "2024-01-15",
    "data_vencimento": "2024-02-15",
    "valor_documento": 1500.00,
    "instrucoes": "Não receber após o vencimento",
    "demonstrativo": "Referente ao serviço XYZ"
  }'

# Consultar boleto
curl -X GET "http://localhost:8080/ords/schema/api/v1/boletos/1"

# Listar boletos
curl -X GET "http://localhost:8080/ords/schema/api/v1/boletos/?status=GERADO&limit=10"

# Atualizar boleto
curl -X PUT "http://localhost:8080/ords/schema/api/v1/boletos/1" \
  -H "Content-Type: application/json" \
  -d '{
    "valor_documento": 1800.00,
    "data_vencimento": "2024-03-15"
  }'

# Registrar pagamento
curl -X POST "http://localhost:8080/ords/schema/api/v1/boletos/1/pagamento" \
  -H "Content-Type: application/json" \
  -d '{
    "data_pagamento": "2024-02-10",
    "valor_pago": 1500.00
  }'

# Cancelar boleto
curl -X DELETE "http://localhost:8080/ords/schema/api/v1/boletos/1"

# Gerar HTML
curl -X GET "http://localhost:8080/ords/schema/api/v1/boletos/1/html" > boleto.html

# Listar bancos
curl -X GET "http://localhost:8080/ords/schema/api/v1/bancos/"
*/
