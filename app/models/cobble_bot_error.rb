class CobbleBotError < StandardError
  def initialize(cause)
    super
    @cause = cause
  end
  
  def local_backtrace
    trace = @cause.backtrace.select do |line|
      line =~ /cobblebot/i
    end.join("\n")
    
    "#{@cause.inspect}\n#{trace}".strip
  end
end
