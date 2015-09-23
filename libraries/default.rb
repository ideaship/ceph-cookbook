require 'json'
require 'chef-vault'

def mon_env_search_string
  # search for any mon nodes
  search_string = 'ceph_is_mon:true'
  if node['ceph']['search_environment'].is_a?(String)
    # search for nodes with this particular env
    search_string += " AND chef_environment:#{node['ceph']['search_environment']}"
  elsif node['ceph']['search_environment']
    # search for any nodes with this environment
    search_string += " AND chef_environment:#{node.chef_environment}"
  end
  search_string
end

def mon_nodes
  search_string = mon_env_search_string

  search(:node, search_string)
end

# If public_network is specified with one or more networks, we need to
# search for a matching monitor IP in the node environment.
# 1. For each public network specified:
#    a. We look if the network is IPv6 or IPv4
#    b. We look for a route matching the network
#    c. If we found match, we return the IP with the port
def find_node_ip_in_network(network, nodeish = nil)
  require 'netaddr'
  nodeish = node unless nodeish
  network.split(/\s*,\s*/).each do |n|
    net = NetAddr::CIDR.create(n)
    nodeish['network']['interfaces'].each do |_iface, addrs|
      addresses = addrs['addresses'] || []
      addresses.each do |ip, params|
        return ip_address_to_ceph_address(ip, params) if ip_address_in_network?(ip, params, net)
      end
    end
  end
  nil
end

def ip_address_in_network?(ip, params, net)
  # Find the IP on this interface that matches the public_network
  # Uses a few heuristics to find the primary IP that ceph would bind to
  # Most secondary IPs never have a broadcast value set
  # Other secondary IPs have a prefix of /32
  # Match the prefix that we want from the public_network prefix
  if params['family'] == 'inet' && net.version == 4
    ip4_address_in_network?(ip, params, net)
  elsif params['family'] == 'inet6' && net.version == 6
    ip6_address_in_network?(ip, params, net)
  else
    false
  end
end

def ip4_address_in_network?(ip, params, net)
  net.contains?(ip) && params.key?('broadcast') && params['prefixlen'].to_i == net.bits
end

def ip6_address_in_network?(ip, params, net)
  net.contains?(ip) && params['prefixlen'].to_i == net.bits
end

def ip_address_to_ceph_address(ip, params)
  if params['family'].eql?('inet')
    return "#{ip}:6789"
  elsif params['family'].eql?('inet6')
    return "[#{ip}]:6789"
  end
end

def mon_addresses
  mon_ips = []

  if File.exist?("/var/run/ceph/ceph-mon.#{node['hostname']}.asok")
    mon_ips = quorum_members_ips
  else
    mons = []
    # make sure if this node runs ceph-mon, it's always included even if
    # search is laggy; put it first in the hopes that clients will talk
    # primarily to local node
    mons << node if node['ceph']['is_mon']

    mons += mon_nodes
    if node['ceph']['config']['global'] && node['ceph']['config']['global']['public network']
      mon_ips = mons.map { |nodeish| find_node_ip_in_network(node['ceph']['config']['global']['public network'], nodeish) }
    else
      mon_ips = mons.map { |node| node['ipaddress'] + ':6789' }
    end
  end
  mon_ips.reject(&:nil?).uniq
end

def ceph_secret(name)
  client = "ceph_#{name}"
  ChefVault::Item.load('vault_ceph_secrets', client)[client]
end

def mon_secret
  ceph_secret 'mon'
end

def osd_secret
  ceph_secret 'bootstrap_osd'
end

def quorum_members_ips
  mon_ips = []
  cmd = Mixlib::ShellOut.new("ceph --admin-daemon /var/run/ceph/ceph-mon.#{node['hostname']}.asok mon_status")
  cmd.run_command
  cmd.error!

  mons = JSON.parse(cmd.stdout)['monmap']['mons']
  mons.each do |k|
    # Note(JR): This may fail once ceph defines address types other than 0, might be better to explicitly filter for ".../0"
    # Also need to check whether this works with inet6.
    mon_ips.push(k['addr'][0..-3])
  end
  mon_ips
end
