#
# Cookbook Name:: ceph
# Attributes:: radosgw
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
#

default['ceph']['radosgw']['clientname'] = 'standalone'
default['ceph']['radosgw']['zone'] = '' # type of String and needs a '.' in front
default['ceph']['radosgw']['api_fqdn'] = 'localhost'
default['ceph']['radosgw']['admin_email'] = 'admin@example.com'
default['ceph']['radosgw']['bind_interface'] = nil
default['ceph']['radosgw']['civetweb']['ssl_certificate'] = false
default['ceph']['radosgw']['packages'] = ['radosgw']
default['ceph']['radosgw']['http_port'] = 80
default['ceph']['radosgw']['https_port'] = 443
