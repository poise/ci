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
  class Resource::CiComponent < Resource
    include Poise(CiServer)
    actions(:enable, :disable)

    attribute(:plugin, kind_of: String, default: lazy { name.split('::').last })
    attribute('', template: true, default_source: lazy { "#{plugin}.xml.erb" })
  end

  class Provider::CiComponent < Provider
    include Poise

    def action_enable
      notifying_block do
        install_plugin
        enable_config
      end
    end

    def action_disable
      notifying_block do
        remove_plugin
        disable_config
      end
    end

    private

    def install_plugin
      jenkins_plugin new_resource.plugin do
        parent new_resource.parent
      end
    end

    def enable_config
      jenkins_config new_resource.plugin do
        content new_resource.content
        parent new_resource.parent
      end
    end

    def remove_plugin
      r = install_plugin
      r.action(:remove)
      r
    end

    def disable_config
      r = enable_config
      r.action(:disable)
      r
    end
  end
end
