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
    actions(:uninstall, :restart, :wait_until_up, :rebuild_config)

    attribute(:server_role, kind_of: String, default: lazy { node['ci']['server_role'] })

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
  end
end
