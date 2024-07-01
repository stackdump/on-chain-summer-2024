CREATE OR REPLACE FUNCTION process_block_number() RETURNS TRIGGER AS $$
DECLARE
    address TEXT := (select config('address'));
    transaction RECORD;
BEGIN
    -- Call the get_eth_transactions function
    FOR transaction IN SELECT * FROM get_eth_transactions(address, NEW.block_number)
    LOOP
        INSERT INTO transactions (transaction_hash, transaction_details, logs, block_number)
        VALUES (transaction.transaction_hash, transaction.transaction_details, transaction.logs, NEW.block_number)
        ON CONFLICT (transaction_hash) DO NOTHING;
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER block_number_insert_trigger
AFTER INSERT ON block_numbers
FOR EACH ROW
EXECUTE FUNCTION process_block_number();

