use_inline_resources

def whyrun_supported?
  true
end

action :add do
  name = @new_resource.name
  keyname = @new_resource.keyname || "client.#{name}"
  as_keyring = @new_resource.as_keyring
  default_filename = "/etc/ceph/ceph.#{keyname}.#{as_keyring ? 'keyring' : 'secret'}"
  filename = @new_resource.filename || default_filename
  owner = @new_resource.owner
  group = @new_resource.group
  mode = @new_resource.mode

  # Obtain the key from its vault if one wasn't provided
  key = @new_resource.key || ceph_secret(name)

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
