require 'timeout'

class IO
  def readline_nonblock
    StringIO.new.tap do |buffer|
      begin
        timeout(1) do
          while (ch = recv(1))
            buffer << ch
            break if ch == "\n"
          end
        end
      rescue Timeout::Error
        # We timed out waiting therefore continue
      end
    end.string.strip
  end
end
