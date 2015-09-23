use_inline_resources

def whyrun_supported?
  true
end

action :create do
  keyname = @current_resource.keyname

  if @current_resource.exists
    if @current_resource.keys_match && @current_resource.caps_match
      Chef::Log.info "Client #{ @new_resource } already exists and matches "\
                     'specifications - nothing to do.'
    else
      # Todo(JR): Be less intrusive and update changed caps instead of recreating
      converge_by("Recreating client #{ @new_resource } as existing doesn't "\
                  'match specifications') do
        delete_entity(keyname)
        create_entity(keyname)
      end
    end
  else
    converge_by("Creating client #{ @new_resource }") do
      create_entity(keyname)
    end
  end
end

def load_current_resource
  @current_resource = Chef::Resource::CephClient.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  @current_resource.keyname(@new_resource.keyname || "client.#{@new_resource.name}")
  @current_resource.caps(get_caps(@current_resource.keyname))
  @current_resource.key(get_key(@current_resource.keyname))
  @current_resource.caps_match = @current_resource.caps == @new_resource.caps
  @current_resource.keys_match = @new_resource.key.nil? || (@current_resource.key == @new_resource.key)
  @current_resource.exists = ! (@current_resource.key.nil? || @current_resource.key.empty?)
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
  caps
end

def delete_entity(keyname)
  cmd_text = "ceph auth del #{keyname} --name mon. --key='#{mon_secret}'"
  cmd = Mixlib::ShellOut.new(cmd_text)
  cmd.run_command
  cmd.error!
  Chef::Log.debug "Client #{keyname} deleted"
end

def create_entity(keyname)
  tmp_keyring = "#{Chef::Config[:file_cache_path]}/.#{keyname}.keyring"

  key = new_resource.key || ceph_secret(keyname)

  cmd_text = "ceph-authtool #{tmp_keyring} --create-keyring --name #{keyname} "\
             "--add-key '#{key}'"
  cmd = Mixlib::ShellOut.new(cmd_text)
  cmd.run_command
  cmd.error!

  caps = new_resource.caps.map { |k, v| "#{k} '#{v}'" }.join(' ')

  cmd_text = "ceph auth -i #{tmp_keyring} add #{keyname} #{caps} --name mon. "\
             "--key='#{mon_secret}'"
  cmd = Mixlib::ShellOut.new(cmd_text)
  cmd.run_command
  cmd.error!
  Chef::Log.debug "Client #{keyname} created"

  # remove temporary keyring file
  file tmp_keyring do # ~FC009
    action :delete
    sensitive true if Chef::Resource::File.method_defined? :sensitive
  end
end
