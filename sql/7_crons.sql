CREATE OR REPLACE FUNCTION refresh_and_insert() RETURNS VOID AS $$
BEGIN
    PERFORM insert_next_block_number();
    REFRESH MATERIALIZED VIEW transaction_logs_view;
END;
$$ LANGUAGE plpgsql;

-- REVIEW: Other setup needed?
CREATE EXTENSION pg_cron;

-- schedule runs every minute
-- SELECT cron.schedule('*/1 * * * * *', 'SELECT refresh_and_insert()');
