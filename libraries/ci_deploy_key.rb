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

require File.expand_path('../ci_server', __FILE__)

class Chef
  class Resource::CiDeployKey < Resource
    include Poise(CiServer)
    actions(:create, :remove)

    attribute(:key, kind_of: String, required: true)
    attribute(:hostname, kind_of: String, default: '*')

    def path
      ::File.join(parent.ssh_path, "#{name}.pub")
    end

    def after_created
      super
      notifies(:rebuild_ssh_config, parent)
    end

  end

  class Provider::CiDeployKey < Provider
    include Poise

    def action_create
      notifying_block do
        create_key
      end
    end

    def action_remove
      notifying_block do
        remove_key
      end
    end

    private

    def create_key
      file new_resource.path do
        owner new_resource.parent.user
        group new_resource.parent.ssh_dir_group
        mode '600'
        content new_resource.key
      end
    end

    def remove_key
      r = create_key
      r.action(:delete)
      r
    end

  end
end
