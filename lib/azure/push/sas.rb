require 'cgi'
require 'base64'
require 'openssl'

module Azure
  module Push
    module Sas
      def self.sas_token(url, key_name, access_key)
        # lifetime ||= {lifetime: 10}
        target_uri = CGI.escape(url.downcase).gsub('+', '%20').downcase
        expires = Time.now.to_i + 1000 #FIXME: hardcoded lifetime
        to_sign = "#{target_uri}\n#{expires}"
        signature = CGI.escape(Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), access_key, to_sign))).gsub('+', '%20')
        "SharedAccessSignature sr=#{target_uri}&sig=#{signature}&se=#{expires}&skn=#{key_name}"
      end
    end
  end
end