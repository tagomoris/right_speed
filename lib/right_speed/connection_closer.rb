# frozen_string_literal: true

require_relative "logger"

module RightSpeed
  class ConnectionCloser
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
  end
end
