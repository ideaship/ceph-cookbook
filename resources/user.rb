actions :create
default_action :create

attribute :name, :kind_of => String, :name_attribute => true
attribute :caps, :kind_of => Hash, :default => { 'mon' => 'allow r' }

# what the key should be called in the ceph cluster
# defaults to client.#{name}
attribute :keyname, :kind_of => String

# The actual key
attribute :key, :kind_of => String, :default => nil

attr_accessor :exists, :caps_match, :keys_match
