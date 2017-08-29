SERVICES = %w{trader-web@15000.service trader-paymium_private_node@15100.service trader-kraken_public_node@15200.service trader-jobs@15300.service trader-resque@15400.service trader-paymium_public_node@15500.service trader-resque_refresh@15600.service trader-resque_scheduler@15700.service}

namespace :app do
  desc "Enable web server"
  task :enable do
    on roles(:web) do |host|
      within release_path do
        execute :sudo, :systemctl, "daemon-reload"
        SERVICES.each do |service|
          execute :sudo, :systemctl, :enable, service
        end
      end
    end
  end

  desc "Start web server"
  task :start do
    on roles(:web) do |host|
      within release_path do
        execute :sudo, :systemctl, "daemon-reload"
        SERVICES.each do |service|
          execute :sudo, :systemctl, :start, service
        end
      end
    end
  end

  desc "Stop web server"
  task :stop do
    on roles(:web) do |host|
      within release_path do
        SERVICES.each do |service|
          execute :sudo, :systemctl, :stop, service
        end
      end
    end
  end

  desc "Restart web server"
  task :restart do
    on roles(:web) do |host|
      within release_path do
        execute :sudo, :systemctl, "daemon-reload"
        SERVICES.each do |service|
          execute :sudo, :systemctl, :restart, service
        end
      end
    end
  end

  desc "Create a restart script"
  task :create_restart_script do
    on roles(:web) do |host|
      file_path = '/etc/cron.daily/restart_trader_services'

      file_content = "#!/bin/sh\n"
      file_content += SERVICES.
          map{|s| s.gsub('.service', '')}.
          map{|s| "service #{s} restart"}.
          join("\n")

      execute :sudo, :echo, "'#{file_content}' >/tmp/script"
      execute :sudo, :mv, '/tmp/script', file_path
      execute :sudo, :chmod, "+x #{file_path}"
    end
  end
end
