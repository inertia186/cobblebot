module Detectable
  extend Commandable

  PROJECTILES = %w(Arrow Fireball SmallFireball WitherSkull ThrownExpBottle ThrownPotion Snowball)
  TROUBLE_ENTITIES = [
    ['Item', '{Item:{id:minecraft:egg}}', 5],
    
    # These are zombies that have naturally picked up items that prevent them
    # from naturally despawning.
    ['Zombie', '{Equipment:[0:{id:"minecraft:egg"}]}', 5],
    ['Zombie', '{Equipment:[0:{id:"minecraft:slime_ball"}]}', 5],
    ['Zombie', '{Equipment:[0:{id:"minecraft:rotten_flesh"}]}', 5],
    ['Zombie', '{Equipment:[0:{id:"minecraft:string"}]}', 5],
    
    # These are mobs that are probably building up in a mob grinder.  The more
    # damaged, the more likely they'll be swept.
    ['Zombie', '{Health:4s}', 1],
    ['Zombie', '{Health:3s}', 2],
    ['Zombie', '{Health:2s}', 3],
    ['Zombie', '{Health:1s}', 4],
    ['Skeleton', '{Health:4s}', 1],
    ['Skeleton', '{Health:3s}', 2],
    ['Skeleton', '{Health:2s}', 3],
    ['Skeleton', '{Health:1s}', 4],
    ['Blaze', '{Health:4s}', 1],
    ['Blaze', '{Health:3s}', 2],
    ['Blaze', '{Health:2s}', 3],
    ['Blaze', '{Health:1s}', 4],
    ['Creeper', '{Health:4s}', 1],
    ['Creeper', '{Health:3s}', 2],
    ['Creeper', '{Health:2s}', 3],
    ['Creeper', '{Health:1s}', 4],
    ['Enderman', '{Health:4s}', 1],
    ['Enderman', '{Health:3s}', 2],
    ['Enderman', '{Health:2s}', 3],
    ['Enderman', '{Health:1s}', 4],
    ['Spider', '{Health:4s}', 1],
    ['Spider', '{Health:3s}', 2],
    ['Spider', '{Health:2s}', 3],
    ['Spider', '{Health:1s}', 4],
    ['CaveSpider', '{Health:4s}', 1],
    ['CaveSpider', '{Health:3s}', 2],
    ['CaveSpider', '{Health:2s}', 3],
    ['CaveSpider', '{Health:1s}', 4]
  ]
  PASSIVE_MOB_TYPES = %w(Bat Chicken Cow MushroomCow Pig Rabbit Sheep Squid Villager VillagerGolem Wolf Ocelot EntityHorse SnowMan)
  HOSTILE_MOB_TYPES = %w(Blaze Creeper ElderGuardian Endermite Ghast Guardian MagmaCube Silverfish Skeleton Slime Spider CaveSpider Witch WitherSkeleton Zombie EnderDragon WitherBoss Shulker Giant Enderman PigZombie)
  ALL_MOB_TYPES = PASSIVE_MOB_TYPES + HOSTILE_MOB_TYPES
  
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    def detect_spam(nick, message)
      # Don't bother to check for spam if there's only one player on.
      return if ServerQuery.numplayers.to_i < 2
    
      server_log = "#{ServerProperties.path_to_server}/logs/latest.log"
      lines = IO.readlines(server_log)
      lines = lines[([-(lines.size - 1), -50].max)..-1]
      return if lines.nil?
    
      player = Player.find_by_nick(nick)
      col = if player.nil? || player.new? || !player.above_exploration_threshold?
        7
      else
        20
      end
    
      regexp = player_input_regexp(nick, message, col)
      all = []

      lines.each do |line|
        words = line.split(' ')[4..-1]
        unless words.nil?
          sample = words.join(' ').downcase
          all << sample[0..[sample.size - 1, col].min] if regexp.match(line)
        end
      end

      return "No spam detected for #{nick}." if all.size == 0
    
      ratio = all.uniq.size.to_f / all.size.to_f
      handle_spam(nick, ratio)

      if !!player
        unless player.spam_ratio == ratio
          player.update_column(:spam_ratio, ratio) # no AR callbacks
        end
      
        return player
      end
    end
    
    def detectable_reset
      @last_detect_frozen_projectiles = nil
      @last_detect_trouble_entities = nil
    end
    
    def detect_frozen_projectiles
      if @last_detect_frozen_projectiles.nil?
        @last_detect_frozen_projectiles = Time.now
      elsif 15.minutes.ago > @last_detect_frozen_projectiles
        detectable_reset and return
      else
        return
      end
      
      entities = []
      
      PROJECTILES.each do |type|
        entities += Server.entity_data(selector: "@e[type=#{type}]")
      end
      
      return "Not evaluating frozen projectiles." unless entities.any?

      handle_frozen_projectiles
      
      "Evaluating frozen projectiles: #{entities.size}"
    end

    def detect_trouble_entities
      if @last_detect_trouble_entities.nil?
        @last_detect_trouble_entities = Time.now
      elsif 15.minutes.ago > @last_detect_trouble_entities
        detectable_reset and return
        return
      else
        return
      end
      
      entities = []
      
      TROUBLE_ENTITIES.map { |data| data[0] }.uniq do |type|
        entities += Server.entity_data(selector: "@e[type=#{type}]")
      end
      
      return entities unless entities.any?

      handle_trouble_entities
      
      "Evaluating entities: #{entities.size}"
    end
    
    def detect_pvp(message)
      if message =~ /was.*by/
        loser_nick = message.split(' was').first
        loser = Player.find_by_nick(loser_nick)
        winner_nick = message.split('by ').last.split(' ').first
        winner = Player.find_by_nick(winner_nick)
      elsif message =~ /was killed trying to hurt/
        loser_nick = message.split(' ').first
        loser = Player.find_by_nick(loser_nick)
        winner_nick = message.split(' ').last
        winner = Player.find_by_nick(winner_nick)
      elsif message =~ /was burnt to a crisp/
        loser_nick = message.split(' ').first
        loser = Player.find_by_nick(loser_nick)
        winner_nick = message.split(' ').last
        winner = Player.find_by_nick(winner_nick)
      elsif message =~ /tried to swim in lava/
        loser_nick = message.split(' ').first
        loser = Player.find_by_nick(loser_nick)
        winner_nick = message.split(' ').last
        winner = Player.find_by_nick(winner_nick)
      end

      return if loser.nil? || winner.nil?
      
      winner.pvp_wins.create(body: message, recipient: loser)
    end
  private
    def player_input_regexp(nick, message, col)
      %w( [ ] \\ ^ $ . | ? * + \( \)).each do |c|
        message.gsub!(c, "\\#{c}")
      end

      # FIXME If last character of message substring is a regex escape character, include the next character.
      s = message[0..[message.size - 1, col].min]
  
      chat_regex = %r(: \<#{nick}\> .*#{s}.*)i
      emote_regex = %r(: \* #{nick} .*#{s}.*)i
      Regexp.union([chat_regex, emote_regex])
    end
    
    def handle_spam(nick, ratio)
      if ratio <= 0.2 && ratio > 0.126
        say(nick, 'Warning, spam detected.', color: 'yellow', as: 'Server')
      elsif ratio <= 0.126 && ratio > 0.1
        say(nick, 'Warning, spam detected.', color: 'red', as: 'Server')
        play_sound(nick, 'oot_navi_listen')
      elsif ratio <= 0.1
        @kicked_for_spam ||= []

        if @kicked_for_spam.include? nick
          player = Player.find_by_nick(nick)
          
          player.ban!('annoying chat', announce: true) and return if !!player && player.new?
        end
        
        kick(nick, "Spammy ratio #{ratio}")
        @kicked_for_spam << nick
      end
    end
    
    def on_junk(&block)
      if !!Preference.is_junk_objective_timestamp
        is_junk_objective_timestamp = Preference.is_junk_objective_timestamp.to_i
        timestamp = Time.at(is_junk_objective_timestamp)
      else
        execute 'scoreboard objectives add isJunk dummy'
        timestamp = Time.now
        Preference.is_junk_objective_timestamp = timestamp.to_i
      end

      yield
      
      if 24.hours.ago > timestamp
        # We don't want the scoreboard to grow and grow.
        execute 'scoreboard objectives remove isJunk'
        Preference.is_junk_objective_timestamp = nil
      end
    end
    
    # This method looks for all projectiles and markes them as junk.  Then, it
    # allows them to land.  Any projectiles still loaded after waiting will be
    # swept.  This will (hopefully) eliminate projectiles that have been loaded
    # that are just floating in one place.
    def handle_frozen_projectiles
      on_junk do
        PROJECTILES.each do |type|
          # Mark
          execute "scoreboard players add @e[type=#{type}] isJunk 1"
        end

        PROJECTILES.each do |type|
          # Sweep only projectiles that have been marked more than once.
          execute "kill @e[type=#{type},score_isJunk_min=2]"
        end
      end
    end

    # This method looks for mobs that, for example cannot despawn due to their
    # held equipment.  For some situations, only certain types of equipment
    # qualify, like eggs and rotten flesh.  If a mob is marked as junk, it is
    # teleported to the void to keep them from dropping the same problem
    # equipment for other mobs to pick up.
    def handle_trouble_entities
      on_junk do
        TROUBLE_ENTITIES.each do |data|
          # Mark
          execute "scoreboard players add @e[type=#{data[0]}] isJunk #{data[2]} #{data[1]}"
        end
        
        TROUBLE_ENTITIES.map { |data| data[0] }.uniq.each do |type| 
          # Try to limit pathfinding for mobs in grinders.
          execute "entitydata @e[type=#{type},score_isJunk_min=1] {NoAI:1}"
          execute "entitydata @e[type=#{type},score_isJunk_min=2] {NoAI:1}"
          execute "entitydata @e[type=#{type},score_isJunk_min=3] {NoAI:1}"
          execute "entitydata @e[type=#{type},score_isJunk_min=4] {NoAI:1}"
          
          # This is useful for debugging and troubleshooting.  It allows the
          # log to record which mobs were removed near which player.
          execute "execute @e[type=#{type},score_isJunk_min=5] ~ ~ ~ playsound random.pop master @a[r=32] ~ ~ ~ 1 1"
          execute "execute @e[type=#{type},score_isJunk_min=5] ~ ~ ~ particle cloud ~ ~ ~ 0 0 0 0"
          
          # Sweep
          # We use /tp instead of /kill to limit new drops from mobs.
          execute "tp @e[type=#{type},score_isJunk_min=5] ~ ~-1000 ~"
        end
      end
    end
  end
end
