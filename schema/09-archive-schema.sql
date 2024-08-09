/*
 * archiving
 */

CREATE OR REPLACE FUNCTION archive_update_log() RETURNS trigger
  LANGUAGE plpgsql
  AS
$$
DECLARE
  col TEXT = (
    SELECT attname
    FROM pg_index
    JOIN pg_attribute ON
        attrelid = indrelid
        AND attnum = ANY(indkey)
    WHERE indrelid = TG_RELID AND indisprimary
  );
BEGIN
  INSERT INTO archive.operation_log (operation, table_name, primary_key)
  VALUES(TG_OP, TG_TABLE_NAME, row_to_json(NEW) ->> col);
  RETURN NEW;
END;
$$;

CREATE TRIGGER archive_insert_usercode
AFTER INSERT OR UPDATE ON archive.usercode
FOR EACH ROW EXECUTE PROCEDURE public.archive_update_log();

CREATE TRIGGER archive_insert_ticket
AFTER INSERT OR UPDATE ON archive.ticket
FOR EACH ROW EXECUTE PROCEDURE archive_update_log();

CREATE OR REPLACE PROCEDURE prune_usercodes(interval_spec interval)
LANGUAGE sql
AS $$
DELETE FROM usercode
WHERE usercode_id IN (
  SELECT usercode.usercode_id
  FROM usercode
  LEFT JOIN ticket USING (usercode_id)
  WHERE ticket_id IS NULL
  AND verified = 'f'
  AND now() - usercode.created > interval_spec
);
$$;

CREATE OR REPLACE PROCEDURE archive_tickets(interval_spec interval)
LANGUAGE plpgsql
AS $$
DECLARE
  ticket_id integer;
  usercode_id shortkey;
  reply_count integer;
BEGIN
  FOR ticket_id, usercode_id, reply_count IN
    SELECT ticket.ticket_id, ticket.usercode_id, count(reply_id) AS reply_count
    FROM ticket
    LEFT JOIN reply USING (ticket_id)
    WHERE now() - ticket.closed > interval_spec
    GROUP BY ticket.ticket_id, ticket.usercode_id
  LOOP
    EXECUTE format(
        'INSERT INTO archive.usercode '
        'SELECT usercode_id, created, email, hostname '
        'FROM usercode WHERE usercode_id=%L '
        'ON CONFLICT DO NOTHING', usercode_id
    );
    EXECUTE format(
        'INSERT INTO archive.ticket '
        'SELECT ticket_id, created, usercode_id, sitecode_id, url, closed, %s '
        'FROM ticket WHERE ticket_id=%s '
        'ON CONFLICT DO NOTHING', reply_count, ticket_id
    );
    EXECUTE format(
        'DELETE FROM reply '
        'WHERE ticket_id=%s ', ticket_id
    );
    EXECUTE format(
        'DELETE FROM ticket '
        'WHERE ticket_id=%s ', ticket_id
    );
  END LOOP;
END;
$$;
