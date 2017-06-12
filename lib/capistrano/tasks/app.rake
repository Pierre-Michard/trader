SERVICES = %w{trader-web@15000.service trader-paymium_private_node@15100.service trader-kraken_public_node@15200.service trader-jobs@15300.service trader-resque@15400.service trader-paymium_public_node@15500.service}

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
end
