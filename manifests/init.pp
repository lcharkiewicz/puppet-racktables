# == Class: racktables
#
# Simple module to manage RackTables installation.
# Module clones git repo and put files in a selected place.
# After that you have to finish installation via web browser or you can init
# an empty database (it is fully automated then but it is not a default option!).
# Module installs necessary PHP dependencies.
# Module assumes you have already created MySQL database.
# Module provides simple vhost config file as well.
#
# === Parameters
#
# Document parameters here.
#
# [*install_dir*]
#   Location where racktables files will be extracted (mandatory).
#
# [*use_installer*]
#   Does not create secret.php and you have to use web installer.
#   If set false it inits datebase and put parameters in secret.php. 
#   With 'false' it is fully automated.
#
# [*db_name*]
#   Database name for secret.php file.
#
# [*db_host*]
#   Database host for secret.php file.
#
# [*db_username*]
#   Database user for secret.php file.
#
# [*db_password*]
#   Database password for secret.php file.

# [*server_name*]
#   ServerName for vhost purposes.
#
# [*server_aliases*]
#   ServerAlias for vhost purposes.
#
# [*git_repo_url*]
#   URL for RackTables git repository.
#
# [*install_deps*]
#   Installs PHP dependencies. You can choose between 'all', 'minimal' or 'none'.
#
# [*install_apache*]
#   Installs apache (httpd) (if not installed already) and starts it.
#
# [*include_apache_vhost*]
#   Provides apache vhost file in /etc/httpd/conf.d (RH family at the moment).
#
# [*install_nginx*]
#   Install ngninx (if not installed already) and starts it.
#
# [*include_nginx_vhost*]
#   Provides nginx vhost file in /etc/nginx/racktables.conf (TODO).
#
# === Examples
#
#  Get RackTables from git repo and use apache vhost
#   and continue installation via web:
#
#  class { racktables:
#    install_dir    => '/var/www/htdocs/racktables',
#  }
#
#  Get RackTables from git repo and put variables in secret.php
#   to init db automatically:
#
#  class { racktables:
#    install_dir    => '/var/www/htdocs/racktables',
#    use_installer  => false,
#    db_name        => 'racktables',
#    db_host        => 'localhost',
#    db_username    => 'racktables',
#    db_password    => 'racktables'
#  }
#
# === Authors
#
# Leszek Charkiewicz <leszek@charkiewicz.net>
#
class racktables (
  $install_dir,
  $use_installer = true,
  $db_name = 'racktables',
  $db_host = 'localhost',
  $db_username = 'racktables',
  $db_password = 'racktables',
  $server_name = $::fqdn,
  $server_aliases = undef,
  $git_repo_url = 'https://github.com/RackTables/racktables.git',
  $install_deps = 'min',
  $install_apache = true,
  $include_apache_vhost = true,
  $install_nginx = false, # TODO
  $include_nginx_vhost = false,
) {

  if $install_apache == true {
    if $install_nginx == true {
      fail('Apache and Nginx cannot be enabled simultaneously')
    }
  }


  if $install_apache == true {
    class {'racktables::apache':
      include_apache_vhost => $include_apache_vhost
    }
  }


  if $install_nginx == true {
    class {'racktables::nginx':
      # TODO
      include_nginx_vhost => $include_nginx_vhost
    }
  }


  exec {'create install dir':
    command => "/bin/mkdir -p ${install_dir}",
    unless  => "/usr/bin/test -d ${install_dir}"
  } ->

  package {'git':
    ensure => present,
  } ->

  exec {'clone git repo':
    cwd     => $install_dir,
    command => "/usr/bin/git clone ${git_repo_url} .",
    unless  => "/usr/bin/test -d ${install_dir}/.git",
  }


  case $install_deps {

    default,'min': {
      $php_deps = ['php-pdo', 'php-mysql', 'php-mbstring', 'php-gd', 'php-bcmath']
      package {$php_deps:
        ensure => present,
      }
    }

    'all': {
      $php_deps = ['php-pdo', 'php-mysql', 'php-mbstring', 'php-gd',  'php-bcmath', 'php-snmp', 'php-ldap', 'php-pear-Image-GraphViz']
      package {$php_deps:
        ensure => present,
      }
    }

    'none': {
      notice('Did not installed any PHP dependencies.')
    }

  }


  exec {'clone racktables contrib repo':
    command => "/usr/bin/git clone https://github.com/RackTables/racktables-contribs /tmp/racktables-contribs",
    unless  => "/usr/bin/test -f ${install_dir}/wwwroot/inc/secret.php",
  } ->

  #TODO get last init-full.sql version automatically
  exec {'initialize database':
    cwd     => '/tmp/racktables-contribs/demo.racktables.org',
    command => "/usr/bin/mysql -h ${db_host} -u ${db_username} -p${db_password} ${db_name} < init-full-0.20.5.sql",
    unless  => "/usr/bin/mysql -h ${db_host} -u ${db_username} -p${db_password} ${db_name} -e 'DESCRIBE VSIPs'",
  } ->

  file {"${install_dir}/wwwroot/inc/secret.php":
    ensure  => file,
    owner   => 'apache',
    group   => 'apache',
    mode    => '0600',
    content => template('racktables/secret.php.erb'),
    require => Exec['clone git repo'],
  } ->

  exec {'clean after db init procedure':
    command => '/bin/rm -rf /tmp/racktables-contribs',
    unless  => '/usr/bin/test ! -d /tmp/racktables-contribs',
  }

}
