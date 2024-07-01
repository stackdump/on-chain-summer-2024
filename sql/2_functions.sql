CREATE EXTENSION http;

CREATE OR REPLACE FUNCTION get_eth_transactions(address TEXT, block_number INT) RETURNS TABLE(transaction_hash TEXT, transaction_details JSONB, logs JSONB) AS $$
DECLARE
    api_endpoint TEXT := (SELECT config('endpoint'));
    hex_block_number TEXT := '0x' || to_hex(block_number);
    block JSONB;
    transaction JSONB;
    transaction_hash TEXT;
    request_id INT;
BEGIN
    -- Get the next value from the sequence for the request ID
    request_id := nextval('request_id_seq');

    -- Get the block details
    SELECT content::jsonb INTO block
    FROM http_post(
        api_endpoint,
        '{
            "jsonrpc": "2.0",
            "method": "eth_getBlockByNumber",
            "params": ["' || hex_block_number || '", true],
            "id": ' || request_id || '
        }',
        'application/json'
    );

    -- Extract transactions involving the specific address
    FOR transaction IN SELECT * FROM jsonb_array_elements(block->'result'->'transactions')
    LOOP
        IF transaction->>'from' = address OR transaction->>'to' = address THEN
            transaction_hash := transaction->>'hash';

            -- Get the next value from the sequence for the request ID
            request_id := nextval('request_id_seq');

            -- Get transaction details
            SELECT content::jsonb INTO transaction
            FROM http_post(
                api_endpoint,
                '{
                    "jsonrpc": "2.0",
                    "method": "eth_getTransactionByHash",
                    "params": ["' || transaction_hash || '"],
                    "id": ' || request_id || '
                }',
                'application/json'
            );

            -- Get the next value from the sequence for the request ID
            request_id := nextval('request_id_seq');

            -- Get transaction receipt to fetch logs
            SELECT content::jsonb INTO logs
            FROM http_post(
                api_endpoint,
                '{
                    "jsonrpc": "2.0",
                    "method": "eth_getTransactionReceipt",
                    "params": ["' || transaction_hash || '"],
                    "id": ' || request_id || '
                }',
                'application/json'
            );

            -- Return the transaction details and logs
            RETURN QUERY SELECT transaction_hash, transaction, logs->'result'->'logs';
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_latest_block_number() RETURNS INT AS $$
DECLARE
    api_endpoint TEXT := (SELECT config('endpoint'));
    response JSONB;
    latest_block_number INT;
    request_id INT;
BEGIN
    request_id := nextval('request_id_seq');
    -- Get the latest block number from the Ethereum node API
    SELECT content::jsonb INTO response
    FROM http_post(
            api_endpoint,
            '{
                "jsonrpc": "2.0",
                "method": "eth_blockNumber",
                "params": [],
                "id": ' || request_id || '
            }',
            'application/json'
         );

    -- Convert the block number from hexadecimal to integer
    latest_block_number := ('x' || substring(response->>'result' from 3))::bit(24)::int;

    RETURN latest_block_number;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_next_block_number() RETURNS VOID AS $$
DECLARE
    max_block_number INT;
    latest_block_number INT;
BEGIN
    SELECT MAX(block_number) INTO max_block_number FROM block_numbers;

    IF max_block_number IS NULL THEN
        max_block_number := 0;
    END IF;

    -- Get the latest block number using the get_latest_block_number function
    latest_block_number := get_latest_block_number();

    -- REVIEW: may want to do some number of max at a time
    WHILE max_block_number < latest_block_number LOOP
            max_block_number := max_block_number + 1;
            INSERT INTO block_numbers (block_number) VALUES (max_block_number);
        END LOOP;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_block_stats() RETURNS TABLE(highest_index INT, latest INT, behind INT) AS $$
DECLARE
    latest_block_number INT;
BEGIN
    -- Get the latest block number once
    latest_block_number := get_latest_block_number();

    RETURN QUERY
    SELECT
        max(block_number) AS highest_index,
        latest_block_number AS latest,
        latest_block_number - max(block_number) AS behind
    FROM
        block_numbers;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_block_by_number(block_number INT) RETURNS JSONB AS $$
DECLARE
    api_endpoint TEXT := (SELECT config('endpoint'));
    hex_block_number TEXT := '0x' || to_hex(block_number);
    response JSONB;
    request_id INT;
BEGIN
    request_id := nextval('request_id_seq');
    -- Get the block details from the Ethereum node API
    SELECT content::jsonb INTO response
    FROM http_post(
            api_endpoint,
            '{
                "jsonrpc": "2.0",
                "method": "eth_getBlockByNumber",
                "params": ["' || hex_block_number || '", true],
                "id": ' || request_id || '
            }',
            'application/json'
         );

    RETURN response;
END;
$$ LANGUAGE plpgsql;
