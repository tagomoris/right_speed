# frozen_string_literal: true

require_relative "logger"

module RightSpeed
  class ConnectionCloser
    # This class was introduced to serialize closing connections
    # (instead of closing those in each Ractor) to try to avoid SEGV.
    # But SEGV is still happening, so this class may not be valueable.

    def run(workers)
      @ractor = Ractor.new(workers) do |workers|
        logger = RightSpeed.logger
        while workers.size > 0
          r, conn = Ractor.select(*workers, move: true)
          if conn == :closing
            workers.delete(r)
            next
          end
          begin
            conn.close
          rescue => e
            logger.debug { "Error while closing a connection #{conn}, #{e.class}:#{e.message}" }
          end
        end
      rescue => e
        logger.error { "Unexpected error, #{e.class}:#{e.message}" }
      end
    end

    def wait
      @ractor.take
    end
  end
end
