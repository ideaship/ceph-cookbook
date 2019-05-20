name 'ceph'
maintainer 'cloudbau GmbH'
maintainer_email 'j.klare@cloudbau.de'
license 'Apache-2.0'
description 'Installs/Configures the Ceph distributed filesystem'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
issues_url 'https://github.com/cloudbau/ceph-cookbook/issues'
source_url 'https://github.com/cloudbau/ceph-cookbook'
chef_version '>= 12.5' if respond_to?(:chef_version)
version '3.3.0'

supports 'ubuntu'

depends 'chef-vault'
depends 'openstack-common'

gem 'netaddr', '~> 1.5.1'
