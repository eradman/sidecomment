/*
 * archiving
 */

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
