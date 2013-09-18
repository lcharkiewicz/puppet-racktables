#
class racktables::apache (
  $include_apache_vhost
) {

  case $::osfamily {
    'RedHat': {
      $package_name = 'httpd'
      $service_name = 'httpd'
      $vhost_conf = '/etc/httpd/conf.d/racktables.conf'

    }
    'Debian': {
      $package_name = 'apache2'
      $service_name = 'apache2'
      $vhost_conf = '/etc/apache2/sites-available/racktables'
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

  if $include_apache_vhost != false {
    file {$vhost_conf:
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('racktables/apache.vhost.conf.erb'),
      require => Package[$package_name],
    }
  }
}
