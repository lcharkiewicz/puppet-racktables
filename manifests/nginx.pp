#
class racktables::nginx (
  $include_nginx_vhost
) {

  case $::osfamily {
    'RedHat': {
      $package_name = 'nginx'
      $service_name = 'nginx'
      $vhost_conf = '/etc/nginx/conf.d/racktables.conf'

    }
    'Debian': {
      $package_name = 'nginx'
      $service_name = 'nginx'
      $vhost_conf = '/etc/nginx/sites-available/racktables'
    }
    default: {
      fail('Your OS family is not supported yet.')
    }
  }

  package {$package_name:
    ensure => present,
  } ->

  service {$service_name:
    ensure => running,
    enable => true,
  }

  if $include_nginx_vhost != false {
    file {$vhost_conf:
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('racktables/nginx.vhost.conf.erb'),
      require => Package[$package_name],
    }
  }
}
