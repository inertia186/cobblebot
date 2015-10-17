class CobbleBotError < StandardError
  def initialize(options = {})
    super(@message = options[:message])
    @cause = options[:cause]
  end
  
  def local_backtrace
    trace = if @cause
      @cause.backtrace.select do |line|
        line.include?(Rails.root.to_s)
      end.join("\n")
    end
    
    "#{@message}\n#{@cause.inspect}\n#{trace}".strip
  end
end
