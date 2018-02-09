directory '/etc/ceph' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

node.default['ceph']['config'].tap do |conf|
  conf['global'].tap do |global|
    global['mon host'] = mon_addresses.sort.join(', ')
  end
end

template '/etc/ceph/ceph.conf' do
  source 'ceph.conf.erb'
  variables(
    service_config: node['ceph']['config']
  )
  mode '0644'
end
