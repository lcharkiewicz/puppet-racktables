# RackTables module for Puppet

Puppet module to manage RackTables installation. This module clones git repository to demanded location, inits database (or leaves it for manual initialization via web) and provides simple vhost for apache (httpd) (and nginx in future). Module installs necessary PHP dependencies.  

## Usage
Get RackTables from git repo and use apache vhost and continue installation via web:

  class { racktables:
    install_dir    => '/var/www/htdocs/racktables',
  }

Get RackTables from git repo and put variables in secret.php to init database automatically:

  class { racktables:
    install_dir    => '/var/www/htdocs/racktables',
    use_installer  => false,
    db_name        => 'racktables',
    db_host        => 'localhost',
    db_username    => 'racktables',
    db_password    => 'racktables'
  }


## Assumptions
+ module assumes you have already created MySQL database (probably via mysql module)

## Supported platforms
+ RHEL/CentOS
+ in close future - Ubuntu ;)

## TODO
+ vhost file for nginx
+ get latest version number automatically (for init db purpose)
+ tests? :)
