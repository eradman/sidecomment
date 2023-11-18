# cat puma.rb
app_dir = __dir__
port 9292
pidfile "#{app_dir}/run/puma.pid"
state_path "#{app_dir}/run/puma.state"
directory "#{app_dir}/"
stdout_redirect "#{app_dir}/log/puma.stdout.log", "#{app_dir}/log/puma.stderr.log", true
workers 3
threads 1, 1
activate_control_app "unix://#{app_dir}/run/pumactl.sock"
