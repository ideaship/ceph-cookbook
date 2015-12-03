# need to include sysctl recipe in addition to setting this attribute
node.default['sysctl']['params']['vm']['swappiness'] = 1
node.default['sysctl']['params']['vm']['min_free_kbytes'] = 2_097_152
