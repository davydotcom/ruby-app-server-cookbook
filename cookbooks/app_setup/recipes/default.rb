include_recipe "git"
include_recipe "database"

node[:apps].each do |app|
  app_path = "/srv/www/#{app[:name]}"
  repo_path = "#{app_path}/#{app[:name]}.git"
  repo_cache_path = "#{app_path}/cached"
  releases_path = "#{app_path}/releases"

  # initialize bare git repo
  directory repo_path do
    recursive true
    owner app[:username]
    group app[:group] || app[:username]
    mode 0770
    action [:create]
  end

  bash "create repo" do
    code "cd #{repo_path} && git init --bare"
    not_if { File.exists?("#{repo_path}/HEAD") }
  end

  bash "own the repo" do
    code "chown -R deploy:www #{repo_path} && chmod -R 0770 #{repo_path}"
    only_if { File.exists?("#{repo_path}/HEAD") }
  end

  template "#{repo_path}/hooks/post-receive" do
    path "#{repo_path}/hooks/post-receive"
    source "post-receive.sh.erb"
    owner app[:username]
    group app[:group] || app[:username]    
    mode 0755
    variables(
      :app_user => app[:username],
      :app_path => app_path,
      :repo_path => repo_path,
      :repo_cache_path => repo_cache_path,
      :releases_path => releases_path,
      :git_branch => app[:git_branch] || "master",
      :rails_env => app[:rails_env],
      :keep_releases => app[:keep_releases] || 5
    )
    action :create
  end

  # Setup application system folders
  [
    app_path, 
    repo_cache_path,
    "#{app_path}/shared",
    "#{app_path}/shared/config",
    "#{app_path}/shared/tmp",
    "#{app_path}/shared/tmp/pids",
    "#{app_path}/shared/tmp/sockets",
    "#{app_path}/shared/log",
    "#{app_path}/shared/bundle",
    "#{app_path}/shared/public/assets",
    releases_path
  ].each do |dir|
    directory dir do
      recursive true
      owner app[:username]
      group app[:group] || app[:username]
      mode 0770
      action [:create]
    end
  end

  # Setup application public folders
  [
    "#{app_path}/shared/public",
    "#{app_path}/shared/public/assets",
  ].each do |dir|
    directory dir do
      recursive true
      owner app[:username]
      group app[:group] || app[:username]
      mode 0775
      action [:create]
    end
  end

  template "#{app_path}/shared/config/env_vars.rb" do
    path "#{app_path}/shared/config/env_vars.rb"
    source "env_vars.rb.erb"
    owner app[:username]
    group app[:group] || app[:username]
    mode 0660
    action :create
    not_if { File.exists?("#{app_path}/shared/config/env_vars.rb") }
  end

  template "#{node[:nginx][:conf_dir]}/sites-available/#{app[:name]}" do
    source "rails_app.conf.erb"
    owner "root"
    group "root"
    mode 0644
    variables(
      :app_path => app_path,
      :server_name => app[:server],
      :server_aliases => app[:aliases] || []
    )
    if File.exists?("#{node[:nginx][:conf_dir]}/sites-enabled/#{app[:name]}")
      notifies :reload, resources(:service => "nginx"), :delayed
    end
  end

  if app[:monit] && app[:monit][:delayed_job]
    template "/etc/monit/conf.d/delayed_job.#{app[:name]}.monitrc" do
      owner "root"
      group "root"
      mode 0644
      source "delayed_job.monitrc.erb"
      variables(
        :app_path => app_path,
        :app_user => app[:username],
        :rails_env => app[:rails_env]
      )
      notifies :run, resources(:execute => "restart-monit")
      action :create
    end
  end

  # database connection info
  connection_info = {
    :host => "127.0.0.1", 
    :port => 5432, 
    :username => 'postgres', 
    :password => node['postgresql']['password']['postgres']
  }
  app[:databases].each do |database|
    # Setup DB Users
    # Note: This needs to be completed before creating the databases so 
    # the DB owner users exists
    database[:users].each do |db_user|
      postgresql_database_user  db_user[:name] do
        connection connection_info
        password db_user[:password] # TODO: use encrypted databags
        action [:create]
      end
    end
    # Setup Databases
    postgresql_database database[:name] do
      connection connection_info
      database_name database[:name]
      template "template1"
      encoding "UTF8"
      owner database[:owner]
      action :create
    end
    # Grant permissions to the BD users
    database[:users].each do |db_user|
      postgresql_database_user db_user[:name] do
        connection connection_info
        database_name database[:name]
        privileges db_user[:privileges].to_a || "ALL"
        action [:grant]
      end
    end
  end

  nginx_site app[:name]
end