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
rgw_clientname = node['ceph']['radosgw']['clientname']
bind_iface = node['ceph']['radosgw']['bind_interface']
address = address_for(bind_iface) if bind_iface
http_port = node['ceph']['radosgw']['http_port']
https_port = node['ceph']['radosgw']['https_port']

rgw_frontends = 'civetweb'
if address
  if node['ceph']['radosgw']['civetweb']['ssl_certificate']
    rgw_frontends += " port=#{address}:#{http_port}+#{address}:#{https_port}s"
    rgw_frontends += " ssl_certificate=#{node['ceph']['radosgw']['civetweb']['ssl_certificate']}"
  else
    rgw_frontends += " port=#{address}:#{http_port}"
  end
else
  rgw_frontends += " port=#{http_port}"
end
if node['ceph']['radosgw']['civetweb']['num_threads']
  rgw_frontends += " num_threads=#{node['ceph']['radosgw']['civetweb']['num_threads']}"
end

node.default['ceph']['config']["client.radosgw.#{rgw_clientname}"].tap do |rgw|
  rgw['rgw socket path'] = "/var/run/ceph/radosgw.#{rgw_clientname}"
  rgw['admin socket'] = "/var/run/ceph/ceph-client.radosgw.#{rgw_clientname}.asok"
  rgw['keyring'] = "/etc/ceph/ceph.client.radosgw.#{rgw_clientname}.keyring"
  rgw['rgw region'] = region[1..-1]
  rgw['rgw region root pool'] = "#{region}.rgw.root"
  rgw['rgw zone'] = "#{region[1..-1]}#{zone}"
  rgw['rgw dns name'] = node['ceph']['radosgw']['api_fqdn']
  rgw['rgw frontends'] = rgw_frontends
  rgw['host'] = node['hostname']
  rgw['pid file'] = '/var/run/ceph/$name.pid'
  rgw['log file'] = '/var/log/ceph/radosgw.log'
  rgw['rgw gc obj min wait'] = 120
  rgw['rgw gc processor max time'] = 120
  rgw['rgw gc processor period'] = 120
  rgw['rgw override bucket index max shards'] = 8
end

include_recipe 'ceph'
node['ceph']['radosgw']['packages'].each do |pck|
  package pck
end

rgw_key =
  chef_vault_item('vault_ceph_secrets',
                  'ceph_radosgw_clientkey')['ceph_radosgw_clientkey']
rgw_caps = {
  'mon' => 'allow rw',
  'osd' => 'allow rwx',
}

ceph_user "radosgw.#{rgw_clientname}" do
  caps rgw_caps
  key rgw_key
end

ceph_client "radosgw.#{rgw_clientname}" do
  key rgw_key
  owner 'root'
  group 'root'
  mode 0640
end

ceph_client 'admin' do
  owner 'root'
  group 'root'
  mode 0640
end

service 'radosgw' do
  supports restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/ceph/ceph.conf]'
end
