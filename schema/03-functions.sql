/*
 * generate a unique 11 character url-safe random alphanumeric ID
 */
CREATE OR REPLACE FUNCTION shortkey_generate(table_name text, id_column text)
RETURNS text AS $$
DECLARE
  gkey TEXT;
  key TEXT;
  found TEXT;
  n INTEGER = 0;
BEGIN
  LOOP
    n = n + 1;
    gkey = encode(gen_random_bytes(8), 'base64');
    gkey = replace(gkey, '/', '_');  -- url safe
    gkey = replace(gkey, '+', '_');  -- url safe
    key = rtrim(gkey, '=');

    EXECUTE format(
      'SELECT %I FROM %I WHERE %I = %L',
      id_column, table_name, id_column, key
    )
    INTO found;

    IF found IS NULL THEN
      EXIT;
    ELSE
      RAISE NOTICE 'Duplicate key found: %, retrying', key;
    END IF;

    IF n > 5 THEN
      RAISE EXCEPTION 'shortkey_generate: retry too many times';
    END IF;
  END LOOP;

  RETURN key;
END
$$ language 'plpgsql';
