include_recipe "ruby-shadow"

if node[:users]
  node[:users].keys.each do |username|
    config = node[:users][username]
    user username do
      comment config[:comment]
      home "/home/#{username}"
      shell "/bin/bash"
      password config[:password]
      if !config[:manage_home] || config[:manage_home] == true
        supports :manage_home => true
      end
      system config[:system] || nil
      action [:create, :manage]
    end 
    if config[:groups]
      config[:groups].each do |groupname|
        group groupname do
          members [username]
          append true
          action [:create, :manage]
        end
      end
    end
    if config[:generate_ssh_keys]
      generate_ssh_keys username do
        user_account username
      end
    end
    
    if !config[:add_keys] || config[:add_keys] == true
      add_keys username
    end
  end
end
