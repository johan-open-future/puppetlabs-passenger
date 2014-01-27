# Class: passenger
#
# This class installs Passenger (mod_rails) on your system.
# http://www.modrails.com
#
# Parameters:
#   [*passenger_version*]
#     The Version of Passenger to be installed
#
#   [*passenger_ruby*]
#     The path to ruby on your system
#
#   [*gem_path*]
#     The path to rubygems on your system
#
#   [*gem_binary_path*]
#     Path to Rubygems binaries on your system
#
#   [*passenger_root*]
#     The passenger gem root directory
#
#   [*mod_passenger_location*]
#     Path to Passenger's mod_passenger.so file
#
#   [*package_provider*]
#     The package provider to use for the system. Following providers are supported:
#     gem : build from source
#     yum : Installs the package from a yum repo. (RedHat family only)
#     apt : Install the package from a debian repo. (Debian family only) NOT IMPLEMENTED YET
#
#   [*passenger_package*]
#     The name of the Passenger package
#
# Usage:
#
#  class { 'passenger':
#    passenger_version      => '3.0.9',
#    passenger_ruby         => '/usr/bin/ruby'
#    gem_path               => '/var/lib/gems/1.8/gems',
#    gem_binary_path        => '/var/lib/gems/1.8/bin',
#    passenger_root         => '/var/lib/gems/1.8/gems/passenger-3.0.9'
#    mod_passenger_location => '/var/lib/gems/1.8/gems/passenger-3.0.9/ext/apache2/mod_passenger.so',
#    passenger_provider     => 'gem',
#    passenger_package      => 'passenger',
#  }
#
#
# Requires:
#   - apache
#   - apache::dev - only for the gem provider
#
class passenger (
  $gem_binary_path        = $passenger::params::gem_binary_path,
  $gem_path               = $passenger::params::gem_path,
  $mod_passenger_location = $passenger::params::mod_passenger_location,
  $package_name           = $passenger::params::package_name,
  $package_ensure         = $passenger::params::package_ensure,
  $package_provider       = $passenger::params::package_provider,
  $passenger_package      = $passenger::params::passenger_package,
  $passenger_provider     = $passenger::params::passenger_provider,
  $passenger_root         = $passenger::params::passenger_root,
  $passenger_ruby         = $passenger::params::passenger_ruby,
  $passenger_version      = $passenger::params::passenger_version,
) inherits passenger::params {

  include '::apache'

  case $package_provider {
    'yum' : {
      case $::osfamily {
        'RedHat': {
          class { '::passenger::install':
            pass_inst_package_ensure       => 'present',
            pass_inst_package_name         => 'mod_passenger',
            pass_inst_package_provider     => $package_provider,
            pass_inst_package_dependencies => '',
          }
          include '::passenger::config'
          anchor { 'yum::passenger::begin': }
          anchor { 'yum::passenger::end': }

          Anchor[ 'yum::passenger::begin'] ->
          Class['::passenger::install'] ->
          Class['::passenger::config'] ->
          Anchor['yum::passenger::end']
        }
        default: {
          fail("Installing passenger with yum is only supported on a RedHat, you are running on ${::operatingsystem}!")
        }
      }
    }
    'apt': {
      case $::osfamily {
        'Debian': {
          class { '::passenger::install':
            pass_inst_package_ensure       => '4.0.33',
            pass_inst_package_name         => 'libapache2-mod-passenger',
            pass_inst_package_provider     => $package_provider,
            pass_inst_package_dependencies => '',
          }
          include '::passenger::config'
          anchor { 'apt::passenger::begin': }
          anchor { 'apt::passenger::end': }

          Anchor[ 'apt::passenger::begin'] ->
          Class['::passenger::install'] ->
          Class['::passenger::config'] ->
          Anchor['apt::passenger::end']
        }
        default: {
          fail("Installing passenger with apt is only supported on a Debian, you are running on ${::operatingsystem}!")
        }
      }
    }
    'gem': {
      include '::apache::dev'
      include '::passenger::install'
      include '::passenger::config'
      include '::passenger::compile'

      anchor { 'gem::passenger::begin': }
      anchor { 'gem::passenger::end': }

      #projects.puppetlabs.com - bug - #8040: Anchoring pattern
      Anchor['gem::passenger::begin'] ->
      Class['apache::dev'] ->
      Class['passenger::install'] ->
      Class['passenger::compile'] ->
      Class['passenger::config'] ->
      Anchor['gem::passenger::end']
    }
    default: {
      fail("Installing passenger with package provider ${package_provider} is not supported")
    }
  }
}
