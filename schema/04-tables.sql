CREATE TABLE account (
  account_id serial PRIMARY KEY,
  created timestamp with time zone NOT NULL DEFAULT now(),
  email varchar(128) NOT NULL UNIQUE,
  username varchar(32) NOT NULL UNIQUE,
  otp char(20) NOT NULL DEFAULT upper(substr(md5(random()::text), 0, 21)),
  last_auth timestamp with time zone,
  home_page varchar(128),
  location varchar(128)
);

CREATE TABLE sitecode (
  sitecode_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created timestamp with time zone NOT NULL DEFAULT now(),
  domains host[] NOT NULL,
  email varchar(128) REFERENCES account (email) NOT NULL,
  verified boolean NOT NULL DEFAULT 'f'
);

CREATE TABLE usercode (
  usercode_id shortkey PRIMARY KEY DEFAULT shortkey_generate('usercode', 'usercode_id'),
  created timestamp with time zone NOT NULL DEFAULT now(),
  email varchar(128) REFERENCES account (email) NOT NULL,
  hostname host NOT NULL,
  verified boolean NOT NULL DEFAULT 'f'
);

CREATE TABLE tag (
  tag_id serial PRIMARY KEY,
  name varchar(20) NOT NULL UNIQUE,
  created timestamp with time zone NOT NULL DEFAULT now(),
  modified timestamp with time zone NOT NULL DEFAULT now()
);

SELECT setval('tag_tag_id_seq', 1000);

CREATE TABLE ticket (
  ticket_id serial PRIMARY KEY,
  created timestamp with time zone NOT NULL DEFAULT now(),
  usercode_id shortkey REFERENCES usercode (usercode_id) NOT NULL,
  sitecode_id uuid REFERENCES sitecode (sitecode_id) NOT NULL,
  url varchar(4096),
  base text,
  selection text,
  extent text,
  topic varchar(30),
  comment_area text NOT NULL,
  closed timestamp with time zone,
  tag_id integer REFERENCES tag (tag_id),
  summary_sent boolean NOT NULL DEFAULT 'f'
);

CREATE TABLE reply (
  reply_id serial PRIMARY KEY,
  account_id integer REFERENCES account (account_id) NOT NULL,
  created timestamp with time zone NOT NULL DEFAULT now(),
  ticket_id integer REFERENCES ticket (ticket_id) NOT NULL,
  comment_area text NOT NULL
);

/*
 * notifications
 */

CREATE TABLE notify_log (
  sent timestamp with time zone NOT NULL DEFAULT now(),
  mailto varchar(128) NOT NULL,
  subject text NOT NULL,
  remote_addr inet NOT NULL
);

CREATE INDEX lotify_log_sent ON notify_log (sent);

CREATE TABLE notify_reply (
  email varchar(128) NOT NULL,
  trigger_reply_id integer REFERENCES reply (reply_id) NOT NULL
);

/*
 * archive schema
 */

CREATE SCHEMA archive;

CREATE TABLE archive.operation_log (
  event_time timestamp with time zone NOT NULL DEFAULT now(),
  operation text,
  table_name text,
  primary_key text
);

CREATE TABLE archive.usercode (
  usercode_id shortkey PRIMARY KEY,
  created timestamp with time zone NOT NULL,
  email varchar(128) NOT NULL REFERENCES account (email) NOT NULL,
  hostname varchar(128) NOT NULL
);

CREATE TABLE archive.tag (
  tag_id serial PRIMARY KEY,
  name varchar(20) NOT NULL UNIQUE,
  created timestamp with time zone NOT NULL,
  modified timestamp with time zone NOT NULL
);

CREATE TABLE archive.ticket (
  ticket_id serial PRIMARY KEY,
  created timestamp with time zone NOT NULL,
  usercode_id shortkey REFERENCES archive.usercode (usercode_id) NOT NULL,
  sitecode_id uuid NOT NULL,
  url varchar(4096),
  closed timestamp with time zone,
  tag_id integer REFERENCES tag (tag_id),
  reply_count integer
);
