include_recipe 'ceph'

node['ceph']['mon']['packages'].each do |pck|
  package pck
end

# This service interferes with our setting up of the admin user
# Should be wrapped for Ubuntu Vivid++ only
service 'ceph-create-keys.service' do
  action :disable
end
