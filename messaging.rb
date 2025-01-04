require 'net/smtp'

require_relative 'data'

# common

def send_msg(mailto, subject, msg)
  raise 'mailto is nil' if mailto.nil?
  raise 'subject is nil' if subject.nil?
  raise 'msg is nil' if msg.nil?

  msgstr = <<~MSG
    From: sidecomment <www@sidecomment.io>
    To: #{mailto}
    Subject: #{subject}

    #{msg}
  MSG

  return unless ENV['RACK_ENV'] == 'production'

  if defined? request
    record_notification(mailto, subject, request.ip)
  else
    record_notification(mailto, subject, '127.0.0.1')
  end

  Net::SMTP.start('localhost') do |smtp|
    smtp.send_message msgstr, 'www@sidecomment.io', mailto
  end
end

# actions

def send_usercode_confirmation(email, hostname, usercode, otp)
  msg = <<~MSG
    Source:

    https://sidecomment.io/comment

    Domain Name: #{hostname}

    Use the following link to confirm the new usercode:

    https://sidecomment.io/account?otp=#{otp}&usercode=#{usercode}
  MSG

  send_msg(email, 'Usercode Activation', msg)
end

def send_sitecode_confirmation(email, hostnames, sitecode, otp)
  msg = <<~MSG
    Source:

    https://sidecomment.io/install

    Domains:

    #{hostnames.join("\n")}

    Use the following link to confirm the new sitecode:

    https://sidecomment.io/account?otp=#{otp}&sitecode=#{sitecode}
  MSG

  send_msg(email, 'Sitecode Activation', msg)
end

def send_one_time_login(email, otp)
  msg = <<~MSG
    Browser

    #{request.user_agent}

    One-time login

    https://sidecomment.io/account?otp=#{otp}
  MSG

  send_msg(email, 'Account Link', msg)
end

def send_open_summary(sitecode_email, sitecode_id, hostname, usercodes, count)
  ticket_summary = ''
  usercodes.each do |usercode_id|
    account = fetch_account(usercode_id, :usercode)
    ticket_summary << "Author: #{account['username']}\n"
    ticket_summary << " https://sidecomment.io/tickets/#{usercode_id}\n"
  end

  msg = <<~MSG
    Sitecode: #{sitecode_id}

    #{ticket_summary}
  MSG
  send_msg(sitecode_email, "(#{count}) new tickets for #{hostname}", msg)
end

def send_reply_summary(account_email, hostname, usercode_id, ticket_id, count)
  msg = <<~MSG
    URL: https://sidecomment.io/tickets/#{usercode_id}

    #{reply_summary(ticket_id, count)}
  MSG
  send_msg(account_email, "(#{count}) new replies for #{hostname}", msg)
end

def reply_summary(ticket_id, limit = 99)
  replies = fetch_replies(ticket_id, limit)

  reply_text = ''
  replies.reverse_each do |row|
    reply_text << "\n #{row['username']}  #{row['created']}\n"
    reply_text << "\n  #{row['comment_area']}\n"
  end
  reply_text
end

def send_ticket_close_summary(ticket_id)
  ticket = fetch_ticket(ticket_id)

  hostname = URI.parse(ticket['url']).host
  msg = <<~MSG
    Created: #{ticket['created']}

    URL: #{ticket['url']}

    Selection

    #{ticket['base']}
    #{ticket['selection']}
    #{ticket['extent']}

    Comments

    #{ticket['comment_area']}

    Replies
    #{reply_summary(ticket_id)}
  MSG
  send_msg(ticket['author'], "Ticket closed for #{hostname}", msg)
end

def send_issue_close_summary(ticket_id)
  ticket = fetch_ticket(ticket_id)

  msg = <<~MSG
    Created: #{ticket['created']}

    Comments

    #{ticket['comment_area']}

    Replies
    #{reply_summary(ticket_id)}
  MSG
  send_msg(ticket['author'], 'Issue closed', msg)
end
