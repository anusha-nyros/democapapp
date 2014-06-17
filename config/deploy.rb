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

task :deploy => ['deploy:push', 'deploy:restart', 'deploy:tag']
 
namespace :deploy do
  task :migrations => [:push, :off, :migrate, :restart, :on, :tag]
  task :rollback => [:off, :push_previous, :restart, :on]
 
  task :push do
    puts 'Deploying site to Heroku ...'
    execute "git push heroku master"
  end
  
  task :restart do
    puts 'Restarting app servers ...'
    execute "heroku restart"
  end
  
  task :tag do
    release_name = "release-#{Time.now.utc.strftime("%Y%m%d%H%M%S")}"
    puts "Tagging release as '#{release_name}'"
    execute "git tag -a #{release_name} -m 'Tagged release'"
    execute "git push --tags heroku"
  end
  
  task :migrate do
    puts 'Running database migrations ...'
    execute "heroku rake db:migrate"
  end
  
  task :off do
    puts 'Putting the app into maintenance mode ...'
    execute "heroku maintenance:on"
  end
  
  task :on do
    puts 'Taking the app out of maintenance mode ...'
    execute "heroku maintenance:off"
  end
 
  task :push_previous do
    releases = `git tag`.split("\n").select { |t| t[0..7] == 'release-' }.sort
    current_release = releases.last
    previous_release = releases[-2] if releases.length >= 2
    if previous_release
      puts "Rolling back to '#{previous_release}' ..."
      
      puts "Checking out '#{previous_release}' in a new branch on local git repo ..."
      execute "git checkout #{previous_release}"
      execute "git checkout -b #{previous_release}"
      
      puts "Removing tagged version '#{previous_release}' (now transformed in branch) ..."
      execute "git tag -d #{previous_release}"
      execute "git push heroku :refs/tags/#{previous_release}"
      
      puts "Pushing '#{previous_release}' to Heroku master ..."
      execute "git push heroku +#{previous_release}:master --force"
      
      puts "Deleting rollbacked release '#{current_release}' ..."
      execute "git tag -d #{current_release}"
      execute "git push heroku :refs/tags/#{current_release}"
      
      puts "Retagging release '#{previous_release}' in case to repeat this process (other rollbacks)..."
      execute "git tag -a #{previous_release} -m 'Tagged release'"
      execute "git push --tags heroku"
      
      puts "Turning local repo checked out on master ..."
      execute "git checkout master"
      puts 'All done!'
    else
      puts "No release tags found - can't roll back!"
      execute releases
    end
  end
end
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
	puts "Deployed successfully"
      execute "touch #{release_path}/tmp/restart.txt"
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
desc "Setting Database configuration"
 task :generate_yml do
	on roles(:app,:web) do
		set :db_username, ask("DB Server Username", nil)
		set :db_password, ask("DB Server Password", nil)
		 
		db_config = <<-EOF
		base: &base
		adapter: postgresql
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
before "deploy:migrate", :generate_yml
before "deploy:migrate", :symlink 

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
