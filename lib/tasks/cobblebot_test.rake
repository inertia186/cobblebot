namespace :cobblebot do
  namespace :test do
    desc 'Run the complete test suite with an unmerged 75% coverage floor'
    task :coverage do
      ENV['COBBLEBOT_COVERAGE_GATE'] = '1'
      Rake::Task['test'].invoke
    end
  end
end
