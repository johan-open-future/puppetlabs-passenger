# Class: passenger::params
#
# This class manages parameters for the Passenger module
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class passenger::params {
  $package_ensure     = '4.0.33'
  $passenger_version  = '4.0.33'
  $passenger_ruby     = '/usr/bin/ruby'
  $package_provider   = 'gem'
  $passenger_provider = 'gem'  # Is this needed ?   not used in the manifests

  if versioncmp ($passenger_version, '4.0.0') > 0 {
    $builddir     = 'buildout'
  } else {
    $builddir     = 'ext'
  }

  # these are settings used in the passenger.conf - this should go into hiera

  $config_PassengerHighPerformance = 'on'
  $config_PassengerMaxPoolSize = inline_template("<%= ( processorcount.to_i * 1.5 ).floor -%>")
  $config_PassengerPoolIdleTime = '1500'
  $config_PassengerMaxRequests = '1000'
  $config_PassengerStatThrottleRate = '120'

  case $::osfamily {
    'debian': {
      if $::lsbdistcodename > '7' {
        $ruby_lib_dir = '/usr/lib/ruby/gems/1.9.1/'
      } else {
        $ruby_lib_dir = '/usr/lib/ruby/gems/1.8'
      }
      $package_name           = 'passenger'
      $passenger_package      = 'passenger'
      $gem_path               = "${ruby_lib_dir}/gems"
      $gem_binary_path        = "${ruby_lib_dir}/bin"
      $passenger_root         = "${ruby_lib_dir}/gems/passenger-${passenger_version}"
      $mod_passenger_location = "${ruby_lib_dir}/gems/passenger-${passenger_version}/${builddir}/apache2/mod_passenger.so"

      # Ubuntu does not have libopenssl-ruby - it's packaged in libruby
      if $::lsbdistid == 'Debian' and $::lsbmajdistrelease <= 5 {
        $package_dependencies   = [ 'libopenssl-ruby', 'libcurl4-openssl-dev', 'build-essential', 'zlib1g-dev' ]
      } else {
        $package_dependencies   = [ 'libruby', 'libcurl4-openssl-dev', 'build-essential', 'zlib1g-dev' ]
      }
    }
    'redhat': {
      # dependencies are needed when starting from the 'minimal' OS install
      $package_dependencies   = [ 'ruby-devel', 'libcurl-devel', 'openssl-devel', 'zlib-devel', 'gcc', 'gcc-c++']
      $package_name           = 'passenger'
      $passenger_package      = 'passenger'
      $gem_path               = '/usr/lib/ruby/gems/1.8/gems'
      $gem_binary_path        = '/usr/lib/ruby/gems/1.8/gems/bin'
      $passenger_root         = "/usr/lib/ruby/gems/1.8/gems/passenger-${passenger_version}"
      $mod_passenger_location = "/usr/lib/ruby/gems/1.8/gems/passenger-${passenger_version}/${builddir}/apache2/mod_passenger.so"
    }
    'darwin':{
      $package_name           = 'passenger'
      $passenger_package      = 'passenger'
      $gem_path               = '/System/Library/Frameworks/Ruby.framework/Versions/Current/usr/bin'
      $gem_binary_path        = '/System/Library/Frameworks/Ruby.framework/Versions/Current/usr/bin'
      $passenger_root         = "/System/Library/Frameworks/Ruby.framework/Versions/Current/usr/bin/passenger-${passenger_version}"
      $mod_passenger_location = "/System/Library/Frameworks/Ruby.framework/Versions/Current/usr/bin/passenger-${passenger_version}/i${builddir}/apache2/mod_passenger.so"
    }
    default: {
      fail("Operating system ${::operatingsystem} is not supported with the Passenger module")
    }
  }
}
