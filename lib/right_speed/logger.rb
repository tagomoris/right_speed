module RightSpeed
  def self.logger
    return Ractor.current[:logger] if Ractor.current[:logger]
    logger = Logger.new($stderr)
    logger.formatter = lambda {|severity, datetime, progname, msg| "[#{datetime}] #{msg}\n" }
    Ractor.current[:logger] = logger
    logger
  end
end
