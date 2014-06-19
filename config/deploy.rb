# config valid only for Capistrano 3.1
require 'yaml'
lock '3.1.0'
set :application, 'democapapp'
set :deploy_to, '/home/nyros/anusha/democapapp'
SSHKit.config.command_map[:rake]  = "#{fetch(:default_env)[:rvm_bin_path]}/rvm ruby-#{fetch(:rvm_ruby_version)} do bundle exec rake"
set :repo_url, 'https://github.com/anusha-nyros/democapapp.git'
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
 #set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
 set :keep_releases, 5

set :template_dir, '/home/nyros/Anu/ROR_Projects/June/Jun19/democapapp/config/deploy'

set :asset_env, "RAILS_GROUPS=assets DATABASE_URL=postgresql://postgres:root@localhost/#{fetch(:application)}_#{fetch(:rails_env)}"
#set :filter, :hosts => %w{heroku.com, 10.90.90.110}

namespace :deploy do

 task :start do
	on roles(:app) do
        within release_path do
          with rails_env: fetch(:rails_env) do
	set :app_port, ask("Port", nil)
	execute :bundle, "exec thin start -p #{fetch(:app_port)} -d -e RAILS_ENV=#{fetch(:rails_env)}"
        #execute :bundle, "exec rails s -p 2003 -d -e RAILS_ENV=#{fetch(:rails_env)}"
          end
        end
      end
  end

  desc "Stop the Thin processes"
  task :stop do
      on roles(:app) do
        within release_path do
          with rails_env: fetch(:rails_env) do
	execute :bundle, "exec thin stop -p #{fetch(:app_port)} -d -e RAILS_ENV=#{fetch(:rails_env)}"
        #execute :bundle, "exec rails s -p 2003 -d -e RAILS_ENV=#{fetch(:rails_env)}"
          end
        end
      end
  end

desc "Setting Database configuration"
 task :generate_yml do
	puts "sfshfsdad"
	on roles(:app) do
		set :db_username, ask("DB Server Username", nil)
		set :db_password, ask("DB Server Password", nil)
		 
		db_config = <<-EOF
development:
  database: #{fetch(:application)}_development
  adapter: mysql2
  encoding: utf8
  reconnect: false
  pool: 5
  username: #{fetch(:db_username)}
  password: #{fetch(:db_password)}		 
test:
  database: #{fetch(:application)}_test
  adapter: mysql2
  encoding: utf8
  reconnect: false
  pool: 5
  username: #{fetch(:db_username)}
  password: #{fetch(:db_password)}   
production:
  database: #{fetch(:application)}_production
  adapter: mysql2
  encoding: utf8
  reconnect: false
  pool: 5
  username: #{fetch(:db_username)}
  password: #{fetch(:db_password)}
EOF
		location = fetch(:template_dir, "config/deploy") + '/database.yml'
		#template = File.file?(location) ? File.read(location) : db_config

		#config = ERB.new(template)

		execute "mkdir -p #{shared_path}/config"
		puts "#{location}"
		File.open(location,'w+') {|f| f.write db_config }
	        #File.open("#{location}", 'w') { |f| db_config.to }
		#puts "#{location}"
     		#upload! "#{location}", "#{shared_path}/config/database.yml"
		#File.write('', "#{db_config}")
		#execute :system, "echo #{db_config}" > "#{shared_path}/config/database.yml"
		#upload! db_config, "#{shared_path}/config/database.yml"
		#execute :put, '#{db_config.to_yaml}, "#{shared_path}/config/database.yml"'
		#put("#{db_config}", "#{shared_path}/config/database.yml") 
		#execute "cat #{db_config}" > "#{shared_path}/config/database.yml"
		#execute "File.open('#{shared_path}/config/database.yml', 'w') { |file| file.write('#{db_config}') }"
		#execute "File.write('#{shared_path}/config/database.yml','#{db_config}')"
		puts "#{db_config}"
		#template = File.expand_path('../database.yml', __FILE__)
		upload! "#{location}", "#{shared_path}/config/database.yml"
puts "sfhsgdfjsgdfj"
	end
end
before "deploy:assets:precompile", :generate_yml
desc "Starting Heroku application"
task :configure do
  on roles(:web) do
	puts "heroku starting"
	with path: 'git@heroku.com:#{fetch(:application)}.git' do
		puts `heroku keys`
	end
  end
end  

desc "Pushing to Heroku "
task :push do
  on roles(:all) do
	puts "Pushing heroku application"
	with path: 'git@heroku.com:#{fetch(:application)}.git' do
		puts `git push -f heroku master`
	end
  end
end
#after "deploy:started", "deploy:rename"
after "deploy:started", "deploy:push"

desc 'precompile application'
task :heroku_precompile do
	on roles(:all), in: :sequence, wait: 5 do
		puts `heroku run rake assets:precompile --app #{fetch(:application)}`
	end
   end
  desc 'migrate application'
  task :heroku_migrate do
    on roles(:all), in: :sequence, wait: 5 do
	puts "Migration started"
      puts `heroku run rake db:migrate --app #{fetch(:application)}`
    end
  end


desc "Heroku running"
task :heroku_start do
	on roles(:all) do
		puts "heroku starting"
		with path: 'git@heroku.com:#{fetch(:application)}.git' do
			puts `heroku open`
		end
 	end
end
after :finished, :heroku_start
  desc 'Restart application'
  task :restart do
     on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
	puts "Deployed successfully"
      #execute "touch #{release_path}/tmp/restart.txt"
     # execute "touch #{current_path}/tmp/thin.pid"
	#execute :bundle, "exec thin restart -p 2003 -d -e RAILS_ENV=#{fetch(:rails_env)}"
    end
  end


 desc "Linking Database.yml file"
 task :symlink do
    on roles(:app) do
     execute "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/"
    end
 end

desc 'Runs rake db:create'
    task :create => [:set_rails_env] do
      on primary fetch(:migration_role) do
        within release_path do
          with rails_env: fetch(:rails_env) do
            execute :rake, "db:create RAILS_ENV=#{fetch(:rails_env)}"
          end
        end
      end
    end

    desc "compile assets locally and upload before finalize_update"
    task :assets do
	on roles(:app) do
	        %x[bundle exec rake assets:clean && bundle exec rake assets:precompile]
        	ENV['COMMAND'] = " mkdir '#{release_path}/public/assets'"
        	invoke
		template = File.expand_path('../public/assets', __FILE_)
        	upload! '#{template}', "#{release_path}/public/assets", {:recursive => true}
	end
    end
after "deploy:finishing", "deploy:assets"


before "deploy:assets:precompile", :symlink 
before "deploy:migrate", :create
before "deploy:assets:precompile", "deploy:heroku_precompile"
before "deploy:migrate", "deploy:heroku_migrate" 
  after :publishing, :restart
 after :restart, :start
  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end
