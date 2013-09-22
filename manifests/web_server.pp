#
class racktables::web_server (
  $web_server = 'apache',
  $install_deps = 'minimal',
) {

  case $::osfamily {
    'RedHat': {
      $apache_package_name = 'httpd'
      $apache_service_name = 'httpd'
      $apache_vhost_conf = '/etc/httpd/conf.d/racktables.conf'
      $apache_vhost_template = 'racktables/apache.vhost.conf.erb'
      $nginx_package_name = 'nginx'
      $nginx_service_name = 'nginx'
      $nginx_vhost_template = 'racktables/nginx.vhost.conf.erb'
      $nginx_vhost_conf = '/etc/nginx/conf.d/racktables.conf'
      $minimal_deps = ['php', 'php-pdo', 'php-mysql', 'php-mbstring', 'php-gd', 'php-bcmath']
      $all_deps = ['php', 'php-pdo', 'php-mysql', 'php-mbstring', 'php-gd',  'php-bcmath', 'php-snmp', 'php-ldap', 'php-pear-Image-GraphViz']
      $php_fpm = 'php-fpm'
    }
    'Debian': {
      $apache_package_name  = ['apache2', 'libapache2-mod-php5']
      $apache_service_name  = 'apache2'
      $apache_vhost_template = 'racktables/apache.vhost.conf.erb'
      $apache_vhost_conf    = '/etc/apache2/sites-available/racktables'
      $apache_vhost_enabled = '/etc/apache2/sites-enabled/racktables'
      $nginx_package_name  = 'nginx'
      $nginx_service_name  = 'nginx'
      $nginx_vhost_template = 'racktables/nginx.vhost.conf.erb'
      $nginx_vhost_conf    = '/etc/nginx/sites-available/racktables'
      $nginx_vhost_enabled = '/etc/nginx/sites-enabled/racktables'
      $minimal_deps = ['php5', 'php5-mysql', 'php5-gd']
      $all_deps = ['php5', 'php5-mysql', 'php5-gd', 'php5-snmp', 'php5-ldap', 'php5-curl', 'php-pear']
      $php_fpm  = 'php5-fpm'
    }
    default: {
      fail("${::operatingsystem} is not supported.")
    }
  }

  case $web_server {
    'apache',default: {
      $package_name = $apache_package_name
      $service_name = $apache_service_name
      $vhost_template = $apache_vhost_template
      $vhost_conf = $apache_vhost_conf
      if $::osfamily == 'Debian' {
        $vhost_enabled = $apache_vhost_enabled
      }
    }
    'nginx': {
      $package_name = $nginx_package_name
      $service_name = $nginx_service_name
      $vhost_template = $nginx_vhost_template
      $vhost_conf = $nginx_vhost_conf
      package {$php_fpm:
        ensure  => installed,
        require => Package[$package_name],
      } ->
      service {$php_fpm:
        ensure  => running,
        enable  => true,
      }
      if $::osfamily == 'Debian' {
        $vhost_enabled = $nginx_vhost_enabled
      }
    }
  }

  case $install_deps {
    'minimal',default: {
      package {$minimal_deps:
        ensure => present,
        before => Package[$package_name],
      }
    }
    'all': {
      package {$all_deps:
        ensure => present,
        before => Package[$package_name],
      }
      if $::osfamily == 'Debian' {
        exec {'/usr/bin/pear install Image_GraphViz':
          unless  => '/usr/bin/pear list | grep Image_GraphViz',
          require => Package[$all_deps],
        }
      }
    }
    'none': { }
  }


  package {$package_name:
    ensure => present,
  } ->

  service {$service_name:
    ensure => running,
    enable => true,
  } ~>

  file {$vhost_conf:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template($vhost_template),
    # TODO - restart php5-fpm after installing PHP dependecies
    notify  => Exec["/etc/init.d/${service_name} restart", "/etc/init.d/${php-fpm} restart"],
    before  => Exec["/etc/init.d/${service_name} restart"],
    require => Package[$package_name],
  }

  if $::osfamily == 'Debian' {
    exec {'disable 000-default apache site':
      command => '/bin/rm -f /etc/apache2/sites-enabled/000-default',
      onlyif  => '/usr/bin/test -L /etc/apache2/sites-enabled/000-default',
      require => File[$vhost_conf],
    } ->
    exec {'enable racktables site':
      command => "/bin/ln -s ${vhost_conf} ${vhost_enabled}",
      unless  => "/usr/bin/test -L ${vhost_enabled}",
      require => File[$vhost_conf],
    } ->
    exec {"/etc/init.d/${service_name} restart":
      refreshonly  => true,
    } ->
    exec {"/etc/init.d/${php_fpm} restart":
      refreshonly  => true,
    }
  }
  else {
    exec {"/etc/init.d/${service_name} restart":
      refreshonly  => true,
    }
  }

}
