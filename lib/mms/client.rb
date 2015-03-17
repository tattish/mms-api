module MMS

  class Client

    attr_accessor :username
    attr_accessor :apikey
    attr_accessor :url

    # @param [String] username
    # @param [String] apikey
    # @param [String] url
    def initialize(username = nil, apikey = nil, url = nil)
      @username = username
      @apikey = apikey
      @url = url.nil? ? 'https://mms.mongodb.com:443/api/public/v1.0' : url
    end

    # @param [String] path
    # @return [Hash]     
    def get(path)
      _get(@url + path, @username, @apikey)
    end

    # @param [String] path
    # @param [Hash] data
    # @return [Hash]
    def post(path, data)
      _post(@url + path, data, @username, @apikey)
    end

    private
    
    def _get_ssl()
      return (@url.split(":")[0]=="https")
    end
    
    # @param [String] path
    # @param [String] username
    # @param [String] password
    def _get(path, username, password)

      digest_auth = Net::HTTP::DigestAuth.new
      digest_auth.next_nonce

      uri = URI.parse path
      uri.user= CGI.escape(username)
      uri.password= CGI.escape(password)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = _get_ssl

      req = Net::HTTP::Get.new uri.request_uri
      res = http.request req

      auth = digest_auth.auth_header uri, res['WWW-Authenticate'], 'GET'
      req = Net::HTTP::Get.new uri.request_uri
      req.add_field 'Authorization', auth

      response = http.request(req)
      response_json = JSON.parse(response.body)

      unless response.code == 200 or response_json['error'].nil?
        msg = "http 'get' error for url `#{url}`"
        msg = response_json['detail'] unless response_json['detail'].nil?

        raise MMS::AuthError.new(msg, req, response) if response.code == '401'
        raise MMS::ApiError.new(msg, req, response)
      end

      (response_json.nil? or response_json['results'].nil?) ? response_json : response_json['results']
    end

    # @param [String] path
    # @param [Hash] data
    # @param [String] username
    # @param [String] password
    def _post(path, data, username, password)
      digest_auth = Net::HTTP::DigestAuth.new
      digest_auth.next_nonce

      uri = URI.parse path
      uri.user= CGI.escape(username)
      uri.password= CGI.escape(password)

      http = Net::HTTP.new uri.host, uri.port
      http.use_ssl = _get_ssl
      
      req = Net::HTTP::Post.new uri.request_uri, {'Content-Type' => 'application/json'}
      res = http.request req

      auth = digest_auth.auth_header uri, res['WWW-Authenticate'], 'POST'
      req = Net::HTTP::Post.new uri.request_uri, {'Content-Type' => 'application/json'}
      req.add_field 'Authorization', auth
      req.body = data.to_json

      response = http.request req
      response_json = JSON.parse response.body

      unless response.code == 200 or response_json['error'].nil?
        msg = "http 'get' error for url `#{url}`"
        msg = response_json['detail'] unless response_json['detail'].nil?

        raise MMS::AuthError.new(msg, req, response) if response.code == '401'
        raise MMS::ApiError.new(msg, req, response)
      end

      (response_json.nil? or response_json['results'].nil?) ? response_json : response_json['results']
    end

  end
end
