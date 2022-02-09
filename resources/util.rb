# frozen_string_literal: true

# Adapted from https://stackoverflow.com/questions/6934185/ruby-net-http-following-redirects
class UrlResolver
  def self.fetch(uri_str, outfile, agent = 'curl/7.43.0', max_attempts = 10, timeout = 10)
    attempts = 0
    cookie = nil

    until attempts >= max_attempts
      attempts += 1

      url = URI.parse(uri_str)
      http = Net::HTTP.new(url.host, url.port)
      http.open_timeout = timeout
      http.read_timeout = timeout
      path = url.path
      path = '/' if path == ''
      path += '?' + url.query unless url.query.nil?

      params = { 'User-Agent' => agent, 'Accept' => '*/*' }
      params['Cookie'] = cookie unless cookie.nil?
      request = Net::HTTP::Get.new(path, params)

      if url.instance_of?(URI::HTTPS)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      http.request request do |response|
        case response
        when Net::HTTPSuccess then
          total = response.header['Content-Length'].to_i
          if total == 0
            fail 'Did not successfully download zip file.'
          end

          size = 0
          progress = 0
          open outfile, 'wb' do |io|
            response.read_body do |chunk|
              io.write chunk
              size += chunk.size
              new_progress = (size * 100) / total
              unless new_progress == progress
                puts 'Downloading %s (%3d%%) ' % [url.path, new_progress]
              end
              progress = new_progress
            end
          end
          return
        when Net::HTTPRedirection then
          location = response['Location']
          cookie = response['Set-Cookie']
          new_uri = URI.parse(location)
          uri_str = if new_uri.relative?
                      url + location
                    else
                      new_uri.to_s
                    end
        else
          raise 'Unexpected response: ' + response.inspect
        end
      end

    end
    raise 'Too many http redirects' if attempts == max_attempts
  end
end
