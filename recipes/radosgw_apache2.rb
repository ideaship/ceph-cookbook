#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Cookbook Name:: ceph
# Recipe:: radosgw_apache2
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

include_recipe 'ceph'
include_recipe 'ceph::radosgw_apache2_repo'
#node.normal['apache']['listen'] = [node['ceph']['radosgw']['rgw_addr']]

node['ceph']['radosgw']['apache2']['packages'].each do |pck|
  package pck
end

include_recipe 'apache2'

%w(proxy proxy_balancer proxy_fcgi rewrite slotmem_shm).each do |modname|
  apache_module modname do
    notifies :restart, 'service[apache2]'
  end
end

web_app 'rgw' do
  template 'rgw.conf.erb'
  server_name node['ceph']['radosgw']['api_fqdn']
  admin_email node['ceph']['radosgw']['admin_email']
  ceph_rgw_addr node['ceph']['radosgw']['rgw_addr']
  notifies :restart, 'service[apache2]'
end

directory node['ceph']['radosgw']['path'] do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

template "#{node['ceph']['radosgw']['path']}/s3gw.fcgi" do
  source 's3gw.fcgi.erb'
  owner 'root'
  group 'root'
  mode '0755'
  variables(
    ceph_rgw_client: "client.radosgw.#{node['hostname']}"
  )
end
