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
  class Resource
    class CiJob < LWRPBase
      self.resource_name = :ci_job
      default_action(:create)
      actions(:remove)

      attribute(:repository, kind_of: String)
      attribute(:job_source, kind_of: String, default: 'job-config.xml.erb')
      attribute(:job_cookbook, kind_of: [String, Symbol], default: 'ci')
      attribute(:server_role, kind_of: String)
      attribute(:builder_role, kind_of: String)
      attribute(:builder_recipe, kind_of: String)
      attribute(:builder_remove_recipe, kind_of: String)

      def after_create
        unless self.repository
          if node['ci']['repository_template']
            self.repository(node['ci']['repository_template'] % self.name)
          else
            raise Exceptions::ValidationFailed, 'Required argument repository is missing!'
          end
        end
        self.server_role(self.node['ci']['server_role']) unless self.server_role
        self.builder_role(self.node['ci']['builder_role_template'] % self.name) unless self.builder_role
        self.builder_recipe(self.node['ci']['builder_recipe_template'] % self.name) unless self.builder_recipe
        self.builder_remove_recipe(self.node['ci']['builder_remove_recipe_template'] % self.name) if !self.builder_recipe and self.node['ci']['builder_remove_recipe_template']
      end

      def is_server?
        self.node['roles'].include?(self.server_role)
      end

      def is_builder?
        self.node['roles'].include?(self.builder_role)
      end

      def provider_for_action(action)
        provider_class = if self.is_server?
          Provider::CiJob::Server
        elsif self.is_builder?
          Provider::CiJob::Builder
        else
          Provider::CiJob
        end
        provider = provider_class.new(self, self.run_context)
        provider.action = action
        provider
      end
    end
  end

  class Provider
    class CiJob < LWRPBase
      def whyrun_supported?
        true
      end

      def action_create
      end

      def action_remove
      end

      class Server < CiJob
        def load_current_resource
          @jenkins_job = Chef::Resource::JekninsJob.new(self.new_resource.name, self.run_context)
          @jenkins_job.action(:nothing)
          @jenkins_job.config(::File.join(node['jenkins']['node']['home'], "#{self.new_resource.name}-config.xml"))

          @template = Chef::Resource::Template.new(@jenkins_job.config, self.run_context)
          @template.source(self.new_source.job_source)
          @template.cookbook(self.new_source.job_source)
          @template.owner('root')
          @template.group('root')
          @template.mode('644')
          @template.notifies(:update, @jenkins_job, :immediately)
        end

        def action_create
          @template.run_action(:create)
          if @template.updated? || @jenkins_job.updated?
            new_resource.updated_by_last_action(true)
          end
        end

        def action_remove
          @template.run_action(:delete)
          @jenkins_job.run_action(:delete)
          if @template.updated? || @jenkins_job.updated?
            new_resource.updated_by_last_action(true)
          end
        end
      end

      class Builder < CiJob
        def action_create
          self.run_context.include_recipe(self.new_resource.builder_recipe)
        end

        def action_remove
          raise 'No removal recipe specified' unless self.new_resource.builder_remove_recipe
          self.run_context.include_recipe(self.new_resource.builder_remove_recipe)
        end
      end
    end
  end
end
