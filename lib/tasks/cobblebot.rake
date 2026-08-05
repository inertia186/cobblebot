require 'csv'
# require 'webmock/minitest'

# WebMock.disable_net_connect! # We need to avoid making API calls during import/export.

namespace :cobblebot do
  preference_keys = %w(key value system created_at updated_at)
  
  # Note, SERVER_CALLBACK_KEYS excludes: pretty_pattern last_match pretty_command last_command_output ran_at error_flag_at
  server_callback_keys = %w(
    type name pattern command cooldown enabled system help_doc_key help_doc
    created_at updated_at
  )

  # Note, PLAYER_KEYS excludes shall_update_stats
  player_keys = %w(uuid nick last_nick last_ip last_chat last_chat_at
    last_location last_login_at last_logout_at spam_ratio play_sounds
    biomes_explored may_autolink registered_at vetted_at created_at updated_at
    leave_game deaths mob_kills time_since_death player_kills
  )
  
  # Note, LINK_KEYS use actor_uuid instead of actor_id/actor_type.
  link_keys = %w(
    url title actor_uuid expires_at last_modified_at can_embed created_at
    updated_at
  )
  
  # Note, MESSAGE_KEYS use auhor_uuid instead of author_id/author_type; recipient_uuid instead of recipient_id/recipient_type; parent_uuid to re-link reply_id.
  message_keys = %w(
    uuid type body keywords recipient_term recipient_uuid author_uuid read_at
    deleted_at created_at updated_at parent_uuid
  )
  
  # Note, IP_KEYS use player_uuid instead of player_id.
  ip_keys = %w(address player_uuid origin cc state city created_at)
  
  # Note, MUTE_KEYS use player_uuid instead of player_id; muted_player_uuid instead of muted_player_id.
  mute_keys = %w(player_uuid muted_player_uuid created_at)
  
  # Note, REPUTATION_KEYS use truster_uuid instead of truster_id; trustee_uuid instead of trustee_id.
  reputation_keys = %w(truster_uuid trustee_uuid rate created_at updated_at)
  
  desc 'display the current information of rake'
  task :info do
    puts "You are running rake task in #{Rails.env} environment."
  end

  desc 'checks messages for illegal characters'
  task check_message_encoding: :environment do
    Message.all.map(&:body).each { |text| text.force_encoding('US-ASCII') }
    puts "OK"
  end

  namespace :export do
    desc 'dump out preferences to csv'
    task preferences: :environment do
      data = CSV.generate do |csv|
        csv << preference_keys
        
        Preference.all.find_each do |preference|
          row = []
          preference_keys.each do |key|
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
        csv << server_callback_keys
        
        ServerCallback.all.find_each do |server_callback|
          row = []
          server_callback_keys.each do |key|
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
        csv << player_keys
        
        Player.all.find_each do |player|
          row = []
          player_keys.each do |key|
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
        csv << link_keys

        Link.all.find_each do |link|
          row = []
          link_keys.each do |key|
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
        csv << message_keys
        
        # Note, we do not export types: Message::IrcReply
        exported_message_types = ["Message::Tip", nil, "Message::Topic", "Message::Pvp", "Message::Donation", "Message::Quote"]
        
        Message.where(type: exported_message_types).find_each do |message|
          row = []
          message_keys.each do |key|
            case key
            when 'parent_uuid'
              if message.parent
                row << message.parent.uuid
              else
                row << nil
              end
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

    desc 'dump out ips to csv'
    task ips: :environment do
      data = CSV.generate do |csv|
        csv << ip_keys
        
        Ip.find_each do |ip|
          row = []
          ip_keys.each do |key|
            case key
            when 'player_uuid'
              row << ip.player.uuid if ip.player
            else
              row << ip.send(key)
            end
          end
          csv << row
        end
        
      end

      puts data
    end

    desc 'dump out mutes to csv'
    task mutes: :environment do
      data = CSV.generate do |csv|
        csv << mute_keys
        
        Mute.find_each do |mute|
          row = []
          mute_keys.each do |key|
            case key
            when 'player_uuid'
              row << mute.player.uuid if mute.player
            when 'muted_player_uuid'
              row << mute.muted_player.uuid if mute.muted_player
            else
              row << mute.send(key)
            end
          end
          csv << row
        end
        
      end

      puts data
    end

    desc 'dump out reputations to csv'
    task reputations: :environment do
      data = CSV.generate do |csv|
        csv << reputation_keys
        
        Reputation.find_each do |reputation|
          row = []
          reputation_keys.each do |key|
            case key
            when 'truster_uuid'
              row << reputation.truster.uuid if reputation.truster
            when 'trustee_uuid'
              row << reputation.trustee.uuid if reputation.trustee
            else
              row << reputation.send(key)
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
        preference_keys.each do |key|
          preference_params[key] = row[key]
        end

        Preference.create(preference_params)
      end
    end

    desc 'pump in server callback from csv'
    task server_callbacks: :environment do
      CSV.parse(STDIN, headers: true) do |row|
        server_callback_params = {}
        server_callback_keys.each do |key|
          server_callback_params[key] = row[key]
        end

        ServerCallback.create(server_callback_params)
      end
    end

    desc 'pump in players from csv'
    task players: :environment do
      CSV.parse(STDIN, headers: true) do |row|
        player_params = {}
        player_keys.each do |key|
          player_params[key] = row[key]
        end

        Player.create(player_params)
      end
      
      # Otherwise, this will bog down the worker.
      Player.update_all("shall_update_stats = 'f'")
    end

    desc 'pump in links from csv'
    task links: :environment do
      CSV.parse(STDIN, headers: true) do |row|
        link_params = {skip_populate_from_response: true}
        link_keys.each do |key|
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
        message_keys.each do |key|
          case key
          when 'type'
            if row[key].present?
              message_params[:type] = row[key]
            else
              message_params[:type] = nil
            end
          when 'parent_uuid'
            if (uuid = row[key]).present?
              parent = Message.find_by_uuid uuid
              message_params[:parent] = parent
            end
          when 'recipient_uuid'
            if (uuid = row[key]).present?
              player = Player.find_by_uuid uuid
              message_params[:recipient] = player
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

    desc 'pump in ips from csv'
    task ips: :environment do
      CSV.parse(STDIN, headers: true) do |row|
        ip_params = {}
        ip_keys.each do |key|
          case key
          when 'player_uuid'
            if (uuid = row[key]).present?
              player = Player.find_by_uuid uuid
              ip_params[:player] = player
            end
          else
            ip_params[key] = row[key]
          end
        end

        next if ip_params[:player].nil?
        ip_params[:no_cc_lookup] = true
        Ip.create(ip_params)
      end
    end

    desc 'pump in mutes from csv'
    task mutes: :environment do
      CSV.parse(STDIN, headers: true) do |row|
        mute_params = {}
        mute_keys.each do |key|
          case key
          when 'player_uuid'
            if (uuid = row[key]).present?
              player = Player.find_by_uuid uuid
              mute_params[:player] = player
            end
          when 'muted_player_uuid'
            if (uuid = row[key]).present?
              player = Player.find_by_uuid uuid
              mute_params[:muted_player] = player
            end
          else
            mute_params[key] = row[key]
          end
        end

        next if mute_params[:player].nil? || mute_params[:muted_player].nil?
        Mute.create(mute_params)
      end
    end

    desc 'pump in reputations from csv'
    task reputations: :environment do
      CSV.parse(STDIN, headers: true) do |row|
        reputation_params = {}
        reputation_keys.each do |key|
          case key
          when 'truster_uuid'
            if (uuid = row[key]).present?
              truster = Player.find_by_uuid uuid
              reputation_params[:truster] = truster
            end
          when 'trustee_uuid'
            if (uuid = row[key]).present?
              trustee = Player.find_by_uuid uuid
              reputation_params[:trustee] = trustee
            end
          else
            reputation_params[key] = row[key]
          end
        end

        next if reputation_params[:truster].nil? || reputation_params[:trustee].nil?
        Reputation.create(reputation_params)
      end
    end
  end
end
