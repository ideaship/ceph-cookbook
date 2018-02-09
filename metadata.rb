name 'ceph'
maintainer 'Jan Klare'
maintainer_email 'j.klare@cloudbau.de'
license 'Apache 2.0'
description 'Installs/Configures the Ceph distributed filesystem'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '3.0.0'

depends 'apt'
depends 'chef-vault'
depends 'openstack-common'

gem 'netaddr', '~> 1.5.1'

source_url 'https://github.com/cloudbau/ceph-cookbook' if respond_to?(:source_url)
issues_url 'https://github.com/cloudbau/ceph-cookbook/issues' if respond_to?(:issues_url)
