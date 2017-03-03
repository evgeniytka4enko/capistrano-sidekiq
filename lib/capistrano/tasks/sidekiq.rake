namespace :load do
  task :defaults do
    set :sidekiq_env, -> { fetch(:rack_env, fetch(:rails_env, fetch(:stage))) }
    set :sidekiq_pid, -> { File.join(shared_path, 'tmp', 'pids', 'sidekiq.pid') }
    set :sidekiq_log, -> { File.join(shared_path, 'log', 'sidekiq.log') }
    set :sidekiq_service, -> { "sidekiq-#{fetch(:application).downcase.gsub(/[ _]/, '-')}" }
  end
end

namespace :sidekiq do
  desc 'Generate and upload systemd service config'
  task :update_systemd do
    on roles(:app) do
      systemd_config_file = File.expand_path(File.join('..', '..', 'templates', 'sidekiq.service.erb'), __FILE__)
      systemd_config = ERB.new(IO.read(systemd_config_file)).result(binding)

      systemd_config_name = "#{fetch(:sidekiq_service)}.service"
      tmp_path = "/tmp/#{systemd_config_name}"
      upload!(StringIO.new(systemd_config), tmp_path)

      path = "/lib/systemd/system/#{systemd_config_name}"
      sudo :mv, tmp_path, path
      sudo :systemctl, :enable, fetch(:sidekiq_service)
      sudo :systemctl, 'daemon-reload'
    end
  end

  desc 'Check if has systemd service config'
  task :check_systemd do
    on roles(:app) do
      systemd_config_name = "#{fetch(:sidekiq_service)}.service"
      path = "/lib/systemd/system/#{systemd_config_name}"
      unless test "[ -f #{path} ]"
        invoke 'sidekiq:update_systemd'
      end
    end
  end

  desc 'Start the sidekiq via systemd'
  task :start do
    on roles(:app) do
      sudo :service, fetch(:sidekiq_service), :start
    end
  end

  desc 'Stop the sidekiq via systemd'
  task :stop do
    on roles(:app) do
      sudo :service, fetch(:sidekiq_service), :stop
    end
  end

  desc 'Restart the sidekiq via systemd'
  task :restart do
    on roles(:app) do
      sudo :service, fetch(:sidekiq_service), :restart
    end
  end

  desc 'Quiet sidekiq (stop accepting new work)'
  task :quiet do
    on roles(:app) do
      execute "if [ -d #{current_path} ] && [ -f #{fetch(:sidekiq_pid)} ] && kill -0 `cat #{fetch(:sidekiq_pid)}`> /dev/null 2>&1; then cd #{current_path} && /bin/bash -lc 'bundle exec sidekiqctl quiet #{fetch(:sidekiq_pid)}' ; else echo 'Sidekiq is not running'; fi"
    end
  end
end

after 'deploy:starting', 'sidekiq:check_systemd'
after 'deploy:starting', 'sidekiq:quiet'
after 'deploy:updated', 'sidekiq:stop'
after 'deploy:reverted', 'sidekiq:stop'
after 'deploy:published', 'sidekiq:start'