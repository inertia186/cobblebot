require 'csv'

namespace :cobblebot do
  PREFERENCE_KEYS = %w(key value system created_at updated_at)
  SERVER_CALLBACK_KEYS = %w(name pattern match_scheme command cooldown enabled system created_at updated_at)
  PLAYER_KEYS = %w(uuid nick last_nick last_ip last_chat last_login_at last_logout_at registered_at vetted_at created_at updated_at)
  LINK_KEYS = %w(url title actor_uuid expires_at last_modified_at created_at updated_at)
  MESSAGE_KEYS = %w(type body keywords recipient_term recipient_uuid author_uuid read_at created_at updated_at)
  
  desc 'display the current information of rake'
  task :info do
    puts "You are running rake task in #{Rails.env} environment."
  end

  namespace :export do
    desc 'dump out preferences to csv'
    task preferences: :environment do
      data = CSV.generate do |csv|
        csv << PREFERENCE_KEYS
        
        Preference.all.find_each do |preference|
          row = []
          PREFERENCE_KEYS.each do |key|
            row << preference.send(key)
          end
          csv << row
        end
        
      end

      puts data
    end

    desc 'dump out server callbacks to csv'
    task server_callbacks: :environment do
      data = CSV.generate do |csv|
        csv << SERVER_CALLBACK_KEYS
        
        ServerCallback.all.find_each do |server_callback|
          row = []
          SERVER_CALLBACK_KEYS.each do |key|
            row << server_callback.send(key)
          end
          csv << row
        end
        
      end

      puts data
    end

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
            when 'actor_uuid'
              if !!link.actor
                row << link.actor.uuid
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

    desc 'dump out messages to csv'
    task messages: :environment do
      data = CSV.generate do |csv|
        csv << MESSAGE_KEYS
        
        Message.where.not(type: 'Message::IrcReply').find_each do |message|
          row = []
          MESSAGE_KEYS.each do |key|
            case key
            when 'recipient_uuid'
              if !!message.recipient
                row << message.recipient.uuid
              else
                row << nil
              end
            when 'author_uuid'
              if !!message.author
                row << message.author.uuid
              else
                row << nil
              end
            else
              row << message.send(key)
            end
          end
          csv << row
        end
        
      end

      puts data
    end
  end
  
  namespace :import do
    desc 'pump in preferences from csv'
    task preferences: :environment do
      CSV.parse(STDIN, headers: true) do |row|
        preference_params = {}
        PREFERENCE_KEYS.each do |key|
          preference_params[key] = row[key]
        end

        Preference.create(preference_params)
      end
    end

    desc 'pump in server callback from csv'
    task server_callbacks: :environment do
      CSV.parse(STDIN, headers: true) do |row|
        server_callback_params = {}
        SERVER_CALLBACK_KEYS.each do |key|
          server_callback_params[key] = row[key]
        end

        ServerCallback.create(server_callback_params)
      end
    end

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
          when 'actor_uuid'
            if (uuid = row[key]).present?
              player = Player.find_by_uuid uuid
              link_params[:actor] = player
            end
          else
            link_params[key] = row[key]
          end
        end

        Link.create(link_params)
      end
    end

    desc 'pump in messages from csv'
    task messages: :environment do
      CSV.parse(STDIN, headers: true) do |row|
        message_params = {}
        MESSAGE_KEYS.each do |key|
          case key
          when 'recipient_uuid'
            if (uuid = row[key]).present?
              player = Player.find_by_uuid uuid
              message_params[:recipeint] = player
            end
          when 'author_uuid'
            if (uuid = row[key]).present?
              player = Player.find_by_uuid uuid
              message_params[:author] = player
            end
          else
            message_params[key] = row[key]
          end
        end

        Message.create(message_params)
      end
    end
  end
end