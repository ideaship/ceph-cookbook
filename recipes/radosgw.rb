#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Cookbook Name:: ceph
# Recipe:: radosgw
#
# Copyright 2011, DreamHost Web Hosting
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# needed for address_for method
class ::Chef::Recipe
    include ::Openstack
end

zone = node['ceph']['radosgw']['zone']
region = node['ceph']['radosgw']['region']
node.default['ceph']['is_radosgw'] = true
node.default['ceph']['config']['rgw'] = {
  'rgw region' => region[1..-1],
  'rgw region root pool' => "#{region}.rgw.root",
  'rgw zone' => "#{region[1..-1]}#{zone}",
  'rgw zone root pool' => "#{region}#{zone}.rgw.root",
  'rgw dns name' => node['ceph']['radosgw']['api_fqdn'],
}

bind_iface = node['ceph']['radosgw']['bind_interface'] 
if bind_iface
  address = address_for bind_iface
  node.normal['ceph']['radosgw']['rgw_addr'] = "#{address}:80"
  node.normal['ceph']['radosgw']['rgw_status_acl'] = address
end

include_recipe 'ceph'
include_recipe 'ceph::radosgw_install'

directory '/var/log/radosgw' do
  owner node['apache']['user']
  group node['apache']['group']
  mode '0755'
  action :create
end

file '/var/log/radosgw/radosgw.log' do
  owner node['apache']['user']
  group node['apache']['group']
end

if node['ceph']['radosgw']['webserver_companion']
  include_recipe "ceph::radosgw_#{node['ceph']['radosgw']['webserver_companion']}"
end

rgw_clientname = node['ceph']['radosgw']['clientname']
rgw_key =
  chef_vault_item('vault_ceph_secrets',
                  "ceph_radosgw_#{rgw_clientname}")["ceph_radosgw_#{rgw_clientname}"]
rgw_caps = {
  'mon' => 'allow r',
  'osd' => 'allow rwx'
}

ceph_user "radosgw.#{rgw_clientname}" do
    caps rgw_caps
    key rgw_key
end

ceph_client "radosgw.#{rgw_clientname}" do
  key rgw_key
  owner 'root'
  group node['apache']['group']
  mode 0640
end

ceph_client 'admin' do
  owner 'root'
  group 'root'
  mode 0640
end

node['ceph']['radosgw']['pools'].each do |pool, pg_num|
  # create zone pools for region
  ceph_pool "#{region}#{zone}#{pool}" do
    pg_num pg_num
  end
  # create region root pool
  next unless pool == '.rgw.root'
  ceph_pool "#{region}#{pool}" do
    pg_num pg_num
  end
end

directory "/var/lib/ceph/radosgw/ceph-radosgw.#{rgw_clientname}" do
  recursive true
  only_if { node['platform'] == 'ubuntu' }
end

# needed by https://github.com/ceph/ceph/blob/master/src/upstart/radosgw-all-starter.conf
file "/var/lib/ceph/radosgw/ceph-radosgw.#{rgw_clientname}/done" do
  action :create
  only_if { node['platform'] == 'ubuntu' }
end

service 'radosgw' do
  case node['ceph']['radosgw']['init_style']
  when 'upstart'
    service_name 'radosgw-all'
    provider Chef::Provider::Service::Upstart
  else
    if node['platform'] == 'debian'
      service_name 'radosgw'
    else
      service_name 'ceph-radosgw'
    end
  end
  supports :restart => true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/ceph/ceph.conf]'
end
