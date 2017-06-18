# Encoding: utf-8
# IBM WebSphere Application Server Liberty Buildpack
# Copyright 2014 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'timeout'
require 'socket'

class DropletUtils

  private_class_method :new

  class << self

    # Returns the server directory (where the physical server.xml, runtime-vars.xml, jvm.options, etc files are located)
    #
    # @param [String] app_dir the name of the app directory.
    # @return [String] the name of the server directory
    def get_server_directory(app_dir)
      # find the Liberty server directory. The directory will either contain the physical server.xml (and similar files) for the push app or push package
      # use cases and will contain sym links to the file in the push directory case. For use cases where we may be creating new files (includes) as well as updating
      # existing files (server.xml, jvm.options, etc) this is the directory we need to use.
      candidates = Dir[File.join(app_dir, 'wlp/usr/servers/*/server.xml')]
      raise "Incorrect number of server.xml's found, expecting exactly one #{candidates}" unless candidates.size == 1
      File.dirname(candidates[0])
    end

    # Return the (constant) name of the jmx server include file. A glorified Global Constant
    #
    # @return [String] the include file name.
    def jmx_handler_include_name
      'app-management-jmx-handler.xml'
    end

    # Return the (constant) name of the proxy config filename relative to the app dir. A glorified Global Constant
    #
    # @return [String] the include file name.
    def proxy_config_filename
      File.join('.app-management', 'bin', 'proxy.config')
    end

    # Determine if someone is listening on the specified port. Typically used to see if the runtime is listening on the port
    def port_bound?(port)
      port_bound = false
      begin
        Timeout.timeout(5) do
          begin
            s = TCPSocket.open('localhost', port.to_i)
            # runtime is listening on port
            s.close
            port_bound = true
          rescue StandardError
            # imperfect code for an imperfect world. Parent class of network exceptions
            port_bound = false
          end
        end
      rescue Timeout::Error
        port_bound = false
      end
      port_bound
    end

    #------------------------------------------------------------------------------------
    # Return an available port within the specified port range.
    #
    # @param [String] start_port starting port to check
    # @param [String] end_port last port to check
    # @return [String] returns the first available port from start_port to end_port
    #------------------------------------------------------------------------------------
    def find_port(start_port, end_port)
      port = start_port
      while port < end_port
        begin
          s = TCPSocket.open('localhost', port)
          s.close
          port += 1
        rescue
          return port
        end
      end
      raise "Unable to find free port. Starting port #{start_port} and ending port #{end_port}"
    end

  end
end
