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

require File.expand_path('../ci_component', __FILE__)

class Chef
  class Resource::CiComponentSecureSlaves < Resource::CiComponent
    attribute(:master_key, kind_of: String, required: true)
    attribute(:secrets_key, kind_of: String, required: true)
    attribute(:username, kind_of: String, default: lazy { node['ci']['server_username'] })
    attribute(:encrypted_api_token, kind_of: String, required: true)
  end

  class Provider::CiComponentSecureSlaves < Provider::CiComponent
    def action_enable
      notifying_block do
        create_secrets_dir
        create_master_key
        create_secrets_key
        create_users_dir
        create_slave_user_dir
        create_slave_user
      end
    end

    def action_disable
      raise NotImplementedError, 'Action :disable is not supported at this time'
    end

    private

    def create_secrets_dir
      directory ::File.join(new_resource.parent.path, 'secrets') do
        owner new_resource.parent.user
        group new_resource.parent.group
        mode '700'
      end
    end

    def create_master_key
      file ::File.join(new_resource.parent.path, 'secrets', 'master.key') do
        owner new_resource.parent.user
        group new_resource.parent.group
        mode '700'
        content new_resource.master_key
      end
    end

    def create_secrets_key
      file ::File.join(new_resource.parent.path, 'secrets', 'hudson.util.Secret') do
        owner new_resource.parent.user
        group new_resource.parent.group
        mode '700'
        content new_resource.secrets_key
      end
    end

    def create_users_dir
      directory ::File.join(new_resource.parent.path, 'users') do
        owner new_resource.parent.user
        group new_resource.parent.group
        mode '755'
      end
    end

    def create_slave_user_dir
      directory ::File.join(new_resource.parent.path, 'users', new_resource.username) do
        owner new_resource.parent.user
        group new_resource.parent.group
        mode '755'
      end
    end

    def create_slave_user
      template ::File.join(new_resource.parent.path, 'users', new_resource.username, 'config.xml') do
        owner new_resource.parent.user
        group new_resource.parent.group
        mode '644'
        variables api_token: new_resource.encrypted_api_token
        source 'slave_user.xml.erb'
        cookbook 'ci'
      end
    end
  end
end
