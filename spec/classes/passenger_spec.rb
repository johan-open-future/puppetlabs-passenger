require 'spec_helper'

describe 'passenger' do
  let(:facts) do
    { :concat_basedir => '/dne',
      :processorcount => '2' }  # needed for the template
  end

  let(:params) do
    {
      :passenger_version      => '3.0.19',
      :passenger_ruby         => '/opt/bin/ruby',
      :gem_path               => '/opt/lib/ruby/gems/1.9.1/gems',
      :gem_binary_path        => '/opt/lib/ruby/bin',
      :passenger_root         => '/opt/lib/ruby/gems/1.9.1/gems/passenger-3.0.19',
      :mod_passenger_location => '/opt/lib/ruby/gems/1.9.1/gems/passenger-3.0.19/ext/apache2/mod_passenger.so'
    }
  end

  describe 'on RedHat' do
    let(:facts) do
      { :osfamily => 'redhat', :operatingsystemrelease => '6.4', :concat_basedir => '/dne', :processorcount => '2' }
    end

    it 'adds libcurl-devel for compilation' do
      should contain_package('libcurl-devel')
    end

    it 'adds httpd config' do
      should contain_file('/etc/httpd/conf.d/passenger.conf').with_content(/PassengerRuby \/opt\/bin\/ruby/)
      should contain_file('/etc/httpd/conf.d/passenger.conf').with_content(/LoadModule passenger_module \/opt\/lib\/ruby\/gems\/1.9.1\/gems\/passenger-3.0.19\/ext\/apache2\/mod_passenger.so/)
      should contain_file('/etc/httpd/conf.d/passenger.conf').with_content(/PassengerRoot \/opt\/lib\/ruby\/gems\/1.9.1\/gems\/passenger-3.0.19/)
    end
  end

  describe 'on Debian' do
    let(:facts) do
      { :osfamily => 'debian', :operatingsystemrelease => '7', :concat_basedir => '/dne', :processorcount => '2' }
    end

    it 'adds mods-available files' do
      should contain_file('/etc/apache2/mods-available/passenger.conf')
      should contain_file('/etc/apache2/mods-available/passenger.load')
    end

    it 'adds symlinks mods-enabled to load modules' do
      should contain_file('/etc/apache2/mods-enabled/passenger.conf').with(
        :ensure => 'link',
        :target => '/etc/apache2/mods-available/passenger.conf'
      )

      should contain_file('/etc/apache2/mods-enabled/passenger.load').with(
        :ensure => 'link',
        :target => '/etc/apache2/mods-available/passenger.load'
      )
    end
  end

  ['redhat', 'debian'].each do |osfamily|
    let(:facts) do
      { :osfamily => osfamily, :operatingsystemrelease => 'thing', :concat_basedir => '/dne', :processorcount => '2' }
    end

    context "on #{osfamily} with customized params" do
      it 'compiles the apache module' do
        should contain_exec('compile-passenger').with(
          :path => ['/opt/lib/ruby/bin', '/usr/bin', '/bin', '/usr/local/bin'],
          :creates => '/opt/lib/ruby/gems/1.9.1/gems/passenger-3.0.19/ext/apache2/mod_passenger.so'
        )
      end

      it 'adds passenger package' do
        should contain_package('passenger').with(
          :name => 'passenger',
          :provider => 'gem'
        )
      end

      it 'includes apache' do
        should contain_class('apache')
      end
    end
  end

  describe 'on RedHat using yum provider' do
    let(:facts) do
      { :osfamily => 'RedHat', :operatingsystemrelease => 'thing', :concat_basedir => '/dne', :processorcount => '2' }
    end
    let(:params) do
      { :package_provider       => 'yum', }
    end
    it "installs the passenger package" do
      should contain_package('passenger').with(
        :name => 'mod_passenger',
        :provider => 'yum',
      )
    end

    it 'does not compile the package' do
      should_not contain_exec('compile-passenger')
      should_not contain_class('apache-dev')
    end
  end

  describe 'raise errors on unsupported providers and hardware' do
    context "yum on debian" do
      let(:facts) do
        { :osfamily => 'Debian', :operatingsystemrelease => 'thing', :concat_basedir => '/dne', :processorcount => '2' }
      end
      let(:params) do
        { :package_provider => 'yum', }
      end
      it 'should raise an error' do
        expect { should compile }.to raise_error(Puppet::Error,/Installing passenger with yum is only supported on a RedHat/)
      end
    end
    context "yum on RedHat" do
      let(:facts) do
        { :osfamily => 'RedHat', :operatingsystemrelease => 'thing', :concat_basedir => '/dne', :processorcount => '2' }
      end
      let(:params) do
        { :package_provider => 'apt', }
      end
      it do
        expect { should compile}.to raise_error(Puppet::Error,/Installing passenger with apt is only supported on a Debian/)
      end
    end
  end


end
