# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary
# server in each group is considered to be the first
# unless any hosts have the primary property set.
# Don't declare `role :all`, it's a meta role
role :app, %w{anusha-nyros@github.com, 10.90.90.110}
role :web, %w{democapapp.com, 10.90.90.110}
role :db,  %w{democapapp.com}, :primary => true

# Extended Server Syntax
# ======================
# This can be used to drop a more detailed server
# definition into the server list. The second argument
# something that quacks like a hash can be used to set
# extended properties on the server.
set :password, ask("Server Password", nil)
server 'github.com', user: 'anusha-nyros', :password => "#{fetch(:password)}", roles: %w{app}, my_property: :my_value
server 'democapapp.com', user: 'anusha_nyros@yahoo.com', :password => "#{fetch(:password)}", roles: %w{app,web,db}, my_property: :my_value
server '10.90.90.110', user: 'nyros', :password => "#{fetch(:password)}", roles: %w{app,db}, my_property: :my_value

# you can set custom ssh options
# it's possible to pass any option but you need to keep in mind that net/ssh understand limited list of options
# you can see them in [net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start)
# set it globally
#  set :ssh_options, {
#    keys: %w(/home/rlisowski/.ssh/id_rsa),
#    forward_agent: false,
#    auth_methods: %w(password)
#  }
# and/or per server
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
#   ssh_options: {
#     user: 'user_name', # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: 'please use keys'
#   }
# setting per server overrides global ssh_options
