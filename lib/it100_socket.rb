require 'singleton'
require 'socket'

class IT100Socket < TCPSocket
  include Singleton

  def initialize(uri = nil)
    @it100_uri = uri
    super(it100_uri.host, it100_uri.port)
  end

  def it100_uri
    @it100_uri ||= URI(ENV['IT100_URI'])
  end
end
