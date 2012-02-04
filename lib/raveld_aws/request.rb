require 'base64'
require 'cgi'
require 'net/https'
require 'openssl'
require 'uri'
require 'xml/libxml'

module RaveldAws
  class Request
    def initialize(host, parameters, aws_access_key, aws_secret_key)
      parameters['AWSAccessKeyId'] = aws_access_key
      parameters['SignatureVersion'] = '2'
      parameters['SignatureMethod'] = 'HmacSHA256'
      parameters['Timestamp'] = utc_iso8601(Time.now)
      parameters['Signature'] = calculate_signature("GET", 
                                                    host, 
                                                    parameters, 
                                                    aws_secret_key)
      query = parameters.keys.map do |key|
        "#{amz_escape(key)}=#{amz_escape(parameters[key])}"
      end.join('&')
      @uri = "https://#{host}/?#{query}"
    end
    
    # Can be called with a block if 'custom' error handling is needed.
    # The block will be called with the response hash if an error occurs.
    # If no block is given on an error, a BrainstemException will be raised.
    #
    # For example, the structure of the AMZN error response for EC2 is different
    # than that of EMR.
    def execute
      puri = URI.parse(@uri)
      http = Net::HTTP.new(puri.host, puri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Get.new(puri.request_uri) 
      response = http.request(request)
      
      if (!response || (response.code != '200'))
        # failure
        if response && !response.body.nil?
          # grab the AMZN error message and pass it along
          raise xml_to_hash(response.body)
        else
          # no error info to be found
          raise 'unknown'
        end
      else
        # success
        return xml_to_hash(response.body)
      end
    end
    
private
    def xml_to_hash(xml)
      begin
        XML.default_load_external_dtd = false
        XML.default_pedantic_parser = true
        result = XML::Parser.string(xml).parse
        return { result.root.name.to_s => xml_node_to_hash(result.root)}
      rescue Exception => e
        # raise your custom exception here
      end
    end
    
    def xml_node_to_hash(node)
      # If we are at the root of the document, start the hash
      if node.element?
        if node.children?
          result_hash = {}
  
          node.each_child do |child|
            result = xml_node_to_hash(child)
  
            if child.name == "text"
              if !child.next? and !child.prev?
                return result
              end
            elsif result_hash[child.name.to_sym]
              if result_hash[child.name.to_sym].is_a?(Object::Array)
                result_hash[child.name.to_sym] << result
              else
                result_hash[child.name.to_sym] = [result_hash[child.name.to_sym]] << result
              end
            else
              result_hash[child.name.to_sym] = result
            end
          end
  
          return result_hash
        else
          return nil
        end
      else
        return node.content.to_s
      end
    end

    def utc_iso8601(time)
      time.utc.strftime("%Y-%m-%dT%H:%M:%S.000Z")
    end

    # Escape a string according to Amazon rules
    def amz_escape(param)
      CGI.escape(param.to_s).gsub("+", "%20").gsub("%7E", "~")
    end

    def calculate_signature(verb, host, parameter_map, secret_key)
      digest = OpenSSL::Digest::Digest.new("sha256")
      canonical_string = parameter_map.keys.sort.map do |key|
        "#{amz_escape(key)}=#{amz_escape(parameter_map[key])}"
      end.join('&')
      to_sign = "#{verb.to_s.upcase}\n#{host.downcase}\n/\n#{canonical_string}"
      Base64.encode64(OpenSSL::HMAC.digest(digest, secret_key, to_sign)).strip
    end
  end
end