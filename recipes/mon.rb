# This recipe creates a monitor cluster
#
# You should never change the mon default path or
# the keyring path.
# Don't change the cluster name either
# Default path for mon data: /var/lib/ceph/mon/$cluster-$id/
#   which will be /var/lib/ceph/mon/ceph-`hostname`/
# The keyring files are created using the following pattern:
#  /etc/ceph/$cluster.client.$name.keyring
#  e.g. /etc/ceph/ceph.client.admin.keyring
#  The bootstrap-osd and bootstrap-mds keyring are a bit
#  different and are created in
#  /var/lib/ceph/bootstrap-{osd,mds}/ceph.keyring

node.default['ceph']['is_mon'] = true

include_recipe 'ceph'
include_recipe 'ceph::mon_install'

service_type = node['ceph']['mon']['init_style']

# Note(JR): This requires Infernalis or higher
ceph_user = 'ceph'
ceph_group = 'ceph'

directory "/var/lib/ceph/mon/ceph-#{node['hostname']}" do
  owner ceph_user
  group ceph_group
  mode 00755
  recursive true
  action :create
end

# TODO: cluster name
cluster = 'ceph'

keyring = "/tmp/#{cluster}-#{node['hostname']}.mon.keyring"

execute 'format mon-secret as keyring' do # ~FC009
  command lazy { "ceph-authtool '#{keyring}' --create-keyring --name=mon. --add-key='#{mon_secret}' --cap mon 'allow *'" }
  user ceph_user
  group ceph_group
  creates keyring
  sensitive true if Chef::Resource::Execute.method_defined? :sensitive
end

execute 'add bootstrap-osd key to keyring' do
  command lazy { "ceph-authtool '#{keyring}' --name=client.bootstrap-osd --add-key='#{osd_secret}' --cap mon 'allow profile bootstrap-osd'  --cap osd 'allow profile bootstrap-osd'" }
  user ceph_user
  group ceph_group
  sensitive true if Chef::Resource::Execute.method_defined? :sensitive
end

execute 'ceph-mon mkfs' do
  command "ceph-mon --mkfs -i #{node['hostname']} --keyring '#{keyring}'"
  user ceph_user
  group ceph_group
end

ruby_block 'finalise' do
  block do
    ['done', service_type].each do |ack|
      ::File.open("/var/lib/ceph/mon/ceph-#{node['hostname']}/#{ack}", 'w').close
    end
  end
end

if service_type == 'upstart'
  service 'ceph-mon' do
    provider Chef::Provider::Service::Upstart
    action :enable
  end
  service 'ceph-mon-all' do
    provider Chef::Provider::Service::Upstart
    supports :status => true
    action [:enable, :start]
  end
end

service 'ceph_mon' do
  case service_type
  when 'upstart'
    service_name 'ceph-mon-all-starter'
    provider Chef::Provider::Service::Upstart
  when 'systemd'
    service_name 'ceph-mon'
  else
    service_name 'ceph'
  end
  supports :restart => true, :status => true
  action [:enable, :start]
end

# Todo(JR): Check whether we want to do this every time or only during bootstrap
mon_addresses.each do |addr|
  execute "peer #{addr}" do
    command "ceph --admin-daemon '/var/run/ceph/ceph-mon.#{node['hostname']}.asok' add_bootstrap_peer_hint #{addr}"
    ignore_failure true
  end
end
