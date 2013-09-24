require 'bundler/capistrano'
require 'capistrano-unicorn'

set :application, "bubblevine"
set :repository,  "https://github.com/orangejulius/bubblevine.git"
set :domain, "bubblevine.io"

role :app, domain
role :web, domain
role :db, domain, primary: true

set :user, 'bubblevine'
set :deploy_to, '/home/bubblevine'
set :use_sudo, false

after 'deploy:restart', 'unicorn:restart'  # app preloaded
after 'deploy:finalize_update', 'config:symlink'

namespace :config do
  desc "Symlink the configuration files for the app"
  task :symlink do
    run <<-CMD
      for i in `ls -A #{shared_path}/config`; do
        if test -f "#{shared_path}/config/$i"; then
          ln -nfs "#{shared_path}/config/$i" "#{release_path}/config/$i";
        fi;
      done;
    CMD
  end
end
