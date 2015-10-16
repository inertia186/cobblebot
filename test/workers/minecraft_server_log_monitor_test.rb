require 'test_helper'

class MinecraftServerLogMonitorTest < ActiveSupport::TestCase
  def setup
    Preference.path_to_server = "#{Rails.root}/tmp"
  end
  
  def test_perform
    adapter_type = ActiveRecord::Base.connection.adapter_name.downcase.to_sym
    status_select = case adapter_type
    when :sqlite
      monitor = Thread.start do
        MinecraftServerLogMonitor.perform(debug: true, "max_ticks" => 1)
      end
      skip 'Took too long to run.' unless monitor.join 5
    when :postgresql
      MinecraftServerLogMonitor.perform(debug: true, "max_ticks" => 1)
    else raise NotImplementedError, "Unknown adapter type '#{adapter_type}'"
    end
  end
end
