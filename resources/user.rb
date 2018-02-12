default_action :create

property :caps, Hash, default: { 'mon' => 'allow r' }

# what the key should be called in the ceph cluster
# defaults to client.#{name}
property :keyname, String

# The actual key
property :key, String

action :create do
  # current_value is set in load_current_value
  # new_resource values are set by ceph_user resource (e.g., in
  # recipes/_ceph_controller.rb)
  name = new_resource.name
  keyname = new_resource.keyname || "client.#{name}"
  key = new_resource.key
  caps = new_resource.caps
  current_caps = get_caps(keyname)
  current_key = get_key(keyname)

  if current_caps
    # XXX If no key is passed to the ceph_user resource, key matching is
    #     ignored; the message "already exists and matches" (below) may be a
    #     bit confusing in that case.
    keys_match = key.nil? || (current_key == key)
    caps_match = current_caps == caps

    if keys_match && caps_match
      Chef::Log.info "Client #{name} already exists and matches "\
                     'specifications - nothing to do.'
    else
      # Todo(JR): Be less intrusive and update changed caps instead of
      # recreating
      converge_by("Recreating client #{name} as existing doesn't "\
                  'match specifications') do
        delete_entity(keyname)
        create_entity(keyname, key, caps)
      end
    end
  else
    converge_by("Creating client #{name}") do
      create_entity(keyname, key, caps)
    end
  end

  # remove temporary keyring file
  tmp_keyring = get_tmp_path(keyname)
  file tmp_keyring do # ~FC009
    action :delete
    sensitive true if Chef::Resource::File.method_defined? :sensitive
  end
end

def get_tmp_path(keyname)
  "#{Chef::Config[:file_cache_path]}/.#{keyname}.keyring"
end

def get_key(keyname)
  cmd = "ceph auth print_key #{keyname} --name mon. --key='#{mon_secret}'"
  Mixlib::ShellOut.new(cmd).run_command.stdout
end

def get_caps(keyname)
  caps = {}
  cmd = "ceph auth get #{keyname} --name mon. --key='#{mon_secret}'"
  output = Mixlib::ShellOut.new(cmd).run_command.stdout
  output.scan(/caps\s*(\S+)\s*=\s*"([^"]*)"/) { |k, v| caps[k] = v }
  caps unless caps == {}
end

def delete_entity(keyname)
  cmd_text = "ceph auth del #{keyname} --name mon. --key='#{mon_secret}'"
  cmd = Mixlib::ShellOut.new(cmd_text)
  cmd.run_command
  cmd.error!
  Chef::Log.debug "Client #{keyname} deleted"
end

def create_entity(keyname, key, caps)
  tmp_keyring = get_tmp_path(keyname)

  key ||= ceph_secret(keyname)

  cmd_text = "ceph-authtool #{tmp_keyring} --create-keyring --name #{keyname} "\
             "--add-key '#{key}'"
  cmd = Mixlib::ShellOut.new(cmd_text)
  cmd.run_command
  cmd.error!

  caps = caps.map { |k, v| "#{k} '#{v}'" }.join(' ')

  cmd_text = "ceph auth -i #{tmp_keyring} add #{keyname} #{caps} --name mon. "\
             "--key='#{mon_secret}'"
  cmd = Mixlib::ShellOut.new(cmd_text)
  cmd.run_command
  cmd.error!
  Chef::Log.debug "Client #{keyname} created"
end
