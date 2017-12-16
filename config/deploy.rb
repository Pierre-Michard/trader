# config valid only for current version of Capistrano
lock "3.8.2"

set :application, "trader"
set :repo_url, "git@github.com:Pierre-Michard/trader.git"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/home/trader/app"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
append :linked_files, "config/secret/kraken.yml", "config/secret/paymium.yml", "config/secret/gdax.yml", '.env'

# Default value for linked_dirs is []
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system", "node/node_modules"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5
set :user, "trader"

set :foreman_template, 'systemd'
set :foreman_export_path, ->{ File.join(shared_path, 'systemd') }
set :foreman_options, ->{ {
    app: 'trader',
    log: File.join(shared_path, 'log')
} }


after 'deploy:publishing', 'foreman:export'
after 'foreman:export', 'app:restart'
after 'app:restart', 'app:create_restart_script'