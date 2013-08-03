require 'java_properties'

module CobbleBot
  class Config

    VALID_OPTIONS = %w(config_yaml config).map(&:to_sym)
    VALID_OPTIONS.each do |option|
      attr_accessor option
    end

    def initialize(options = {})
      options.each do |k, v|
        raise "Invalid option specified" unless VALID_OPTIONS.include?(k.to_sym)

        send("#{k}=", v)
      end
      
      if !self.config_yaml.nil? && File.exists?(self.config_yaml)
        self.config ||= YAML.load(File.read(self.config_yaml))
      end

      raise StandardError.new("config not initialized properly") if self.config.nil?
      
      if !self.config['server'].nil?
        if File.directory?(self.config['server']['path'])
          unless File.exists?(server_properties_path)
            raise StandardError.new("expected valid server properties: #{self.config['server']['properties']} in #{self.config['server']['path']}")
          end
        else
          raise StandardError.new("expected valid path to server: #{self.config['server']['path']}")
        end
      end
    end
    
    def server_properties_path
      config['server']['path'] + "/" + config['server']['properties']
    end
    
    def server_properties
      @server_properties ||= JavaProperties::Properties.new(server_properties_path)
    end
  end
end