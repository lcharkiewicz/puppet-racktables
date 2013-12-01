# RackTables module for Puppet

Puppet module to manage [RackTables](http://racktables.org/) installation. This module clones [git repository](https://github.com/RackTables/racktables) to demanded location, inits database (or leaves it for manual initialization via web) and provides simple vhost for apache (httpd) and nginx. Module installs necessary PHP dependencies.  

For an automated version default credentials are:
login: admin
password: admin

## Usage
Gets RackTables from git repo, set apache vhost and continue installation via web:

    class { 'racktables':
      install_dir    => '/var/www/htdocs/racktables',
      use_installer  => true,
    }

Get RackTables from git repo, set nginx vhost (with your server_name), install all PHP dependencies, create proper secret.php and init database automatically:

    class { 'racktables':
      install_dir    => '/var/www/htdocs/racktables',
      install_deps   => 'all',
      web_server     => 'nginx',
      server_name    => 'racktables.example.com',
      db_name        => 'racktables_db',
      db_host        => 'localhost',
      db_username    => 'racktables_user',
      db_password    => 'racktables_pass',
    }


## Assumptions
+ module assumes you have already created MySQL database (probably via mysql module)

## Supported platforms
+ RHEL/CentOS
+ Ubuntu

## TODO
+ SSL option for the vhost config.
+ tests? :)
