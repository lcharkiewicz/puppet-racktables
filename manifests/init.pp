# == Class: racktables
#
# Simple module to manage RackTables installation.
# Module clones git repo or downloads tar and put files in a selected place.
# After that you have to finish installation via web browser or you can init
# demo database the same as demo.racktables.org (it is fully automated then).
# Module provides simple vhost config file as well.
# Module assumes you have already created MySQL database.
#
# === Parameters
#
# Document parameters here.
#
# [*install_dir*]
#   Location where racktables files will be extracted (mandatory).
#
# [*install_method*]
#   Choose between 'git' and 'tar'. Git is recommended (and default) option.
#
# [*use_installer*]
#   Does not create secret.php and you have to use web installer.
#   If set false it inits datebase and put parameters in secret.php. 
#   With 'false' it is fully automated.
#
# [*server_name*]
#   ServerName for vhost purposes.
#
# [*server_aliases*]
#   ServerAlias for vhost purposes.
#
# [*git_repo_url*]
#   URL for RackTables git repository.
#
# [*tar_url*]
#   URL for tar file with RackTables.
#
# [*tar_tmp_dir*]
#   Temporary directory to extract tar.
#
# [*install_deps*]
#   Installs PHP dependencies. You can choose between 'all', 'minimal' or 'none'
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
#
# === Examples
#
#  Get RackTables from git repo and use apache vhost
#   and continue installation via web:
#
#  class { racktables:
#    install_dir    => '/var/www/htdocs/racktables',
#    install_method => 'git'
#  }
#
#
#  Get RackTables from git repo and put variables in secret.php
#   to init db automaticly:
#
#  class { racktables:
#    install_dir    => '/var/www/htdocs/racktables',
#    install_method => 'git',
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
  $install_method = 'git',
  $use_installer = true,
  $server_name = $::fqdn,
  $server_aliases = undef,
  $git_repo_url = 'https://github.com/RackTables/racktables.git',
  $tar_url = 'http://sourceforge.net/projects/racktables/files/latest/download?source=files',
  $tar_tmp_dir = '/tmp/racktables',
  $install_deps = 'min',
  $install_apache = true,
  $include_apache_vhost = true,
  $install_nginx = false, # TODO
  $include_nginx_vhost = false,
  $db_name = 'racktables',
  $db_host = 'localhost',
  $db_username = 'racktables',
  $db_password = 'racktables',
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


  case $install_method {

    'git': {
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
    }

    'tar': {
      exec {'create tar tmp dir':
        command => "/bin/mkdir -p ${tar_tmp_dir}",
        unless  => "/usr/bin/test -d ${tar_tmp_dir}"
      } ->
      exec {'download tar':
        cwd     => $tar_tmp_dir,
        command => "/usr/bin/curl -L ${tar_url} -o racktables-latest.tar.gz",
        unless  => '/usr/bin/test -f racktables-latest.tar.gz',
      } ->
      exec {'extract tar':
        cwd      => $tar_tmp_dir,
        command  => '/bin/tar zxvf racktables-latest.tar.gz',
        unless   => '/usr/bin/test -d $(find . -maxdepth 1 -name "RockTables-*")',
      } ->
      exec {'create install dir':
        command => "/bin/mkdir -p ${install_dir}",
        unless  => "/usr/bin/test -d ${install_dir}"
      }
      # TODO - there's strange problem - how to move extracted data??? (in a nice way)
      #exec {'move extracted content':
      #  cwd      => $tar_tmp_dir,
      #  command  => "/bin/mv $(find . -maxdepth 1 -name 'RackTables*')/* ${install_dir}",
      #  #command => "mv $(ls -1 | grep RackTables | tr -d '\n') ${install_dir}",
      #  unless   => "/usr/bin/test -d ${install_dir}/wwwroot"
      #}
      exec {'clean tmp dir':
        command => "/bin/rm -rf ${tar_tmp_dir}",
        onlyif  => "/usr/bin/test -d ${tar_tmp_dir}",
      }
    }

    default: {
      fail('Chosen method does not exist.')
    }
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


  $which_method = $install_method ? {
    'git'   => 'clone git repo',
    'tar'   => 'move extracted content',
    default => 'clone git repo',
  }

  if $use_installer {
    file {"${install_dir}/wwwroot/inc/secret.php":
      ensure  => absent,
      require => Exec[$which_method],
    }
  }
  else {
    # for init demo db git is necessary
    if $install_method == 'tar' {
      package {'git':
        ensure => present,
      }
    }

    exec {'clone racktables contrib repo':
      command => "/usr/bin/git clone https://github.com/RackTables/racktables-contribs /tmp/racktables-contribs",
      unless  => "/usr/bin/test -f ${install_dir}/wwwroot/inc/secret.php",
    } ->

    #TODO get last init-full.sql version automaticly
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
        require => Exec[$which_method],
    } ->

    exec {'clean after db init procedure':
      command => '/bin/rm -rf /tmp/racktables-contribs',
      unless  => '/usr/bin/test ! -d /tmp/racktables-contrib',
    }

  }

}
