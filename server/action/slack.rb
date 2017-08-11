require 'slack-notifier'

module DSCConnect
  module Action
    class Slack < Base
      def notify(username: 'DSC Event', icon_url: nil, title:, message: nil, color: nil)
        notifier = ::Slack::Notifier.new(webhook_url, username: username)
        params = {}
        params[:icon_url] = icon_url if icon_url
        attachment = {}
        attachment[:fallback] = message || title
        attachment[:title] = title
        attachment[:text] = interpolate_message(message) if message
        attachment[:color] = color if color
        params[:attachments] = [attachment]
        response = notifier.ping(nil, params)
        info "Response : #{response.body}"
      rescue Errno::EINVAL, Errno::ECONNREFUSED, Errno::ECONNRESET,
             EOFError, SocketError, Timeout::Error, Net::HTTPBadResponse,
             Net::HTTPHeaderSyntaxError, Net::ProtocolError, RestClient::Unauthorized,
             SocketError => e
        raise Error, e.message
      end

      private

      def interpolate_message(message)
        message.gsub('%{occurred_at}', source_event.timestamp.strftime('%B %-d, %Y at %I:%M:%S%p'))
      end

      def webhook_url
        config[:webhook_url]
      end
    end
  end
end
