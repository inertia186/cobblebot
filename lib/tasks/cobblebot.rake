require 'csv'

namespace :cobblebot do
  PLAYER_KEYS = %w(uuid nick last_nick last_ip last_chat last_login_at last_logout_at registered_at vetted_at created_at updated_at)
  
  desc 'display the current information of rake'
  task :info do
    puts "You are running rake task in #{Rails.env} environment."
  end

  namespace :export do
    desc 'dump out players to csv'
    task players: :environment do
      data = CSV.generate do |csv|
        csv << PLAYER_KEYS
        
        Player.all.find_each do |player|
          row = []
          PLAYER_KEYS.each do |key|
            row << player.send(key)
          end
          csv << row
        end
        
      end

      puts data
    end
  end
  
  namespace :import do
    desc 'pump in players from csv'
    task players: :environment do
      CSV.parse(STDIN, headers: true) do |row|
        player_params = {}
        PLAYER_KEYS.each do |key|
          player_params[key] = row[key]
        end

        Player.create(player_params)
      end
    end
  end
private
  def dump_csv ( record, keys )
    keys.each do |key|
      value = record.send(key).to_s
      if value =~ /([",])/
        print "\"#{value.gsub(/([",])/, "\\#{$1}")}\""
      else
        print value
      end
      print ',' unless key == keys.last
    end
    
    print "\n"
  end
end