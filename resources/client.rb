default_action :add

property :caps, Hash, default: { 'mon' => 'allow r', 'osd' => 'allow r' }

# Whether to store the secret in a keyring file or a plain secret file
property :as_keyring, [TrueClass, FalseClass], default: true

# what the key should be called in the ceph cluster
# defaults to client.#{name}.#{hostname}
property :keyname, String

# The actual key (the key will be read from a vault item if not provided)
property :key, String

# where the key should be saved
# defaults to /etc/ceph/ceph.client.#{name}.#{hostname}.keyring if as_keyring
# defaults to /etc/ceph/ceph.client.#{name}.#{hostname}.secret if not as_keyring
property :filename, String

# key file access creds
property :owner, String, default: 'root'
property :group, String, default: 'root'
property :mode, [Integer, String], default: '00640'

action :add do
  name = new_resource.name
  keyname = new_resource.keyname || "client.#{name}"
  as_keyring = new_resource.as_keyring
  default_filename = "/etc/ceph/ceph.#{keyname}.#{as_keyring ? 'keyring' : 'secret'}"
  filename = new_resource.filename || default_filename
  owner = new_resource.owner
  group = new_resource.group
  mode = new_resource.mode

  # Obtain the key from its vault if one wasn't provided
  key = new_resource.key || ceph_secret(name)

  # update the key in the file
  file filename do # ~FC009
    content file_content(keyname, key, as_keyring)
    owner owner
    group group
    mode mode
    sensitive true if Chef::Resource::File.method_defined? :sensitive
  end
end

def file_content(keyname, key, as_keyring)
  if as_keyring
    "[#{keyname}]\n\tkey = #{key}\n"
  else
    key
  end
end
