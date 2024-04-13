CREATE MATERIALIZED VIEW archive_tag_summary AS
    SELECT tag.name, count(tag.name)
    FROM archive.ticket
    JOIN archive.usercode USING (usercode_id)
    JOIN tag USING (tag_id)
    GROUP BY tag.name;

ALTER TABLE archive_tag_summary OWNER TO system;
