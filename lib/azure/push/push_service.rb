#-------------------------------------------------------------------------
# # Copyright (c) Microsoft and contributors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#--------------------------------------------------------------------------
require 'azure/push/sas'

module Azure
  module Push
    class PushService
      include Azure::Push::Sas

      def initialize(namespace, hub, access_key, key_name)
        # BEGIN workaround for named arguments
        #       Keeps compatibility with ruby < 2.0
          key_name ||= 'DefaultFullSharedAccessSignature'
        # END workaround for named arguments

        @access_key = access_key
        @key_name = key_name
        @namespace = namespace
        @hub = hub
        # @sig_lifetime = sig_lifetime
      end


      def send(payload, tags, format, additional_headers)
        # BEGIN workaround for named arguments
        #       Keeps compatibility with ruby < 2.0
        format ||='apple'
        additional_headers ||= {}
        # END workaround for named arguments

        raise ArgumentError unless %w(apple gcm template windows windowsphone).include? format
        raise ArgumentError unless additional_headers.instance_of?(Hash)
        if tags.instance_of?(Array)
          tags = tags.join(' || ')
        end
        uri = URI(url)
        content_type = %w(apple gcm template).include?(format) ? 'application/json' : 'application/xml;charset=utf-8'
        headers = {
            'Content-Type' => content_type,
            'Authorization' => Azure::Push::Sas.sas_token(url, @key_name, @access_key),
            'ServiceBusNotification-Format' => format,
            'ServiceBusNotification-Tags' => tags
        }.merge(additional_headers)
        http = Net::HTTP.new(uri.host,uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        req = Net::HTTP::Post.new(uri.path, initheader = headers)
        req.body = payload
        res = http.request(req)
        return true if res.kind_of?(Net::HTTPSuccess)
        raise "Azure send request failed.  HTTP Response: #{res.message}"
      end

      private
      def url
        "https://#{@namespace}.servicebus.windows.net/#{@hub}/messages"
      end
    end
  end
end
