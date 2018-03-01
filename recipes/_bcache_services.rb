# Cookbook Name:: ceph
# Recipe:: _bcache_services
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

# This recipe creates the needed systemd service configurations to properly
# start bcached osds

# install bcache-tools to allow using bcache
package 'bcache-tools'

# create systemd dropin to run ceph-osd as root (bcache does not work without it
# for now)
directory '/etc/systemd/system/ceph-osd@.service.d'

cookbook_file '/etc/systemd/system/ceph-osd@.service.d/10-ExecStart.conf' do
  source 'ceph-osd_dropin'
end

# create systemd service to start ceph-osd via ceph-disk-activate
cookbook_file '/etc/systemd/system/ceph-disk-activate@.service' do
  source 'ceph-disk-activate'
end

# reload systemd units after adding droping and new ceph-disk-activate service
execute 'systemctl daemon-reload'
