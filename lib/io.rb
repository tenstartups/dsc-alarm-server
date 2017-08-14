require 'stringio'
require 'timeout'

class IO
  def readline_nonblock(timeout: 1, line_end: "\n")
    StringIO.new.tap do |buffer|
      begin
        Timeout.timeout(timeout) do
          while (ch = recv(1))
            buffer << ch
            break if buffer.string.ends_with?(line_end)
          end
        end
      rescue Timeout::Error
        buffer.string = ''
      end
    end.string
  end
end
