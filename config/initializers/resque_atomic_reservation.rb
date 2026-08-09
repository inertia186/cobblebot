require Rails.root.join('app/services/resque_atomic_job_reservation')

module ResqueAtomicReservation
  def reserve
    queues.each do |queue|
      log_with_severity :debug, "Checking #{queue}"
      job = ResqueAtomicJobReservation.call(
        resque: Resque,
        worker: self,
        queue: queue
      )
      if job
        log_with_severity :debug, "Found job on #{queue}"
        return job
      end
    end

    nil
  rescue Exception => error
    log_with_severity :error, "Error reserving job: #{error.inspect}"
    log_with_severity :error, error.backtrace.join("\n")
    raise
  end
end

Resque::Worker.prepend(ResqueAtomicReservation)
