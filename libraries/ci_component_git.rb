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
  class Resource::CiComponentGit < Resource::CiComponent
    self.resource_name = :ci_component_git
    # TODO: FIX REQUIRED COPY PASTA OF THESE
    default_action(:enable)
    actions(:disable)
    parent_type(CiServer)
  end

  class Provider::CiComponentGit < Provider::CiComponent
    def install_plugin
      include_recipe 'git'
      super
    end
  end
end
