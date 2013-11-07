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

# Template for the repository for a specific job. Unset by default.
#   The %{name} will be replaced with the job name
default['ci']['repository'] = nil

# Role to use to find the Jenkins server.
default['ci']['server_role'] = 'ci-server'

# Template for the role to find the builder for a specific job.
#   The %{name} will be replaced with the job name
default['ci']['builder_role'] = 'ci-builder-%{name}'

# Template for the recipe used to prepare a builder for a specific job.
#   The %{name} will be replaced with the job name
default['ci']['builder_recipe'] = 'ci-app::%{name}'

# Default SSH known_hosts for Jenkins.
# This default value is for github.com as of 2013-11-05.
# TODO: Query this via DNS.
default['ci']['known_hosts'] = "github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==\n"
