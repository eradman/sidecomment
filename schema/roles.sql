CREATE ROLE sidecomment LOGIN;
CREATE ROLE webui LOGIN;
CREATE ROLE system LOGIN;

GRANT system TO sidecomment;
GRANT pg_read_all_stats to system;
