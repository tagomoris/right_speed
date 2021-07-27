module RightSpeed
  module Worker
    class Base
      def self.logger
        return Ractor.current[:logger] if Ractor.current[:logger]
        logger = Logger.new($stderr)
        logger.formatter = lambda {|severity, datetime, progname, msg| "[#{datetime}] #{msg}\n" }
        Ractor.current[:logger] = logger
        logger
      end

      def initialize(id:)
        @id = id
        @ractor = nil
        # TODO: initialization of webapp
      end

      def stop
        @ractor # terminate if possible
      end
    end
  end
end
