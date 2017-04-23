namespace :load do
  task :defaults do
    set :foreman_template, 'systemd'
    set :foreman_export_path, ->{ File.join(shared_path, 'systemd') }
    set :foreman_options, ->{ {
        app: 'trader',
        log: File.join(shared_path, 'log')
    } }
  end
end

