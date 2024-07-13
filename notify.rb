require_relative 'data'
require_relative 'messaging'

# Periodic notifications

def notify_tickets
  tickets = tickets_pending_notification
  tickets.each do |row|
    usercodes = PG::TextDecoder::Array.new.decode(row['usercode_ids'])
    send_open_summary(row['sitecode_email'], row['sitecode_id'],
                      row['hostname'], usercodes,
                      row['count'].to_i)
    mark_ticket_sent(usercodes)
  end
  tickets
end

def notify_replies
  replies = replies_pending_notification
  replies.each do |row|
    reply_ids = PG::TextDecoder::Array.new.decode(row['reply_ids'])
    send_reply_summary(row['account_email'], row['hostname'],
                       row['usercode_id'], row['ticket_id'],
                       row['count'].to_i)
    mark_reply_sent(row['account_email'], reply_ids)
  end
  replies
end
