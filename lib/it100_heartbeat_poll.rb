module DSCConnect
  class IT100HeartbeatPoll
    include WorkerThreadBase

    def do_work
      @next_heartbeat_at ||= Time.now.to_i + 30
      return unless (now = Time.now.to_i) >= @next_heartbeat_at
      debug 'Sending heartbeat request'
      IT100SocketClient.instance.poll
      @next_heartbeat_at = now + 30
    end
  end
end
