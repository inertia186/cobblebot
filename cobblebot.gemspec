Gem::Specification.new do |s|
  s.name = 'cobblebot'
  s.version = '0.0.1'
  s.date = '2013-06-22'
  s.summary = "Minecraft Server Automation and Library"
  s.description = "A gem to interact with a Minecraft server."
  s.authors = ["Anthony Martin"]
  s.email = 'cobblebot@martin-studio.com'
  s.files = ["lib/cobblebot.rb"]
  s.homepage = 'https://github.com/inertia186/cobblebot'

  s.add_dependency "java_properties", "~> 0.0.4"
  s.add_dependency "minecraft-query", "~> 0.0.1"
end
