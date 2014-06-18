# config valid only for Capistrano 3.1
lock '3.1.0'

set :default_env, { rvm_bin_path: '~/.rvm/bin' }
set :application, 'cap_demo'
set :deploy_to, '/var/www/anusha/#{fetch(:application)}'
SSHKit.config.command_map[:rake]  = "#{fetch(:default_env)[:rvm_bin_path]}/rvm ruby-#{fetch(:rvm_ruby_version)} do bundle exec rake"
set :repo_url, 'git://github.com/anusha-nyros/democapapp.git'
set :rails_env, "production"
# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# Default deploy_to directory is /var/www/my_app
# set :deploy_to, '/var/www/my_app'

# Default value for :scm is :git
set :scm, :git

# Default value for :format is :pretty
 set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
 set :pty, true

# Default value for :linked_files is []
 set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
 set :keep_releases, 5


 
namespace :deploy do
 before :deploy, "deploy:configure"

desc "Starting Heroku application"
task :configure do
  on roles(:all) do
	puts "heroku starting"
	execute "heroku login"
	set :heroku_username, ask("Heroku Username", nil)
	set :heroku_password, ask("Heroku Password", nil)
	set :user, "#{fetch(:heroku_username)}"
	set :password, "#{fetch(:heroku_password)}"
	execute "heroku create"
	execute "heroku apps:rename democapapp"
	execute :rake, "assets:precomplie RAILS_ENV=#{fetch{rails_env}}"
  end
end  

desc "Renaming Heroku application"
task :rename do
  on roles(:all) do
	puts "renaming application"
	
  end
end

desc "Pushing to Heroku "
task :push do
  on roles(:all) do
	puts "Pushing heroku application"
	execute "git push heroku master"
  end
end
#after "deploy:started", "deploy:rename"
after "deploy:started", "deploy:push"
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
	puts "Deployed successfully"
      execute "touch #{release_path}/tmp/restart.txt"
    end
  end

  desc 'migrate application'
  task :heroku_migrate do
    on roles(:all), in: :sequence, wait: 5 do
	puts "Migration started"
      execute "heroku run rake db:migrate"
    end
  end


desc "Heroku running"
task :heroku_start do
	on roles(:all) do
		puts "heroku starting"
		execute "heroku open"
 	end
end
after :publishing, :heroku_start

 desc "Linking Database.yml file"
 task :symlink do
    on roles(:app) do
     execute "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/"
    end
 end
desc "Setting Database configuration"
 task :generate_yml do
	on roles(:all) do
		set :db_username, ask("DB Server Username", nil)
		set :db_password, ask("DB Server Password", nil)
		 
		db_config = <<-EOF
		base: &base
		adapter: mysql2
		encoding: utf8
		reconnect: false
		pool: 5
		username: #{fetch(:db_username)}
		password: #{fetch(:db_password)}
		 
		development:
		database: #{fetch(:application)}_development
		<<: *base
		 
		test:
		database: #{fetch(:application)}_test
		<<: *base
		 
		production:
		database: #{fetch(:application)}_production
		<<: *base
		EOF
		 
		execute "mkdir -p #{shared_path}/config"
		execute "cat #{db_config}">"#{shared_path}/config/database.yml"
		#put db_config, "#{shared_path}/config/database.yml"
	end
end
before "deploy:migrate", :generate_yml
before "deploy:migrate", :symlink 
before "deploy:migrate", "deploy:heroku_migrate" 
  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end
