#
# Cookbook Name:: ceph
# Resource:: pool
#
# Author:: Sergio de Carvalho <scarvalhojr@users.noreply.github.com>
#

actions :create, :delete
default_action :create

property :name, String, name_property: true

# The total number of placement groups for the pool.
property :pg_num, Integer, required: true

# Optional arguments for pool creation
property :create_options, String

# Forces a non-empty pool to be deleted.
property :force, [TrueClass, FalseClass], default: false

property :exists

action :create do
  if current_value.exists
    Chef::Log.info "#{new_resource} already exists - nothing to do."
  else
    converge_by("Creating #{new_resource}") do
      create_pool(new_resource)
    end
  end
end

action :delete do
  if current_value.exists
    converge_by("Deleting #{new_resource}") do
      delete_pool
    end
  else
    Chef::Log.info "#{current_value} does not exist - nothing to do."
  end
end

load_current_value do
  name name
  exists pool_exists?(name)
end

def create_pool(new_resource)
  cmd_text = "ceph osd pool create #{new_resource.name} #{new_resource.pg_num}"
  cmd_text << " #{new_resource.create_options}" if new_resource.create_options
  cmd = Mixlib::ShellOut.new(cmd_text)
  cmd.run_command
  cmd.error!
  Chef::Log.debug "Pool created: #{cmd.stderr}"
end

def delete_pool(new_resource)
  cmd_text = "ceph osd pool delete #{new_resource.name}"
  cmd_text << " #{new_resource.name} --yes-i-really-really-mean-it" if
    new_resource.force
  cmd = Mixlib::ShellOut.new(cmd_text)
  cmd.run_command
  cmd.error!
  Chef::Log.debug "Pool deleted: #{cmd.stderr}"
end

def pool_exists?(name)
  cmd = Mixlib::ShellOut.new("ceph osd pool get #{name} size")
  cmd.run_command
  cmd.error!
  Chef::Log.debug "Pool exists: #{cmd.stdout}"
  true
rescue
  Chef::Log.debug "Pool doesn't seem to exist: #{cmd.stderr}"
  false
end
