require 'rest-client'

module DSCConnect
  module Action
    class IFTTT < Base
      def maker_event(event:, **args)
        response = RestClient.post(
          event_uri(event),
          args.to_json,
          content_type: :json,
          accept: :json
        )
        info "Response : #{response}"
      rescue Errno::EINVAL, Errno::ECONNREFUSED, Errno::ECONNRESET,
             EOFError, SocketError, Timeout::Error, Net::HTTPBadResponse,
             Net::HTTPHeaderSyntaxError, Net::ProtocolError, RestClient::Unauthorized,
             SocketError => e
        raise Error, e.message
      end

      private

      def event_uri(event)
        "https://maker.ifttt.com/trigger/#{event}/with/key/#{maker_key}"
      end

      def maker_key
        config[:maker_key]
      end
    end
  end
end
