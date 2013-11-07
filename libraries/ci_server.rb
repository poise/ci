#
# Author:: Noah Kantrowitz <noah@coderanger.net>
#
# Copyright 2013, Balanced, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class Chef
  class Resource::CiServer < Resource::Jenkins
    self.resource_name = :ci_server

    # TODO: FIX REQUIRED COPY PASTA OF THESE
    default_action(:install)
    actions(:uninstall, :restart, :wait_until_up, :rebuild_config, :rebuild_ssh_config)

    attribute(:server_role, kind_of: String, default: lazy { node['ci']['server_role'] })
    attribute(:known_hosts, kind_of: String, default: lazy { node['ci']['known_hosts'] })

    def component(name, &block)
      method_missing(:"component_#{name}", name, &block)
    rescue NameError
      method_missing(:component, name, &block)
    end

    def after_created
      super
      action(:nothing) unless is_server?
    end

    private

    def sub_resource_name(method_symbol)
      :"ci_#{method_symbol}"
    end

    def is_server?
      node['roles'].include?(server_role)
    end

  end

  class Provider::CiServer < Provider::Jenkins

    def action_rebuild_ssh_config
      converge_by('generate Jenkins ssh config') do
        notifying_block do
          create_ssh_config
        end
      end
    end

    private

    def create_ssh_dir
      r = super
      create_known_hosts
      create_ssh_config
      r
    end

    def create_known_hosts
      file ::File.join(new_resource.ssh_path, 'known_hosts') do
        owner new_resource.user
        group new_resource.ssh_dir_group
        mode '600'
        content Array(new_resource.known_hosts).join("\n")
      end
    end

    def create_ssh_config
      # Find all keys and group them by hostname
      keys = {}
      new_resource.subresources.each do |r|
        if r.is_a?(Resource::CiDeployKey)
          (keys[r.hostname] ||= []) << r
        end
      end

      template ::File.join(new_resource.ssh_path, 'config') do
        source 'ssh_config.erb'
        cookbook 'ci'
        owner new_resource.user
        group new_resource.ssh_dir_group
        mode '600'
        variables new_resource: new_resource, keys: keys
      end
    end
  end
end
