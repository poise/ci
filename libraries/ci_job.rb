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
  class Resource::CiJob < Resource::LWRPBase
    include Poise
    poise_subresource(CiServer)
    self.resource_name = :ci_job
    default_action(:enable)
    actions(:disable)

    attribute(:job_name, kind_of: String, default: lazy { name.split('::').last })
    attribute(:source, kind_of: String)
    attribute(:cookbook, kind_of: [String, Symbol])
    attribute(:content, kind_of: String)

    attribute(:repository, kind_of: String, default: lazy { node['ci']['repository'] })
    attribute(:server_role, kind_of: String, default: lazy { parent.server_role || node['ci']['server_role'] })
    attribute(:builder_role, kind_of: String, default: lazy { node['ci']['builder_role'] })
    attribute(:builder_recipe, kind_of: String, default: lazy { node['ci']['builder_recipe'] })

    def after_created
      super
      raise "#{self}: Only one of source or content can be specified" if source && content
      raise Exceptions::ValidationFailed, 'Required argument repository is missing!' unless repository

      # If source is given, the default cookbook should be the current one
      cookbook(source ? cookbook_name : 'ci')
      # If neither source nor content are given, fill in a default
      source('job-config.xml.erb') if !source && !content

      # Interpolate the job name into a few attributes to make life easier
      %w{repository server_role builder_role builder_recipe}.each do |key|
        val = send(key)
        send(key, val % {name: job_name}) if val
      end
    end

    def provider_for_action(action)
      provider_class = if is_server?
        Provider::CiJob::Server
      elsif is_builder?
        Provider::CiJob::Builder
      else
        Provider::CiJob
      end
      provider = provider_class.new(self, run_context)
      provider.action = action
      provider
    end

    private

    def is_server?
      node['roles'].include?(server_role)
    end

    def is_builder?
      node['roles'].include?(builder_role)
    end
  end

  class Provider::CiJob < Provider::LWRPBase
    include Poise

    def whyrun_supported?
      true
    end

    # These spaces left intentionally blank
    def action_enable
    end

    def action_disable
    end

    class Server < CiJob
      def action_enable
        notifying_block do
          enable_job
        end
      end

      def action_disable
        notifying_block do
          disable_job
        end
      end

      private

      def enable_job
        jenkins_job new_resource.name do
          source new_resource.source
          cookbook new_resource.cookbook
          content new_resource.content
          parent new_resource.parent
          options do
            repository new_resource.repository
          end
        end
      end

      def disable_job
        r = enable_job
        r.action(:disable)
        r
      end

    end

    class Builder < CiJob
      def action_enable
        include_recipe(new_resource.builder_recipe)
      end
    end
  end
end
