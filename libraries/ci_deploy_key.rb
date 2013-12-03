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
  class Resource::CiDeployKey < Resource
    include Poise

    attribute(:key, kind_of: String, required: true)
    attribute(:hostname, kind_of: String, default: '*')
  end

  class Provider::CiDeployKey < Provider
    # This space left intentionally blank
  end
end

module Ci
  # Helper module for SSH-related configuration needed in both ci_server and ci_job (on the node side)
  module SshHelper
    module Resource
      def known_hosts(arg=nil)
        set_or_return(:known_hosts, arg, kind_of: String, default: node['ci']['known_hosts'])
      end
    end

    module Provider
      # Hooks to override helper behaviors
      def ssh_base_path
        ::File.join(new_resource.path, '.ssh')
      end

      def ssh_user
        new_resource.user
      end

      def ssh_group
        new_resource.group
      end

      private

      # Find all deploy keys visible in the current context
      def deploy_keys
        @deploy_keys ||= begin
          keys = []
          col = run_context.resource_collection
          it = proc {|r| keys << r if r.is_a?(Chef::Resource::CiDeployKey) }
          # If we are in a subcontext, we want to scan recursively
          if col.respond_to?(:recursive_each)
            col.recursive_each(&it)
          else
            col.each(&it)
          end
          keys
        end
      end

      # Action helpers
      def manage_ssh
        create_known_hosts
        create_ssh_keys
        create_ssh_config
      end

      def create_known_hosts
        file ::File.join(ssh_base_path, 'known_hosts') do
          owner ssh_user
          group ssh_group
          mode '600'
          content Array(new_resource.known_hosts).join("\n")
        end
      end

      def create_ssh_keys
        deploy_keys.each do |key|
          file ::File.join(ssh_base_path, key.name) do
            owner ssh_user
            group ssh_group
            mode '600'
            content key.key
          end
        end
      end

      def create_ssh_config
        # Find all keys and group them by hostname
        keys = deploy_keys.inject({}) do |memo, key|
          (memo[key.hostname] ||= []) << key
          memo
        end

        template ::File.join(ssh_base_path, 'config') do
          source 'ssh_config.erb'
          cookbook 'ci'
          owner ssh_user
          group ssh_group
          mode '600'
          variables new_resource: new_resource, keys: keys
        end
      end
    end
  end
end

