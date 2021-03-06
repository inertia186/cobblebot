# Used for ad-hoc thread running a block as its own.  It is highly
# recommended that database access be avoided in the run block.
module Runnable
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    def run(options = {max_wait: 1}, &block)
      result = nil
      
      thread = Thread.start do
        result = yield
      end
      
      thread if thread.join(options[:max_wait])
      
      result || thread
    end
  end
end