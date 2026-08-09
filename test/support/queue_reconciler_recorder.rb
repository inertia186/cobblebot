class QueueReconcilerRecorder
  attr_reader :calls

  def initialize(results: {}, error: nil)
    @results = results
    @error = error
    @calls = []
  end

  def call(**arguments)
    calls << arguments
    raise error if error

    results.fetch(arguments.fetch(:worker_class))
  end

private
  attr_reader :error, :results
end
