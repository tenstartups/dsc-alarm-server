require 'slack-notifier'
require 'singleton'

module DSCConnect
  module Action
    class Slack
      include Singleton
      include LoggingHelper

      def notify(username: 'DSC Event', icon_url: nil, title:, message: nil, color: nil)
        notifier = ::Slack::Notifier.new(webhook_url, username: username)
        params = {}
        params.merge! icon_url: icon_url if icon_url
        attachment = {}
        attachment.merge! fallback: message || title, title: title
        attachment.merge! text: message if message
        attachment.merge! color: color if color
        params.merge! attachments: [attachment]
        response = notifier.ping(message, params)
        info "Response : #{response.body}"
      rescue Errno::EINVAL, Errno::ECONNREFUSED, Errno::ECONNRESET,
             EOFError, SocketError, Timeout::Error, Net::HTTPBadResponse,
             Net::HTTPHeaderSyntaxError, Net::ProtocolError, RestClient::Unauthorized => e
        raise ActionError, e.message
      end

      private

      def webhook_url
        Configuration.instance.action_handlers.try(:slack).try(:webhook_url)
      end
    end
  end
end
