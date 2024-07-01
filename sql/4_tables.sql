-- Table for storing block numbers
CREATE TABLE block_numbers (
    block_number INT PRIMARY KEY
);

-- Table for storing transaction data
CREATE TABLE transactions (
    transaction_hash TEXT PRIMARY KEY,
    transaction_details JSONB,
    logs JSONB,
    block_number INT
);
