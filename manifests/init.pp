# == Class: racktables
#
# Simple module to manage RackTables (http://racktables.org) installation.
# Module clones git repo and put files in a selected place.
# After that you have to finish installation via web browser or you can init
# an empty database (it is fully automated but it is not a default option!).
# Module installs necessary PHP dependencies.
# Module assumes you have already created MySQL database.
# Module provides simple vhost config file as well.
#
# For an automated version credentials are:
# login: admin
# password: admin
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
#   Default: false.
#
# [*install_deps*]
#   Installs PHP dependencies. You can choose between 'all', 'minimal' or 'none'.
#
# [*web_server*]
#   Installs chosen web server and provides propoer vhost config.
#   Default: apache (httpd)
#
# [*server_name*]
#   ServerName for vhost purposes.
#
# [*server_aliases*]
#   ServerAlias for vhost purposes.
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
# [*git_repo_url*]
#   URL for RackTables git repository.
#
# === Examples
#
#  Get RackTables from git repo, set apache vhost
#  and continue installation via web:
#
#  class { 'racktables':
#    install_dir   => '/var/www/htdocs/racktables',
#    use_installer => true,
#  }
#
#  Get RackTables from git repo, set nginx vhost (with server_name),
#  install all PHP dependencies, create proper secret.php to init database automatically:
#
#  class { 'racktables':
#    install_dir  => '/var/www/htdocs/racktables',
#    install_deps => 'all',
#    web_server   => 'nginx',
#    server_name  => 'racktables.example.com',
#    db_name      => 'racktables',
#    db_host      => 'localhost',
#    db_username  => 'racktables',
#    db_password  => 'racktables',
#  }
#
# === Authors
#
# Leszek Charkiewicz <leszek@charkiewicz.net>
#
class racktables (
  $install_dir,
  $use_installer = false,
  $install_deps = 'min',
  $web_server = 'apache',
  $server_name = $::fqdn,
  $server_aliases = undef,
  $db_name = 'racktables',
  $db_host = 'localhost',
  $db_username = 'racktables',
  $db_password = 'racktables',
  $git_repo_url = 'https://github.com/RackTables/racktables.git',
) {

  class {'racktables::web_server':
    web_server   => $web_server,
    install_deps => $install_deps,
  } ->

  exec {'create install dir':
    command => "/bin/mkdir -p ${install_dir}",
    unless  => "/usr/bin/test -d ${install_dir}",
  } ->

  package {'git':
    ensure => present,
  } ->

  exec {'clone git repo':
    cwd     => $install_dir,
    command => "/usr/bin/git clone ${git_repo_url} .",
    unless  => "/usr/bin/test -d ${install_dir}/.git",
  }


  if $use_installer == false {
    exec {'clean after failed installation':
      command => '/bin/rm -rf /tmp/racktables-contribs',
      unless  => '/usr/bin/test ! -d /tmp/racktables-contribs',
    } ->

    exec {'clone racktables contrib repo':
      command => '/usr/bin/git clone https://github.com/RackTables/racktables-contribs /tmp/racktables-contribs',
      unless  => "/usr/bin/test -f ${install_dir}/wwwroot/inc/secret.php",
    } ->

    exec {'initialize database':
      cwd     => '/tmp/racktables-contribs/demo.racktables.org',
      command => "/usr/bin/mysql -h ${db_host} -u ${db_username} -p${db_password} ${db_name} < $(ls -1 | grep '.sql' | sort -n | tail -1)",
      unless  => "/usr/bin/mysql -h ${db_host} -u ${db_username} -p${db_password} ${db_name} -e 'DESCRIBE VSIPs'",
    } ->

    file {"${install_dir}/wwwroot/inc/secret.php":
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0666',
      content => template('racktables/secret.php.erb'),
      require => Exec['clone git repo'],
    } ->

    exec {'clean after db init procedure':
      command => '/bin/rm -rf /tmp/racktables-contribs',
      unless  => '/usr/bin/test ! -d /tmp/racktables-contribs',
    }
  }

}
