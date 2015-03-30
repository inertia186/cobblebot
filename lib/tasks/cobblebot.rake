require 'csv'

namespace :cobblebot do
  PLAYER_KEYS = %w(uuid nick last_nick last_ip last_chat last_login_at last_logout_at registered_at vetted_at created_at updated_at)
  LINK_KEYS = %w(url title actor_nick expires_at last_modified_at created_at updated_at)
  
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

    desc 'dump out links to csv'
    task links: :environment do
      data = CSV.generate do |csv|
        csv << LINK_KEYS

        Link.all.find_each do |link|
          row = []
          LINK_KEYS.each do |key|
            case key
            when 'actor_nick'
              if !!link.actor
                row << link.actor.nick
              else
                row << nil
              end
            else
              row << link.send(key)
            end
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
        
    desc 'pump in links from csv'
    task links: :environment do
      CSV.parse(STDIN, headers: true) do |row|
        link_params = {}
        LINK_KEYS.each do |key|
          case key
          when 'actor_nick'
            if (nick = row[key]).present?
              player = Player.any_nick(nick).first
              link_params[:actor] = player
            end
          else
            link_params[key] = row[key]
          end
        end

        Link.create(link_params)
      end
    end
  end
end