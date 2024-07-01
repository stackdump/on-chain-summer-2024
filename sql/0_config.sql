CREATE OR REPLACE FUNCTION config(p_name TEXT)
RETURNS TEXT AS $$
DECLARE
    config_data JSONB := $config$
        {
            "endpoint": "http://127.0.0.1:8545",
            "address": "0x7f1ed3d3aac8903f869eeb32182265dc34106353"
        }
        $config$::jsonb;
BEGIN
    RETURN config_data->>p_name;
END; $$ LANGUAGE plpgsql;
