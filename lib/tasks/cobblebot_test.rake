namespace :cobblebot do
  namespace :test do
    desc 'Run the complete serial suite with an unmerged 75% coverage floor'
    task :coverage do
      ENV['COBBLEBOT_COVERAGE_GATE'] = '1'
      ENV['HELL_ENABLED'] = '0'
      Rake::Task['test'].invoke
    end
  end
end
