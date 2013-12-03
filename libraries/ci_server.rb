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

require File.expand_path('../ci_deploy_key', __FILE__)

class Chef
  class Resource::CiServer < Resource::Jenkins
    include Ci::SshHelper::Resource
    attribute(:path, kind_of: String, default: lazy { node['ci']['path'] })

    def component(name, &block)
      method_missing(:"component_#{name}", name, &block)
    rescue NameError
      method_missing(:component, name, &block)
    end

    private

    def sub_resource_name(method_symbol)
      :"ci_#{method_symbol}"
    end

  end

  class Provider::CiServer < Provider::Jenkins
    include Ci::SshHelper::Provider

    def action_install
      # Force server tag to true
      node.override['ci']['is_server'] = true
      super
    end

    def ssh_group
      new_resource.ssh_dir_group
    end

    private

    def create_ssh_dir
      r = super
      manage_ssh # Via SshHelper
      r
    end
  end
end
