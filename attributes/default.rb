default['ceph']['install_debug'] = false

default['ceph']['install_repo'] = false

default['ceph']['user_pools'] = []

case node['platform']
when 'ubuntu'
  default['ceph']['init_style'] = if node['platform_version'].to_f >= 15.04
                                    'systemd'
                                  else
                                    'upstart'
                                  end
else
  default['ceph']['init_style'] = 'sysvinit'
end

case node['platform_family']
when 'debian'
  packages = ['ceph-common']
  packages += debug_packages(packages) if node['ceph']['install_debug']
  default['ceph']['packages'] = packages
when 'rhel', 'fedora'
  packages = ['ceph']
  packages += debug_packages(packages) if node['ceph']['install_debug']
  default['ceph']['packages'] = packages
else
  default['ceph']['packages'] = []
end
