-- Enum for Scalar
CREATE TYPE scalar_enum AS ENUM (
    '1'
);


-- Enum for Topic Hash
CREATE TYPE topic_enum AS ENUM (
    'TicTacToe'
);


-- Enum for Roles
CREATE TYPE role_enum AS ENUM (
    'X',
    'O',
    'HALT'
);

-- Enum for Actions
CREATE TYPE action_enum AS ENUM (
    'X00', 'X01', 'X02',
    'X10', 'X11', 'X12',
    'X20', 'X21', 'X22',
    'O00', 'O01', 'O02',
    'O10', 'O11', 'O12',
    'O20', 'O21', 'O22',
    'HALT'
);
