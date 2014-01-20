class passenger::install (
  $pass_inst_package_ensure       = $passenger::package_ensure,
  $pass_inst_package_name         = $passenger::package_name,
  $pass_inst_package_provider     = $passenger::package_provider,
  $pass_inst_package_dependencies = $passenger::package_dependencies,
)  {

  notify { "my parameters are : ${pass_inst_package_ensure} - ${pass_inst_package_name} -  ${pass_inst_package_provider} - ${pass_inst_package_dependencies}":}

  package { 'passenger':
    ensure   => $pass_inst_package_ensure,
    name     => $pass_inst_package_name,
    provider => $pass_inst_package_provider,
  }

  if $pass_inst_package_dependencies {
    package { $pass_inst_package_dependencies:
      ensure => present,
      before => Package['passenger'],
    }
  }

}
