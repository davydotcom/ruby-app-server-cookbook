define :generate_ssh_keys, :user_account => nil do
  username = params[:user_account]
  
  raise ":user_account should be provided." if username.nil?
  
  Chef::Log.debug("generate ssh keys for #{username}.")
  
  execute "generate ssh keys for #{username}." do
    user username
    creates "/home/#{username}/.ssh/id_rsa.pub"
    command "ssh-keygen -t rsa -q -f /home/#{username}/.ssh/id_rsa -P \"\""
  end
end