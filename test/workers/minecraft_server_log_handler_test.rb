require 'test_helper'

class MinecraftServerLogHandlerTest < ActiveSupport::TestCase
  def setup
    Preference.path_to_server = "#{Rails.root}/tmp"

    stub_request(:head, "https://gist.github.com/inertia186/5002463").
      to_return(status: 200)
    stub_request(:get, "https://gist.github.com/inertia186/5002463").
      to_return(status: 200)
    stub_request(:get, "https://www.youtube.com/watch?v=GVgMzKMgNxw").
      to_return(status: 200)
    stub_request(:get, "https://www.youtube.com/watch?v=OdSkx7QmO7k").
      to_return(status: 200)
    stub_request(:get, "http://www.mojang.com/").
      to_return(status: 200)
  end

  def test_check_version
    assert_callback_ran 'Check Version' do
      ServerCallback::AnyPlayerEntry.handle('[15:17:25] [Server thread/INFO]: <inertia186> @server version')
    end
  end

  def test_not_check_version
    refute_callback_ran 'Check Version' do
      ServerCallback::AnyPlayerEntry.handle('[15:17:25] [Server thread/INFO]: <inertia186> test')
    end
  end

  def test_playercheck
    assert_callback_ran 'Player Check' do
      ServerCallback::AnyPlayerEntry.handle('[08:23:03] [Server thread/INFO]: <inertia186> @server playercheck inertia186')
    end
  end

  def test_autolink
    cobblebot = Link.where(url: 'http://github.com/inertia186/cobblebot').first
    cobblebot.update_attribute(:expires_at, 2.days.from_now)
    
    assert_no_difference -> { Link.count }, 'did not expect new link record' do
      assert_callback_ran 'Autolink' do
        ServerCallback::AnyPlayerEntry.handle('[08:23:03] [Server thread/INFO]: <inertia186> http://github.com/inertia186/cobblebot')
      end
    end
  end

  def test_autolink_disabled
    player = Player.find_by_nick('inertia186')

    player.update_attribute(:may_autolink, false)    
    assert_no_difference -> { player.links.count }, 'did not expect new link record' do
      assert_callback_ran 'Autolink' do
        ServerCallback::AnyPlayerEntry.handle('[08:23:03] [Server thread/INFO]: <inertia186> https://www.youtube.com/watch?v=OdSkx7QmO7k')
      end
    end

    player.update_attribute(:may_autolink, true)
    assert_difference -> { player.links.count }, 1, 'expect new link record' do
      assert_callback_ran 'Autolink' do
        ServerCallback::AnyPlayerEntry.handle('[08:23:03] [Server thread/INFO]: <inertia186> https://www.youtube.com/watch?v=OdSkx7QmO7k')
      end
    end
  end

  def test_player_authenticated
    def Server.entity_data(options = {selector: "@e[c=1]", near_player: nil, radius: 0})
      return ['Frozen Projectile']
    end

    refute Preference.is_junk_objective_timestamp, "did not expect is_junk_objective_timestamp, it was: #{Preference.is_junk_objective_timestamp}"
    
    assert_difference -> { Player.count }, 1, 'expect new player' do
      assert_callback_ran 'Player Authenticated' do
        ServerCallback::ServerEntry.handle('[14:12:05] [User Authenticator #23/INFO]: UUID of player xXPlayerXx is f6ddf946-f162-8d48-a21b-ac00929fb848')
      end
    end

    assert Preference.is_junk_objective_timestamp, 'expect is_junk_objective_timestamp'

    assert_no_difference -> { Player.count }, 'did not expect new player' do
      ServerCallback::ServerEntry.handle('[14:12:05] [User Authenticator #23/INFO]: UUID of player xXPlayerXx is f6ddf946-f162-8d48-a21b-ac00929fb848')
    end

    player = Player.last
    assert_nil player.last_nick, 'expect last_nick to be nil'

    assert_no_difference -> { Player.count }, 'did not expect new player' do
      ServerCallback::ServerEntry.handle('[14:12:05] [User Authenticator #23/INFO]: UUID of player yYPlayerYy is f6ddf946-f162-8d48-a21b-ac00929fb848')
    end

    player.reload
    assert_equal player.nick, 'yYPlayerYy', 'expected nick to update to new nick'
    refute_nil player.last_nick, 'expect last_nick to update'
    refute_equal player.nick, player.last_nick, 'expect last_nick not to be equal to nick'

    assert_no_difference -> { Player.count }, 'did not expect new player' do
      ServerCallback::ServerEntry.handle('[14:12:05] [User Authenticator #23/INFO]: UUID of player zZPlayerZz is f6ddf946-f162-8d48-a21b-ac00929fb848')
    end

    player.reload
    assert_equal player.nick, 'zZPlayerZz', 'expected nick to update to new nick'
    assert_equal player.last_nick, 'yYPlayerYy', 'expect last_nick to update'
  end

  def test_player_authenticated_is_junk_objective_timestamp
    def Server.entity_data(options = {selector: "@e[c=1]", near_player: nil, radius: 0})
      return ['Frozen Projectile']
    end

    refute Preference.is_junk_objective_timestamp, "did not expect is_junk_objective_timestamp, it was: #{Preference.is_junk_objective_timestamp}"
    ServerCallback::ServerEntry.handle('[14:12:05] [User Authenticator #23/INFO]: UUID of player xXPlayerXx is f6ddf946-f162-8d48-a21b-ac00929fb848')
    assert Preference.is_junk_objective_timestamp, 'expect is_junk_objective_timestamp'
    travel 2.days do
      ServerCommand.send(:handle_frozen_projectiles)
      refute Preference.is_junk_objective_timestamp, "did not expect is_junk_objective_timestamp, it was: #{Preference.is_junk_objective_timestamp}"
    end
  end
  
  def test_message_of_the_day
    assert_callback_ran 'Message of the Day' do
      ServerCallback::ServerEntry.handle('[08:57:14] [Server thread/INFO]: inertia186 joined the game')
    end
  end

  def test_latest_player_chat
    player = Player.find_by_nick('inertia186')
    callback = ServerCallback.find_by_name('Latest Player Chat')
    
    assert_callback_ran callback do
      ServerCallback::AnyPlayerEntry.handle('[15:04:50] [Server thread/INFO]: <inertia186> Hello!')
    end

    assert_equal 'Hello!', player.reload.last_chat, 'did not expect nil last_chat'

    player.update_attribute(:last_chat, nil)
    
    assert_callback_ran callback do
      ServerCallback::AnyPlayerEntry.handle('[15:04:50] [Server thread/INFO]: <inertia186> "quoted"')
    end
  
    assert_equal '"quoted"', player.reload.last_chat, 'did not expect nil last_chat'

    player.update_attribute(:last_chat, nil)
    
    assert_callback_ran callback do
      ServerCallback::AnyPlayerEntry.handle('[15:04:50] [Server thread/INFO]: <inertia186> #{0}')
    end

    refute_nil player.reload.last_chat, 'did not expect nil last_chat'

    player.update_attribute(:last_chat, nil)

    assert_callback_ran callback do
      ServerCallback::AnyPlayerEntry.handle('[15:04:50] [Server thread/INFO]: <inertia186> #{1/0}')
    end

    refute_nil player.reload.last_chat, 'did not expect nil last_chat'
  end

  def test_latest_player_ip
    assert_callback_ran 'Latest Player IP' do
      ServerCallback::ServerEntry.handle('[17:45:49] [Server thread/INFO]: inertia186[/127.0.0.1:63640] logged in with entity id 7477 at (15.11891680919476, 63.0, 296.4194632969733)')
    end
    refute_nil Player.find_by_nick('inertia186').last_ip, 'did not expect nil last_ip'
  end

  def test_player_logged_out
    callback = ServerCallback.find_by_name('Player Logged Out')
    
    assert_callback_ran callback do
      ServerCallback::ServerEntry.handle('[15:29:35] [Server thread/INFO]: inertia186 lost connection: TextComponent{text=\'Disconnected\', siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}')
    end

    refute_nil Player.find_by_nick('inertia186').last_logout_at, 'did not expect nil last_chat'

    # Variations
    
    assert_callback_ran callback do
      ServerCallback::ServerEntry.handle('[11:44:45] [Server thread/INFO]: inertia186 lost connection: TranslatableComponent{key=\'disconnect.timeout\', args=[], siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}')
    end

    assert_callback_ran callback do
      ServerCallback::ServerEntry.handle('[19:27:46] [Server thread/INFO]: inertia186 lost connection: TranslatableComponent{key=\'disconnect.genericReason\', args=[Internal Exception: java.io.IOException: Connection reset by peer], siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}')
    end

    assert_callback_ran callback do
      ServerCallback::ServerEntry.handle('[18:28:53] [Server thread/INFO]: blackhat186 lost connection: TextComponent{text=\'Flying is not enabled on this server\', siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}')
    end

    assert_callback_ran callback do
      ServerCallback::ServerEntry.handle('[10:21:31] [Server thread/INFO]: inertia186 lost connection: TextComponent{text=\'You logged in from another location\', siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}')
    end

    assert_callback_ran callback do
      ServerCallback::ServerEntry.handle('[00:03:37] [Server thread/INFO]: inertia186 lost connection: TextComponent{text=\'You have been idle for too long!\', siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}')
    end

    assert_callback_ran callback do
      ServerCallback::ServerEntry.handle('[03:05:08] [Server thread/INFO]: inertia186 lost connection: TextComponent{text=\'Have a Nice Day!\', siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}')
    end

    assert_callback_ran callback do
      ServerCallback::ServerEntry.handle('[08:01:11] [Server thread/INFO]: jackass186 lost connection: TextComponent{text=\'disconnect.spam\', siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}')
    end

    assert_callback_ran callback do
      ServerCallback::ServerEntry.handle('[11:11:38] [Server thread/INFO]: jackass186 lost connection: TextComponent{text=\'Kicked by an operator.\', siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}')
    end

    # Ignore

    callback.update_attribute(:ran_at, nil)
    ServerCallback::ServerEntry.handle('[15:12:31] [Server thread/INFO]: /127.0.0.1:50472 lost connection: Failed to verify username!')
    refute callback.reload.error_flag_at, callback.last_command_output
    assert_nil callback.reload.ran_at, 'expect nil ran_at'

    ServerCallback::ServerEntry.handle('[19:06:04] [Server thread/INFO]: /127.0.0.1:52748 lost connection: Internal Exception: io.netty.handler.codec.DecoderException: The received string length is longer than maximum allowed (22 > 16)')
    refute callback.reload.error_flag_at, callback.last_command_output
    assert_nil callback.reload.ran_at, 'expect nil ran_at'

    ServerCallback::ServerEntry.handle('[09:59:11] [Server thread/INFO]: com.mojang.authlib.GameProfile@77550cf1[id=<null>,name=inertia186,properties={},legacy=false] (/127.0.0.1:56157) lost connection: Authentication servers are down. Please try again later, sorry!')
    refute callback.reload.error_flag_at, callback.last_command_output
    assert_nil callback.reload.ran_at, 'expect nil ran_at'

    ServerCallback::ServerEntry.handle('[13:28:33] [Server thread/INFO]: com.mojang.authlib.GameProfile@22ad3285[id=<null>,name=inertia186,properties={},legacy=false] (/127.0.0.1:53908) lost connection: Timed out')
    refute callback.reload.error_flag_at, callback.last_command_output
    assert_nil callback.reload.ran_at, 'expect nil ran_at'

    ServerCallback::ServerEntry.handle('[00:22:23] [Server thread/INFO]: com.mojang.authlib.GameProfile@622ca134[id=<null>,name=inertia186,properties={},legacy=false] (/127.0.0.1:15274) lost connection: Internal Exception: java.io.IOException: Connection reset by peer')
    refute callback.reload.error_flag_at, callback.last_command_output
    assert_nil callback.reload.ran_at, 'expect nil ran_at'

    ServerCallback::ServerEntry.handle('[17:01:27] [Server thread/INFO]: com.mojang.authlib.GameProfile@e509a8b[id=ffffffff-ffff-ffff-ffff-ffffffffffff,name=blackhat186,properties={textures=[com.mojang.authlib.properties.Property@6688ce2c]},legacy=false] (/127.0.0.1:57235) lost connection: You are banned from this server!')
    refute callback.reload.error_flag_at, callback.last_command_output
    assert_nil callback.reload.ran_at, 'expect nil ran_at'
  end
  
  def test_prediction
    callback = ServerCallback.find_by_name('Predict')
    
    assert_callback_ran callback do
      ServerCallback::ServerEntry.handle('[18:45:22] [Server thread/INFO]: com.mojang.authlib.GameProfile@4835d4bb[id=<null>,name=inertia186,properties={},legacy=false] (/127.0.0.1:61582) lost connection: Disconnected')
    end
    
    assert callback.last_command_output
  end
  
  def test_autosync
    assert_callback_ran 'Autosync' do
      ServerCallback::ServerEntry.handle('[19:23:22] [Server thread/WARN]: inertia186 moved wrongly!')
    end
  end

  def test_search_replace
    assert_callback_ran 'Search Replace' do
      ServerCallback::AnyPlayerEntry.handle('[15:05:10] [Server thread/INFO]: <inertia186> %s/axe/sword/')
    end
  end
  
  def test_random_tip
    assert_callback_ran 'Random Tip' do
      ServerCallback::AnyPlayerEntry.handle('[15:05:10] [Server thread/INFO]: <inertia186> @server tip')
    end
    # Make sure the "pretend" option reaches the callback for simulated chat.
    assert_equal '@server tip', Player.find_by_nick('inertia186').last_chat, 'expect last chat to be @server tip'
  end
  
  def test_random_tip_server
    Message::Tip.where.not("body LIKE 'server%'").update_all('read_at = CURRENT_TIMESTAMP')
    assert_callback_ran 'Random Tip' do
      ServerCallback::AnyPlayerEntry.handle('[15:05:10] [Server thread/INFO]: <inertia186> @server tip server')
    end
    # Make sure the "pretend" option reaches the callback for simulated chat.
    assert_equal '@server tip server', Player.find_by_nick('inertia186').last_chat, 'expect last chat to be @server tip server'
  end
  
  def test_random_tip_herobrine
    Message::Tip.where.not("body LIKE 'herobrine%'").update_all('read_at = CURRENT_TIMESTAMP')
    assert_callback_ran 'Random Tip' do
      ServerCallback::AnyPlayerEntry.handle('[15:05:10] [Server thread/INFO]: <inertia186> @server tip herobrine')
    end
    # Make sure the "pretend" option reaches the callback for simulated chat.
    assert_equal '@server tip herobrine', Player.find_by_nick('inertia186').last_chat, 'expect last chat to be @server tip herobrine'
  end
  
  def test_random_tip_slap
    def Server.player_nicks(selector = nil)
      ['inertia186'] # in case the tip has a selector
    end
    
    Message::Tip.where.not("body LIKE 'slap%'").update_all('read_at = CURRENT_TIMESTAMP')
    assert_callback_ran 'Random Tip' do
      ServerCallback::AnyPlayerEntry.handle('[15:05:10] [Server thread/INFO]: <inertia186> @server tip slap')
    end
    # Make sure the "pretend" option reaches the callback for simulated chat.
    assert_equal '@server tip slap', Player.find_by_nick('inertia186').last_chat, 'expect last chat to be @server tip slap'
  end
  
  def test_random_tip_mfw
    Message::Tip.where.not("body LIKE '>%'").update_all('read_at = CURRENT_TIMESTAMP')
    assert_callback_ran 'Random Tip' do
      ServerCallback::AnyPlayerEntry.handle('[15:05:10] [Server thread/INFO]: <inertia186> @server tip >')
    end
    # Make sure the "pretend" option reaches the callback for simulated chat.
    assert_equal '@server tip >', Player.find_by_nick('inertia186').last_chat, 'expect last chat to be @server tip >'
  end

  def test_random_got_nothin
    Message::Tip.update_all('read_at = CURRENT_TIMESTAMP')
    assert_callback_ran 'Random Tip' do
      ServerCallback::AnyPlayerEntry.handle('[15:05:10] [Server thread/INFO]: <inertia186> @server tip')
      ServerCallback::AnyPlayerEntry.handle('[15:05:10] [Server thread/INFO]: <inertia186> @server tip')
      ServerCallback::AnyPlayerEntry.handle('[15:05:10] [Server thread/INFO]: <inertia186> @server tip')
    end
    # Make sure the "pretend" option reaches the callback for simulated chat.
    assert_equal '@server tip', Player.find_by_nick('inertia186').last_chat, 'expect last chat to be @server tip'
  end
  
  def test_add_tip
    assert_difference -> { Message::Tip.count }, 1, 'expect new tip' do
      assert_callback_ran 'Add Tip' do
        ServerCallback::AnyPlayerEntry.handle('[15:05:10] [Server thread/INFO]: <inertia186> @server addtip This is a tip.')
      end
    end
  end
  
  def test_add_tip_with_link
    assert_difference -> { Link.count }, 1, 'expect new link' do
      assert_difference -> { Message::Tip.count }, 1, 'expect new tip' do
        assert_callback_ran 'Add Tip' do
          ServerCallback::AnyPlayerEntry.handle('[15:05:10] [Server thread/INFO]: <inertia186> @server addtip https://www.youtube.com/watch?v=GVgMzKMgNxw')
        end
      end
    end

    assert_equal 'https://www.youtube.com/watch?v=GVgMzKMgNxw', Message::Tip.last.keywords, 'expect url as title copied into tip keywords (because stub_request has no body to get the real title)'
  end
  
  def test_slap
    assert_callback_ran 'Slap' do
      ServerCallback::AnyPlayerEntry.handle('[15:05:10] [Server thread/INFO]: <inertia186> @server slap Dinnerbone')
    end
    # Make sure the "pretend" option reaches the callback for simulated chat.
    assert_equal '@server slap Dinnerbone', Player.find_by_nick('inertia186').last_chat, 'expect last chat to be @server slap Dinnerbone'
  end
  
  def test_slap_no_target
    assert_callback_ran 'Slap' do
      ServerCallback::AnyPlayerEntry.handle('[15:05:10] [Server thread/INFO]: <inertia186> @server slap')
    end
    # Make sure the "pretend" option reaches the callback for simulated chat.
    assert_equal '@server slap', Player.find_by_nick('inertia186').last_chat, 'expect last chat to be @server slap'
  end
  
  def test_spam_detect
    MinecraftServerLogHandler.handle '[14:12:05] [User Authenticator #23/INFO]: UUID of player xXPlayerXx is f6ddf946-f162-8d48-a21b-ac00929fb848'
    MinecraftServerLogHandler.handle "[08:33:03] [User Authenticator #23/INFO]: UUID of player GracieBoo is a5077378-81eb-4215-96f9-16679e3401cb"

    def Server.player_nicks(selector = nil)
      ['GracieBoo', 'xXPlayerXx'] # need at least two players for spam detection to work
    end
    
    def ServerQuery.numplayers
      "2"
    end

    spam_event = <<-DONE
      [08:33:03] [Server thread/INFO]: GracieBoo[/127.0.0.1:54212] logged in with entity id 315010 at (5583.5, 40.0, -5573.5)
      [08:33:03] [Server thread/INFO]: GracieBoo joined the game
      [08:33:06] [Server thread/INFO]: <GracieBoo> hi
      [08:33:10] [Server thread/INFO]: <GracieBoo> anybody here?
      [08:33:11] [Server thread/INFO]: <GracieBoo> HELLO
      [08:33:12] [Server thread/INFO]: <GracieBoo> myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:12] [Server thread/INFO]: <GracieBoo> myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:13] [Server thread/INFO]: <GracieBoo> myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:13] [Server thread/INFO]: <GracieBoo> myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:14] [Server thread/INFO]: <GracieBoo> myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:15] [Server thread/INFO]: <GracieBoo> myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:16] [Server thread/INFO]: <GracieBoo> myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:16] [Server thread/INFO]: <GracieBoo> myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:17] [Server thread/INFO]: <GracieBoo> myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:17] [Server thread/INFO]: <GracieBoo> myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:18] [Server thread/INFO]: <GracieBoo> myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:18] [Server thread/INFO]: <GracieBoo> myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:19] [Server thread/INFO]: <GracieBoo> myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:19] [Server thread/INFO]: <GracieBoo> myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:20] [Server thread/INFO]: <GracieBoo> myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:20] [Server thread/INFO]: <GracieBoo> myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:21] [Server thread/INFO]: <GracieBoo> myserver.mcpre.co.uk NEW SERVER COME JOIN
    DONE

    assert_callback_ran 'Spammy' do
      assert_kicked 'GracieBoo' do
        refute_kicked 'inertia186' do
          spam_event.each_line do |line|
            # We are trying to achieve the highest code coverage possible, so
            # this particular test flushes and blocks every line of the example
            # log. Passing a block to open like we do in other tests is "too
            # efficient"  and causes the test to skip certain spam conditions.
      
            # Note, it's good to test both ways because unflushed files more
            # closely simulate a laggy server.
      
            f = File.open("#{Preference.path_to_server}/logs/latest.log", 'a')
            f << line.strip + "\n"
            f.close
            MinecraftServerLogHandler.handle line.strip
          end
        end
      end
    end

    assert Player.find_by_nick('GracieBoo').spam_ratio <= 0.1, 'expect kickable spam ratio'
  end

  def test_spam_detect_alt
    MinecraftServerLogHandler.handle '[14:12:05] [User Authenticator #23/INFO]: UUID of player xXPlayerXx is f6ddf946-f162-8d48-a21b-ac00929fb848'
    MinecraftServerLogHandler.handle "[08:33:03] [User Authenticator #23/INFO]: UUID of player GracieBoo is a5077378-81eb-4215-96f9-16679e3401cb"

    def Server.player_nicks(selector = nil)
      ['GracieBoo', 'xXPlayerXx'] # need at least two players for spam detection to work
    end

    def ServerQuery.numplayers
      "2"
    end

    spam_event = <<-DONE
      [08:33:03] [Server thread/INFO]: GracieBoo[/127.0.0.1:54212] logged in with entity id 315010 at (5583.5, 40.0, -5573.5)
      [08:33:03] [Server thread/INFO]: GracieBoo joined the game
      [08:33:10] [Server thread/INFO]: <GracieBoo> spam
      [08:33:10] [Server thread/INFO]: <GracieBoo> spamt
      [08:33:10] [Server thread/INFO]: <GracieBoo> spamtt
      [08:33:10] [Server thread/INFO]: <GracieBoo> spamttt
      [08:33:10] [Server thread/INFO]: <GracieBoo> spamtttt
      [08:33:10] [Server thread/INFO]: <GracieBoo> spamttttt
      [08:33:10] [Server thread/INFO]: <GracieBoo> spamtttttt
      [08:33:10] [Server thread/INFO]: <GracieBoo> spamttttttt
      [08:33:10] [Server thread/INFO]: <GracieBoo> spamtttttttt
      [08:33:10] [Server thread/INFO]: <GracieBoo> spamttttttttt
      [08:33:10] [Server thread/INFO]: <GracieBoo> spamtttttttttt
      [08:33:10] [Server thread/INFO]: <GracieBoo> spamttttttttttt
      [08:33:10] [Server thread/INFO]: <GracieBoo> spamtttttttttttt
      [08:33:10] [Server thread/INFO]: <GracieBoo> spamttttttttttttt
      [08:33:10] [Server thread/INFO]: <GracieBoo> spamtttttttttttttt
      [08:33:10] [Server thread/INFO]: <GracieBoo> spamttttttttttttttt
    DONE

    File.open("#{Preference.path_to_server}/logs/latest.log", 'a') do |f|
      spam_event.each_line do |line|
        f << line.strip + "\n"
      end
    end

    assert_callback_ran 'Spammy' do
      assert_kicked 'GracieBoo' do
        refute_kicked 'inertia186' do
          MinecraftServerLogHandler.handle "[08:33:10] [Server thread/INFO]: <GracieBoo> spamtttttttttttttttt"
        end
      end
    end

    assert Player.find_by_nick('GracieBoo').spam_ratio <= 0.1, 'expect kickable spam ratio'
  end

  def test_spam_with_tool_detect
    MinecraftServerLogHandler.handle '[12:12:05] [User Authenticator #23/INFO]: UUID of player xXPlayerXx is f6ddf946-f162-8d48-a21b-ac00929fb848'
    MinecraftServerLogHandler.handle "[13:31:09] [User Authenticator #115/INFO]: UUID of player SnowMan35 is 5e37e407-2ecf-407e-b717-316cfecc6b42"

    def Server.player_nicks(selector = nil)
      ['SnowMan35', 'xXPlayerXx'] # need at least two players for spam detection to work
    end

    def ServerQuery.numplayers
      "2"
    end

    spam_event = <<-DONE
      [13:31:10] [Server thread/INFO]: SnowMan35[/127.0.0.1:53431] logged in with entity id 4567520 at (5075.5, 95.40935860049753, -5624.5)
      [13:31:10] [Server thread/INFO]: SnowMan35 joined the game
      [13:31:19] [Server thread/WARN]: SnowMan35 moved too quickly! 0.0,32.40935860049753,0.0 (0.0, 32.40935860049753, 0.0)
      [13:31:51] [Server thread/INFO]: <SnowMan35> ==========/\\===========
      [13:31:51] [Server thread/INFO]: <SnowMan35> =========/==\\==========
      [13:31:51] [Server thread/INFO]: <SnowMan35> ========/====\\=========
      [13:31:51] [Server thread/INFO]: <SnowMan35> =======/======\\========
      [13:31:51] [Server thread/INFO]: <SnowMan35> ======/========\\=======
      [13:31:51] [Server thread/INFO]: <SnowMan35> =====/==========\\======
      [13:31:51] [Server thread/INFO]: <SnowMan35> ====/============\\=====
      [13:31:51] [Server thread/INFO]: <SnowMan35> ===/==============\\====
      [13:31:51] [Server thread/INFO]: <SnowMan35> ==/================\\===
    DONE

    File.open("#{Preference.path_to_server}/logs/latest.log", 'a') do |f|
      spam_event.each_line do |line|
        f << line.strip + "\n"
      end
    end
    
    assert_callback_ran 'Spammy' do
      refute_kicked 'SnowMan35' do
        refute_kicked 'xXPlayerXx' do
          MinecraftServerLogHandler.handle "[13:31:51] [Server thread/INFO]: <SnowMan35> ==/================\==="
        end
      end
    end

    #assert Player.find_by_nick('SnowMan35').spam_ratio <= 0.1, 'expect kickable spam ratio'
  end

  def test_spam_detect_alt_alt
    MinecraftServerLogHandler.handle '[14:12:05] [User Authenticator #23/INFO]: UUID of player xXPlayerXx is f6ddf946-f162-8d48-a21b-ac00929fb848'
    MinecraftServerLogHandler.handle '[08:47:21] [User Authenticator #20/INFO]: UUID of player Genevieve05 is 5000277b-6f04-41d9-ba1a-f477f2b4810e'

    def Server.player_nicks(selector = nil)
      ['Genevieve05', 'xXPlayerXx'] # need at least two players for spam detection to work
    end

    def ServerQuery.numplayers
      "2"
    end

    spam_event = <<-DONE
    [08:47:21] [Server thread/INFO]: Genevieve05[/72.91.207.142:51737] logged in with entity id 303539 at (5000.3521081755625, 34.0, -5199.300000011921)
    [08:47:21] [Server thread/INFO]: Genevieve05 joined the game
    [08:47:33] [Server thread/INFO]: <Genevieve05> Γ¥û ╬⌐ ╬▓ ╬ª ╬ú ╬₧ Γƒü Γª╗ Γºë Γº¡ Γº┤ Γê₧ Γëî Γèò Γïì Γï░ Γï▒ Γ£û Γô╡ Γô╢ Γô╖ Γô╕ Γô╣ Γô║ Γô╗ Γô╝ Γô╜ Γô╛ ß┤ò Γ╕¿ Γ╕⌐ Γ¥¬ Γ¥½ Γô╡ Γô╢ Γô╖ Γô╕ Γô╣ Γô║ Γô╗ Γô╝ Γô╜ Γô╛ ΓÆê ΓÆë ΓÆè ΓÆï ΓÆî ΓÆì ΓÆÄ
    [08:47:55] [Server thread/INFO]: <Genevieve05> ΓÆê ΓÆë ΓÆè ΓÆï ΓÆî ΓÆì ΓÆÄ
    [08:48:01] [Server thread/INFO]: <Genevieve05> ΓÆê ΓÆë ΓÆè ΓÆï ΓÆî ΓÆì ΓÆÄ 8. 9. 10.
    DONE
    File.open("#{Preference.path_to_server}/logs/latest.log", 'a') do |f|
      spam_event.each_line do |line|
        f << line.strip + "\n"
      end
    end

    assert_callback_ran 'Spammy' do
      refute_kicked 'Genevieve05' do
        refute_kicked 'inertia186' do
          # TODO This should kick Genevieve05.
          MinecraftServerLogHandler.handle '[08:49:03] [Server thread/INFO]: <Genevieve05> Γ¥û ╬⌐ ╬▓ ╬ª ╬ú ╬₧ Γƒü Γª╗ Γºë Γº¡ Γº┤ Γê₧ Γëî Γèò Γïì Γï░ Γï▒ Γ£û Γô╡ Γô╢ Γô╖ Γô╕ Γô╣ Γô║ Γô╗ Γô╝ Γô╜ Γô╛ ß┤ò Γ╕¿ Γ╕⌐ Γ¥¬ Γ¥½ Γô╡ Γô╢ Γô╖ Γô╕ Γô╣ Γô║ Γô╗ Γô╝ Γô╜ Γô╛ ΓÆê ΓÆë ΓÆè ΓÆï ΓÆî ΓÆì ΓÆÄ'
        end
      end
    end

    skip 'needs to be < 1.0' if Player.find_by_nick('Genevieve05').spam_ratio == 1.0
    # :nocov:
    fail
    # :nocov:
    #assert_equal ?, Player.find_by_nick('Genevieve05').spam_ratio, 'expect spam ratio'
  end

  def test_emote_spam_detect
    MinecraftServerLogHandler.handle '[14:12:05] [User Authenticator #23/INFO]: UUID of player xXPlayerXx is f6ddf946-f162-8d48-a21b-ac00929fb848'
    MinecraftServerLogHandler.handle "[08:33:03] [User Authenticator #23/INFO]: UUID of player GracieBoo is a5077378-81eb-4215-96f9-16679e3401cb"

    def Server.player_nicks(selector = nil)
      ['GracieBoo', 'xXPlayerXx'] # need at least two players for spam detection to work
    end

    def ServerQuery.numplayers
      "2"
    end

    spam_event = <<-DONE
      [08:33:03] [Server thread/INFO]: GracieBoo[/127.0.0.1:54212] logged in with entity id 315010 at (5583.5, 40.0, -5573.5)
      [08:33:03] [Server thread/INFO]: GracieBoo joined the game
      [08:33:10] [Server thread/INFO]: * GracieBoo myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:11] [Server thread/INFO]: * GracieBoo myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:12] [Server thread/INFO]: * GracieBoo myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:12] [Server thread/INFO]: * GracieBoo myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:13] [Server thread/INFO]: * GracieBoo myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:13] [Server thread/INFO]: * GracieBoo myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:14] [Server thread/INFO]: * GracieBoo myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:15] [Server thread/INFO]: * GracieBoo myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:16] [Server thread/INFO]: * GracieBoo myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:16] [Server thread/INFO]: * GracieBoo myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:17] [Server thread/INFO]: * GracieBoo myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:17] [Server thread/INFO]: * GracieBoo myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:18] [Server thread/INFO]: * GracieBoo myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:18] [Server thread/INFO]: * GracieBoo myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:19] [Server thread/INFO]: * GracieBoo myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:19] [Server thread/INFO]: * GracieBoo myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:20] [Server thread/INFO]: * GracieBoo myserver.mcpre.co.uk NEW SERVER COME JOIN
      [08:33:20] [Server thread/INFO]: * GracieBoo myserver.mcpre.co.uk NEW SERVER COME JOIN
    DONE

    File.open("#{Preference.path_to_server}/logs/latest.log", 'a') do |f|
      spam_event.each_line do |line|
        f << line.strip + "\n"
      end
    end

    assert_callback_ran 'Spammy' do
      assert_kicked 'GracieBoo' do
        refute_kicked 'inertia186' do
          MinecraftServerLogHandler.handle "[08:33:21] [Server thread/INFO]: * GracieBoo myserver.mcpre.co.uk NEW SERVER COME JOIN"
        end
      end
    end

    assert Player.find_by_nick('GracieBoo').spam_ratio <= 0.1, 'expect kickable spam ratio'
  end

  def test_soundcheck
    callback = ServerCallback.find_by_name('Sound Check')

    assert_callback_ran callback do
      ServerCallback::AnyPlayerEntry.handle('[15:05:10] [Server thread/INFO]: <inertia186> @server soundcheck')
    end

    def Server.player_nicks(selector = nil)
      ['inertia186']
    end
    
    Player.find_by_nick('inertia186').update_attribute(:play_sounds, false)
    
    assert_callback_ran callback do
      ServerCallback::AnyPlayerEntry.handle('[15:05:10] [Server thread/INFO]: <inertia186> @server soundcheck')
    end
  end
  
  def test_search_replace
    callback = ServerCallback.find_by_name('Search Replace')
    
    assert_callback_ran callback do
      result = ServerCallback::AnyPlayerEntry.handle('[15:17:25] [Server thread/INFO]: <inertia186> %s/axe/sword')
    end
  end

  def test_help
    ServerCommand.reset_commands_executed
    callback = ServerCallback.find_by_name('Help ...')
    refute_nil callback.help_doc, 'expect help doc for callback'
    
    assert_callback_ran callback do
      result = ServerCallback::PlayerChat.handle('[15:17:25] [Server thread/INFO]: <inertia186> @server help')
      assert_equal 2, ServerCommand.commands_executed.keys.join.split(callback.help_doc.strip).size, 'expect help doc in command executed'
    end
  end

  def test_help_help
    ServerCommand.reset_commands_executed
    callback = ServerCallback.find_by_name('Help ...')
    refute_nil callback.help_doc, 'expect help doc for callback'
    
    assert_callback_ran 'Help ...' do
      result = ServerCallback::PlayerChat.handle('[15:17:25] [Server thread/INFO]: <inertia186> @server help help')
      assert_equal 2, ServerCommand.commands_executed.keys.join.split(callback.help_doc.strip).size, 'expect help doc in command executed'
    end
  end

  def test_help_all
    callbacks = ServerCallback.has_help_docs
    callbacks.find_each do |callback|
      ServerCommand.reset_commands_executed
      refute_nil callback.help_doc, 'expect help doc for callback'
    
      assert_callback_ran 'Help ...' do
        result = ServerCallback::PlayerChat.handle("[15:17:25] [Server thread/INFO]: <inertia186> @server help #{callback.help_doc_key}")
        # Maybe this should use .include? instead of a funky join.
        assert_equal 2, ServerCommand.commands_executed.keys.join.downcase.split(callback.help_doc.split("\n")[0].downcase).size, 'expect help doc in command executed'
      end
    end
  end
  
  def test_register
    callback = ServerCallback.find_by_name('Register')
    player = Player.find_by_nick('inertia186')
    player.update_attribute(:created_at, 48.hours.ago)

    refute player.registered?, 'did not expect player to be registered'
    
    assert_callback_ran callback do
      result = ServerCallback::PlayerChat.handle('[15:17:25] [Server thread/INFO]: <inertia186> @server register')
    end
    
    assert player.reload.registered?, 'expect player to be registered'
  end

  def test_unregister
    callback = ServerCallback.find_by_name('Unregister')
    player = Player.find_by_nick('inertia186')
    player.update_attribute(:created_at, 48.hours.ago)
    player.update_attribute(:registered_at, 24.hours.ago)

    assert player.registered?, 'expect player to be registered'
    
    assert_callback_ran callback do
      result = ServerCallback::PlayerChat.handle('[15:17:25] [Server thread/INFO]: <inertia186> @server unregister')
    end
    
    assert player.reload.registered?, 'for now, still expect player to be registered (unregister not supported yet)'
  end

  def test_origin
    callback = ServerCallback.find_by_name('Origin')
    player = Player.find_by_nick('inertia186')

    assert_callback_ran callback do
      ServerCallback::PlayerChat.handle('[15:17:25] [Server thread/INFO]: <inertia186> @server origin inertia186')
    end
  end

  def test_mail_workflow
    inertia186 = Player.find_by_nick('inertia186')

    callback = ServerCallback.find_by_name('Send Mail')
    assert_difference -> { inertia186.messages.read(false).count }, 2, 'expected unread' do
      assert_callback_ran callback do
        ServerCallback::AnyPlayerEntry.handle('[15:04:50] [Server thread/INFO]: <Dinnerbone> @inertia186 Hello there!')
        ServerCallback::AnyPlayerEntry.handle('[15:04:50] [Server thread/INFO]: <Dinnerbone> @inertia186 Check this out: http://www.mojang.com/')
      end
    end

    ServerCallback::ServerEntry.handle('[14:12:05] [User Authenticator #23/INFO]: UUID of player inertia186 is d6edf996-6182-4d58-ac1b-4ca0321fb748')
    
    callback = ServerCallback.find_by_name('Read Mail')
    assert_difference -> { inertia186.messages.read.count }, 2, 'expected read' do
      assert_callback_ran callback do
        ServerCallback::AnyPlayerEntry.handle('[15:04:50] [Server thread/INFO]: <inertia186> @server mail')
      end
    end

    callback = ServerCallback.find_by_name('Read Mail')
    assert_difference -> { inertia186.messages.read.count }, 0, 'expected fewer messages' do
      assert_callback_ran callback do
        ServerCallback::AnyPlayerEntry.handle('[15:04:50] [Server thread/INFO]: <inertia186> @server mail clear')
      end
    end

    assert_difference -> { inertia186.messages.read.muted(false).count }, -2, 'expected fewer messages' do
      assert_difference -> { inertia186.muted_players.count }, 1, 'expected muted player' do
        ServerCallback::AnyPlayerEntry.handle('[15:04:50] [Server thread/INFO]: <inertia186> @server mail mute dinnerbone')
      end
    end

    assert_difference -> { inertia186.muted_players.count }, 0, 'did not expect muted player (already muted)' do
      ServerCallback::AnyPlayerEntry.handle('[15:04:50] [Server thread/INFO]: <inertia186> @server mail mute dinnerbone')
    end
    
    assert_difference -> { inertia186.messages.read.muted(false).count }, 2, 'expected read' do
      assert_difference -> { inertia186.muted_players.count }, -1, 'expected unmuted player' do
        ServerCallback::AnyPlayerEntry.handle('[15:04:50] [Server thread/INFO]: <inertia186> @server mail unmute dinnerbone')
      end
    end

    assert_difference -> { inertia186.muted_players.count }, 0, 'did not expect unmuted player (already unmuted)' do
      ServerCallback::AnyPlayerEntry.handle('[15:04:50] [Server thread/INFO]: <inertia186> @server mail unmute dinnerbone')
    end

    callback = ServerCallback.find_by_name('Read Mail')
    assert_difference -> { inertia186.messages.read.count }, 0, 'expected fewer messages' do
      assert_callback_ran callback do
        ServerCallback::AnyPlayerEntry.handle('[15:04:50] [Server thread/INFO]: <inertia186> @server mail clear')
      end
    end
  end
  
  def test_unknown_callback
    refute_callback_ran "Unknown" do
      ServerCallback::PlayerChat.handle('[15:17:25] [Server thread/INFO]: <inertia186> test')
    end
  end
end
