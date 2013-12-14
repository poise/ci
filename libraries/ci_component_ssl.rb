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
  class Resource::CiComponentSsl < Resource::CiComponent
    attribute(:certificate, kind_of: String, required: true)
    attribute(:key, kind_of: String, required: true)
    # attribute(:source, kind_of: String)
    # attribute(:cookbook, kind_of: [String, Symbol])
    # attribute(:content, kind_of: String)
    # attribute(:options, option_collector: true)
    attribute(:hostname, kind_of: String)

    def ssl_dir
      ::File.join(parent.path, 'ssl')
    end

    def certs_dir
      ::File.join(ssl_dir, 'certificates')
    end

    def keys_dir
      ::File.join(ssl_dir, 'keys')
    end

    def cert_path
      ::File.join(certs_dir, "#{parent.name}.pem")
    end

    def key_path
      ::File.join(keys_dir, "#{parent.name}.key")
    end
  end

  class Provider::CiComponentSsl < Provider::CiComponent
    def action_enable
      converge_by("install SSL support for CI server #{new_resource.parent.name}") do
        notifying_block do
          create_ssl_dir
          create_certs_dir
          create_keys_dir
          create_cert
          create_key
          install_proxy
        end
      end
    end

    def action_disable
      raise NotImplementedError, 'Action :disable is not supported at this time'
    end

    private

    def create_ssl_dir
      directory new_resource.ssl_dir do
        owner 'root'
        group 'root'
        mode '755'
      end
    end

    def create_certs_dir
      directory new_resource.certs_dir do
        owner 'root'
        group 'root'
        mode '755'
      end
    end

    def create_keys_dir
      directory new_resource.keys_dir do
        owner 'root'
        group 'root'
        mode '700'
      end
    end

    def create_cert
      file new_resource.cert_path do
        owner 'root'
        group 'root'
        mode '644'
        content new_resource.certificate
      end
    end

    def create_key
      file new_resource.key_path do
        owner 'root'
        group 'root'
        mode '600'
        content new_resource.key
      end
    end

    def install_proxy
      jenkins_proxy new_resource.parent.name do
        parent new_resource.parent
        # source new_resource.source
        # cookbook new_resource.cookbook
        # content new_resource.content
        # options new_resource.options
        hostname new_resource.hostname
        provider :nginx

        ssl_enabled true
        ssl_redirect_http true
        cert_path new_resource.cert_path
        key_path new_resource.key_path
      end
    end
  end
end
