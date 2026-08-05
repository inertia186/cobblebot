require Rails.root.join('app/services/resque_configuration')

ResqueConfiguration.load(environment: Rails.env).apply
