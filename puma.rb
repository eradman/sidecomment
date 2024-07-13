require_relative 'notify'

app_dir = __dir__
port 9292
pidfile "#{app_dir}/run/puma.pid"
state_path "#{app_dir}/run/puma.state"
directory "#{app_dir}/"
stdout_redirect "#{app_dir}/log/puma.out", "#{app_dir}/log/puma.err", true
workers 3
threads 1, 1
activate_control_app "unix://#{app_dir}/run/pumactl.sock"

def log(stream, label, message)
  ts = Time.now.strftime('%m-%d-%Y %H:%M:%S')
  stream.puts "#{ts} #{label} #{message}"
end

before_fork do
  fork do
    Process.setproctitle('puma: sidecomment scheduler')
    loop do
      log $stdout, 'notify_tickets', notify_tickets.to_a
      log $stdout, 'notify_replies', notify_replies.to_a
      sleep 600
    rescue StandardError => e
      log $stderr, 'error', e.full_message
      next
    end
  end
end
