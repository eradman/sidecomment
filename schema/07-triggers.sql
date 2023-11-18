/*
 * data integrity / auto-population
 */
CREATE OR REPLACE FUNCTION insert_account() RETURNS trigger
  LANGUAGE plpgsql
AS $$
  DECLARE rnd text = '';
  DECLARE username text;
BEGIN
  username = split_part(NEW.email, '@', 1);

  EXECUTE format(
    'SELECT true FROM account WHERE username = %L',
    username
  )
  INTO found;

  IF found IS NOT NULL THEN
    rnd = floor(random() * (1000-100+1) + 100)::text;
  END IF;

  INSERT INTO account (email, username)
  VALUES (NEW.email, username || rnd)
  ON CONFLICT (email) DO NOTHING;

  RETURN NEW;
END;
$$;

CREATE TRIGGER insert_sitecode
BEFORE INSERT ON sitecode
FOR EACH ROW EXECUTE PROCEDURE insert_account();

CREATE TRIGGER insert_usercode
BEFORE INSERT ON usercode
FOR EACH ROW EXECUTE PROCEDURE insert_account();

/*
 * notifications
 */

CREATE OR REPLACE FUNCTION insert_reply() RETURNS trigger
  LANGUAGE plpgsql
AS $$
BEGIN
  -- accounts that previously replied to this ticket and the site owner
  -- exclude current user
  WITH records AS (
    SELECT account.email,
           NEW.reply_id AS trigger_reply_id
    FROM reply
    JOIN ticket USING (ticket_id)
    JOIN account USING (account_id)
    WHERE ticket_id=NEW.ticket_id AND account_id!=NEW.account_id
    UNION
    SELECT sitecode.email,
           NEW.reply_id
    FROM ticket
    JOIN sitecode USING (sitecode_id)
    JOIN account USING (email)
    WHERE ticket_id=NEW.ticket_id AND account_id!=NEW.account_id
  )
  INSERT INTO notify_reply (email, trigger_reply_id)
  SELECT *
  FROM records;

  RETURN NEW;
END;
$$;

CREATE TRIGGER insert_reply
AFTER INSERT ON reply
FOR EACH ROW EXECUTE PROCEDURE insert_reply();
