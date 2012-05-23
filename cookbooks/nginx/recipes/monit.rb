template "/etc/monit/conf.d/nginx.monitrc" do
  owner "root"
  group "root"
  mode 0644
  source "nginx.monitrc.erb"
  notifies :run, resources(:execute => "restart-monit")
  action :create
end
