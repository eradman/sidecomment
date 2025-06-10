/*
 * rate limits
 */

CREATE OR REPLACE FUNCTION notify_log_insert_check() RETURNS trigger
  LANGUAGE plpgsql
AS $$
DECLARE
  per_minute integer;
  per_hour integer;
BEGIN
  IF (NEW.remote_addr != '127.0.0.1') THEN
    SELECT count(mailto)
    INTO per_minute
    FROM public.notify_log
    WHERE remote_addr = NEW.remote_addr
    AND sent > now() - interval '1 minute';

    SELECT count(*)
    INTO per_hour
    FROM public.notify_log
    WHERE remote_addr = NEW.remote_addr
    AND sent > now() - interval '1 hour';

    IF (per_minute > 2 OR per_hour > 10) THEN
      RAISE EXCEPTION 'notify_log limit';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER notify_log_insert
BEFORE INSERT ON notify_log
FOR EACH ROW EXECUTE PROCEDURE notify_log_insert_check();
