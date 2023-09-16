CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "vector";   

-- Create the example table
CREATE TABLE my_table (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    ma_colonne_text TEXT,
    ma_colonne_vector vector(1536)
);

-- Dummy data
INSERT INTO my_table (ma_colonne_text, ma_colonne_vector) VALUES 
('Dummy data 1', ARRAY(SELECT generate_series(1,1536))), 
('Dummy data 2', ARRAY(SELECT generate_series(1,1536)));

-- Readonly
CREATE RULE my_table_read_only AS ON INSERT TO my_table DO INSTEAD NOTHING;
CREATE RULE my_table_read_only_update AS ON UPDATE TO my_table DO INSTEAD NOTHING;
CREATE RULE my_table_read_only_delete AS ON DELETE TO my_table DO INSTEAD NOTHING;