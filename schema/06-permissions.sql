/*
 * webui
 */

GRANT USAGE ON SCHEMA archive TO webui;

GRANT SELECT,INSERT ON notify_log TO webui;
GRANT SELECT,INSERT ON reply TO webui;
GRANT SELECT,INSERT ON sitecode TO webui;

GRANT SELECT,INSERT,UPDATE ON account TO webui;
GRANT SELECT,INSERT,UPDATE ON sitecode TO webui;
GRANT SELECT,INSERT,UPDATE ON ticket TO webui;
GRANT SELECT,INSERT,UPDATE ON usercode TO webui;

GRANT SELECT,INSERT,DELETE ON reply_queue TO webui;

-- sequences

GRANT UPDATE ON account_account_id_seq TO webui;
GRANT UPDATE ON reply_reply_id_seq TO webui;
GRANT UPDATE ON ticket_ticket_id_seq TO webui;

-- archive schema

GRANT SELECT ON archive.usercode TO webui;
GRANT SELECT ON archive.ticket TO webui;

/*
 * system
 */

GRANT USAGE ON SCHEMA archive TO system;

GRANT SELECT,DELETE ON reply TO system;
GRANT SELECT,DELETE ON ticket TO system;
GRANT SELECT,DELETE ON usercode TO system;

GRANT SELECT,INSERT ON archive.ticket TO system;
GRANT SELECT,INSERT ON archive.usercode TO system;
