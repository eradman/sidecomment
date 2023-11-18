CREATE SCHEMA unit_tests;

CREATE OR REPLACE FUNCTION unit_tests.now() RETURNS timestamp AS $$
BEGIN
    RETURN '2021-10-01 10:00:00-05'::timestamp;
END;
$$ LANGUAGE plpgsql;

ALTER USER CURRENT_USER SET search_path = unit_tests, public, pg_catalog;
