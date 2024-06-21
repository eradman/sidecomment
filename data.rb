# Copyright (c) 2021-2022 Ratical Software

require 'pg'

$pg_url = ENV['DATABASE_URL'] || 'postgresql://webui@localhost/sidecomment'
$pg_url_alt = nil

def db
  if $pg_url_alt.nil?
    $db ||= PG.connect($pg_url, 'fallback_application_name' => 'ruby')
  else
    $db = PG.connect($pg_url_alt)
  end
end

def db_system
  uri = URI($pg_url_alt || $pg_url)
  uri.user = 'system'
  $db_system&.close
  $db_system = PG.connect(uri.to_s, 'fallback_application_name' => 'ruby')
end

def usercode(usercode)
  sql = %(
    SELECT email,hostname
    FROM usercode
    WHERE usercode_id=$1
    AND verified='t';
  )
  db.exec(sql, [usercode])
end

def register_site(email, domains)
  sql = %{
    INSERT INTO sitecode (email, domains)
    VALUES ($1, $2)
    RETURNING sitecode_id;
  }
  domains_array = PG::TextEncoder::Array.new.encode(domains)
  db.exec(sql, [email, domains_array])[0]['sitecode_id']
end

def activate_site(sitecode)
  sql = %(
    UPDATE sitecode
    SET verified='t'
    WHERE sitecode_id=$1
    RETURNING verified;
  )
  db.exec(sql, [sitecode])[0]['verified']
end

def activate_user(usercode)
  sql = %(
    UPDATE usercode
    SET verified='t'
    WHERE usercode_id=$1
    RETURNING verified;
  )
  db.exec(sql, [usercode])[0]['verified']
end

def update_site(sitecode_id, domains)
  sql = %(
    UPDATE sitecode
    SET domains=$2
    WHERE sitecode_id=$1
    RETURNING sitecode_id, email, domains;
  )
  domains_array = PG::TextEncoder::Array.new.encode(domains)
  r = db.exec(sql, [sitecode_id, domains_array])
  r[0] if r.count.positive?
end

def generate_usercode(email, hostname)
  sql = %{
    INSERT INTO usercode (email, hostname)
    VALUES ($1, $2)
    RETURNING usercode_id;
  }
  db.exec(sql, [email, hostname])[0]['usercode_id']
end

def fetch_tickets(usercode)
  sql = %{
    SELECT ticket_id,
         to_char(ticket.created, 'FMMonth DD, YYYY') AS created,
         url, base, selection, extent, comment_area,
         usercode.email AS usercode_email,
         sitecode.email AS sitecode_email,
         account.username,
         topic,
         to_char(ticket.closed, 'FMMonth DD, YYYY') AS closed,
         tag.name AS tag_name
    FROM ticket
    LEFT JOIN tag USING (tag_id)
    JOIN usercode USING (usercode_id)
    JOIN sitecode USING (sitecode_id)
    JOIN account ON (account.email = usercode.email)
    WHERE usercode_id=$1
    ORDER BY ticket.created DESC;
  }
  db.exec(sql, [usercode])
end

def fetch_ticket(ticket_id)
  sql = %{
    SELECT ticket_id,
         to_char(ticket.created, 'FMMonth DD, YYYY') AS created,
         url, base, selection, extent, comment_area,
         account.email AS author,
         account.username,
         to_char(ticket.closed, 'FMMonth DD, YYYY') AS closed,
         tag.name AS tag_name,
         sitecode_id,
         usercode_id
    FROM ticket
    LEFT JOIN tag USING (tag_id)
    JOIN usercode USING (usercode_id)
    JOIN account USING (email)
    WHERE ticket_id=$1
    ORDER BY ticket.created;
  }
  r = db.exec(sql, [ticket_id])
  r[0] if r.count.positive?
end

def fetch_replies(ticket_id, limit = 99)
  sql = %{
    SELECT reply_id,
         to_char(ticket.created, 'Mon DD HH:MI') AS created,
         reply.comment_area,
         account.username,
         now() - reply.created < interval '1 minute' AS new
    FROM reply
    JOIN ticket USING (ticket_id)
    JOIN usercode USING (usercode_id)
    JOIN account USING (account_id)
    WHERE ticket_id=$1
    ORDER BY reply.created DESC
    LIMIT $2
  }
  db.exec(sql, [ticket_id, limit])
end

def fetch_sitecodes(email)
  sql = %(
    SELECT sitecode_id, domains
    FROM sitecode
    WHERE email=$1
    AND verified='t'
    ORDER BY created;
  )
  db.exec(sql, [email])
end

def fetch_sitecode(sitecode_id)
  sql = %(
    SELECT email, domains
    FROM sitecode
    WHERE sitecode_id=$1
  )
  r = db.exec(sql, [sitecode_id])
  r[0] if r.count.positive?
end

def fetch_account(key, relation)
  return if key.nil?

  case relation
  when :email
    sql = %(
        SELECT email, username, last_auth, home_page, location
        FROM account
        WHERE email=$1
      )
  when :username
    sql = %(
        SELECT email, username, last_auth, home_page, location
        FROM account
        WHERE username=$1
      )
  when :usercode
    sql = %{
        SELECT email, username, last_auth, home_page, location
        FROM account
        WHERE email=(SELECT email FROM usercode WHERE usercode_id=$1)
      }
  when :sitecode
    sql = %{
        SELECT email, username, last_auth, home_page, location
        FROM account
        WHERE email=(SELECT email FROM sitecode WHERE sitecode_id=$1)
      }
  else
    raise 'Unknown relation', relation
  end
  r = db.exec(sql, [key])
  r[0] if r.count.positive?
end

def fetch_registration(sitecode_id)
  sql = %(
    SELECT sitecode_id, email, domains
    FROM sitecode
    WHERE sitecode_id=$1
  )
  r = db.exec(sql, [sitecode_id])
  r[0] if r.count.positive?
end

def fetch_ticket_summary(sitecode_id)
  sql = %{
    SELECT ticket.usercode_id, url,
         to_char(ticket.created, 'Mon DD HH:MI') AS created,
         username AS author,
         count(reply_id) AS replies,
         CASE WHEN closed IS NULL
           THEN 'open'
           ELSE 'closed'
         END AS status,
         now() - ticket.created < interval '1 minute' AS new
    FROM ticket
    JOIN usercode USING (usercode_id)
    JOIN account USING (email)
    LEFT JOIN reply USING (ticket_id)
    WHERE sitecode_id=$1
    AND topic IS NULL
    GROUP BY ticket.usercode_id, url, ticket.created, account.username, status
    ORDER BY ticket.created DESC
  }
  db.exec(sql, [sitecode_id])
end

def fetch_issue_summary(sitecode_id)
  sql = %{
    SELECT ticket.usercode_id,
         to_char(ticket.created, 'Mon DD HH:MI') AS created,
         username AS author,
         topic,
         count(reply_id) AS replies,
         CASE WHEN closed IS NULL
           THEN 'open'
           ELSE 'closed'
         END AS status,
         now() - ticket.created < interval '1 minute' AS new
    FROM ticket
    JOIN usercode USING (usercode_id)
    JOIN account USING (email)
    LEFT JOIN reply USING (ticket_id)
    WHERE sitecode_id=$1
    GROUP BY ticket.usercode_id, ticket.created, account.username, topic, status
    ORDER BY ticket.created DESC
  }
  db.exec(sql, [sitecode_id])
end

def fetch_tag_stats(email)
  sql = %{
    WITH all_tags AS (
        SELECT tag.name
        FROM ticket
        JOIN usercode USING (usercode_id)
        JOIN tag USING (tag_id)
        WHERE email=$1
      UNION ALL
        SELECT tag.name
        FROM archive.ticket
        JOIN archive.usercode USING (usercode_id)
        JOIN tag USING (tag_id)
        WHERE email=$1
    )
    SELECT name, count(name)
    FROM all_tags
    GROUP BY name
    ORDER BY count DESC, name
  }
  db.exec(sql, [email])
end

def create_ticket(hostname, params)
  sql = %{
    WITH ins AS (
        SELECT sitecode_id
        FROM sitecode
        WHERE sitecode_id=$2
        AND domains::text[] @> ARRAY[$8]
    )
    INSERT INTO ticket (usercode_id, sitecode_id, url, base, selection, extent, comment_area)
    SELECT $1, sitecode_id, $3, $4, $5, $6, $7
    FROM ins
    RETURNING usercode_id, ticket_id;
  }
  r = db.exec(sql, [
                params['usercode_id'],
                params['sitecode_id'],
                params['url'],
                params['base'],
                params['selection'],
                params['extent'],
                params['comment_area'],
                hostname
              ])
  r[0] if r.count.positive?
end

def create_reply(_hostname, email, params)
  sql = %{
    INSERT INTO reply (account_id, ticket_id, comment_area)
    VALUES ((SELECT account_id FROM account WHERE email=$1), $2, $3)
    RETURNING reply_id, ticket_id;
  }
  db.exec(sql, [
            email,
            params['ticket_id'],
            params['comment_area']
          ])
end

def reset_otp(email)
  sql = %(
    UPDATE account
    SET otp=DEFAULT
    WHERE email=$1
    RETURNING otp
  )
  r = db.exec(sql, [email])
  r[0]['otp'] if r.count.positive?
end

def email_for_otp(otp)
  sql = %{
    UPDATE account
    SET last_auth=now()
    WHERE otp=$1
    RETURNING email
  }
  r = db.exec(sql, [otp])
  r[0]['email'] if r.count.positive?
end

def update_account(email, params)
  sql = %{
    UPDATE account
    SET username=$2, location=$3, home_page=$4, last_auth=now()
    WHERE email=$1
    RETURNING last_auth
  }
  r = db.exec(sql, [
                email,
                params['username'],
                params['location'],
                params['home_page']
              ])
  r[0] if r.count.positive?
end

def tag_and_close(ticket_id, tag)
  if tag
    sql = %{
      INSERT INTO tag (name)
      VALUES ($1)
      ON CONFLICT (name) DO NOTHING
    }
    db.exec(sql, [tag])

    sql = %{
      UPDATE ticket
      SET closed=now(), tag_id=(SELECT tag_id FROM tag WHERE name=$2)
      WHERE ticket_id=$1
      RETURNING tag_id, url
    }
    r = db.exec(sql, [ticket_id, tag])
  else
    sql = %{
      UPDATE ticket
      SET closed=now(), tag_id=NULL
      WHERE ticket_id=$1
      RETURNING tag_id, url
    }
    r = db.exec(sql, [ticket_id])
  end

  r[0] if r.count.positive?
end

def create_issue(email, origin, params)
  sql = %{
    INSERT INTO usercode (email, hostname)
    VALUES ($1, $2)
    RETURNING usercode_id;
  }
  usercode = db.exec(sql, [email, origin])[0]['usercode_id']
  sql = %{
    INSERT INTO ticket (usercode_id, sitecode_id, topic, comment_area)
    VALUES ($1, $2, $3, $4)
    RETURNING usercode_id, ticket_id;
  }
  r = db.exec(sql, [usercode,
                    params['sitecode_id'],
                    params['topic'],
                    params['comment_area']])
  r[0] if r.count.positive?
end

def mark_ticket_sent(usercodes)
  sql = %{
    UPDATE ticket
    SET summary_sent='t'
    WHERE usercode_id=ANY($1)
    AND summary_sent='f'
    RETURNING ticket_id
  }
  db.exec(sql, [PG::TextEncoder::Array.new.encode(usercodes)])
end

def mark_reply_sent(account_email, reply_ids)
  sql = %{
    DELETE FROM reply_queue
    WHERE email=$1
    AND trigger_reply_id=ANY($2)
    RETURNING email, trigger_reply_id
  }
  db.exec(sql, [account_email, PG::TextEncoder::Array.new.encode(reply_ids)])
end

def record_notification(mailto, subject, remote_addr)
  sql = %{
    INSERT INTO notify_log (mailto, subject, remote_addr)
    VALUES ($1, $2, $3)
    RETURNING sent;
  }
  db.exec(sql, [mailto, subject, remote_addr])
end

# system tasks

def archive_records
  sql = %{
    BEGIN;
    CALL prune_usercodes('30 days'::interval);
    CALL archive_tickets('30 days'::interval);
    REFRESH MATERIALIZED VIEW archive_tag_summary;
    COMMIT;
  }
  db_system.exec(sql)
end

def tickets_pending_notification
  sql = %{
    SELECT sitecode.email AS sitecode_email,
         sitecode.sitecode_id, usercode.hostname,
         array_agg(DISTINCT ticket.usercode_id) AS usercode_ids,
         count(ticket.usercode_id)
    FROM ticket
    JOIN usercode USING (usercode_id)
    JOIN sitecode USING (sitecode_id)
    WHERE ticket.summary_sent='f'
    AND usercode.verified='t'
    AND sitecode.verified='t'
    AND ticket.closed IS NULL
    GROUP BY sitecode.email, sitecode.sitecode_id, usercode.hostname
  }
  db.exec(sql, [])
end

def replies_pending_notification
  sql = %{
    SELECT reply_queue.email AS account_email,
           usercode_id,
           ticket_id,
           hostname,
           array_agg(DISTINCT trigger_reply_id) AS reply_ids,
           count(trigger_reply_id) OVER (PARTITION BY ticket_id)
    FROM reply_queue
    JOIN reply ON (trigger_reply_id=reply_id)
    JOIN ticket USING (ticket_id)
    JOIN usercode USING (usercode_id)
    GROUP BY trigger_reply_id, usercode_id, ticket_id, reply_queue.email, hostname
    ORDER BY trigger_reply_id
  }
  db.exec(sql, [])
end
