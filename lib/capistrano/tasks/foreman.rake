namespace :load do
  task :defaults do
    set :foreman_template, 'supervisord'
    set :foreman_export_path, ->{ File.join(shared_path, 'supervisord') }
    set :foreman_options, ->{ {
        app: 'trader',
        log: File.join(shared_path, 'log')
    } }
  end
end

