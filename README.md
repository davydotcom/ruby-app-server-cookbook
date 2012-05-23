Ruby App Server Cookbook
========================

Description
-----------

This cookbook will take a Linux server slug (fresh installation or a prebuilt image on an AWS EC2 or a Rackspace cloud server) to an app server ready for the first application code deployment.

Services/Packages installed:

  * Chef Solo
  * Users
  * SSH w/ SSH Keys only access (root is disabled)
  * Sudoers
  * RVM (and your Rubies)
  * Postgresql
  * Nginx
  * Postfix
  * Git
  * Node.js
  * Memcached
  * Postfix
  * Monit

Application Stack:

  * RVM
  * Deploy using Git + post-recive hooks
  * Nginx + Unicorn Web Stack
  * Postgresql Datbase
  * Delayed Job for background processing (managed with Monit)
  * Postfix for mail delivery (i.e. https://github.com/smartinez87/exception_notification)

Configuration
-------------

Customize your configurations in the following files:

  * nodes/nodename.json (created when the `knife prepare` command is run) 
  * roles/base.json
  * roles/database.json
  * roles/web.json

Usage
-----

1. Setup a Linux (preferably Ubuntu >= 11.10)
1. [remote] Setup SSH Access, add your SSH key to the @authorized_keys@ file for root:
    
          ssh root@x.x.x.x
          mkdir ~/.ssh
          vi ~/.ssh/authorized_keys
          ... paste your ssh key ...

1. [local] Install the @knife-solo@ gem:
    
          gem install knife-solo

1. [local] Generate a knife configuration file (mainly so knife doesn't yell at you):
    
          knife configure -r . --defaults

1. Prep a recipe repo

    [local] Start:
        
          knife kitchen recipe-repo-directory
          cd recipe-repo-directory
          git init
          git add .
          git commit -m "Initial commit"
          git remote add origin ssh://git@bitbucket.org/user/repo.git
          git push origin master

    -- OR --

    [local] Clone the rails-app-server-cookbook repo:
    
          git clone git@github.com:ddeyoung/ruby-app-server-cookbook.git

1. [local] Prepare the server:

          knife prepare root@x.x.x.x

1. [local] Run the cook command for the first time:
    
          knife cook root@x.x.x.x

1. Future cook commands should use the sysadmin user:

      knife cook sysadmin@x.x.x.x
