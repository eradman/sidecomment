CREATE MATERIALIZED VIEW archive_tag_summary AS
    SELECT tag.name, count(tag.name)
    FROM archive.ticket
    JOIN archive.usercode USING (usercode_id)
    JOIN tag USING (tag_id)
    GROUP BY tag.name;

CREATE VIEW sidecomment_stats AS
SELECT usename, query, calls, total_exec_time, min_exec_time, max_exec_time,
       mean_exec_time, stddev_exec_time, rows
FROM pg_stat_statements
JOIN pg_user ON userid=userid
WHERE usename IN ('system', 'webui')
LIMIT 10;

ALTER TABLE archive_tag_summary OWNER TO system;
ALTER TABLE sidecomment_stats OWNER TO system;
