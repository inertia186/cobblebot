require 'test_helper'

class MinecraftServerLogHandlerTest < ActiveSupport::TestCase
  def setup
    method = :create!; eval File.read "#{Rails.root}/db/seeds.rb"
    
    Preference.path_to_server = "#{Rails.root}/tmp"
  end

  def test_check_version
    ServerCallback::AnyPlayerEntry.handle('[15:17:25] [Server thread/INFO]: <inertia186> @server version')
    refute_nil ServerCallback.find_by_name('Check Version').ran_at, 'did not expect nil ran_at'
  end

  def test_playercheck
    ServerCallback::AnyPlayerEntry.handle('[08:23:03] [Server thread/INFO]: <inertia186> @server playercheck inertia186')
    refute_nil ServerCallback.find_by_name('Player Check').ran_at, 'did not expect nil ran_at'
  end

  def test_autolink
    cobblebot = Link.where(url: 'http://github.com/inertia186/cobblebot').first
    cobblebot.update_attribute(:expires_at, 2.days.from_now)
    
    assert_no_difference -> { Link.count }, 'did not expect new link record' do
      ServerCallback::AnyPlayerEntry.handle('[08:23:03] [Server thread/INFO]: <inertia186> http://github.com/inertia186/cobblebot')
    end
    
    refute_nil ServerCallback.find_by_name('Autolink').ran_at, 'did not expect nil ran_at'
  end

  def test_player_authenticated
    assert_difference -> { Player.count }, 1, 'expect new player' do
      ServerCallback::ServerEntry.handle('[14:12:05] [User Authenticator #23/INFO]: UUID of player xXPlayerXx is f6ddf946-f162-8d48-a21b-ac00929fb848')
    end
    refute_nil ServerCallback.find_by_name('Player Authenticated').ran_at, 'did not expect nil ran_at'

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

  def test_message_of_the_day
    ServerCallback::ServerEntry.handle('[08:57:14] [Server thread/INFO]: inertia186 joined the game')
    refute_nil ServerCallback.find_by_name('Message of the Day').ran_at, 'did not expect nil ran_at'
  end

  def test_latest_player_chat
    player = Player.find_by_nick('inertia186')
    callback = ServerCallback.find_by_name('Latest Player Chat')
    
    ServerCallback::AnyPlayerEntry.handle('[15:04:50] [Server thread/INFO]: <inertia186> Hello!')
    refute_nil callback.reload.ran_at, 'did not expect nil ran_at'
    assert_equal 'Hello!', player.reload.last_chat, 'did not expect nil last_chat'

    callback.update_attribute(:ran_at, nil)
    player.update_attribute(:last_chat, nil)
    ServerCallback::AnyPlayerEntry.handle('[15:04:50] [Server thread/INFO]: <inertia186> "quoted"')
    refute_nil callback.reload.ran_at, 'did not expect nil ran_at'
    assert_equal '"quoted"', player.reload.last_chat, 'did not expect nil last_chat'

    callback.update_attribute(:ran_at, nil)
    player.update_attribute(:last_chat, nil)
    ServerCallback::AnyPlayerEntry.handle('[15:04:50] [Server thread/INFO]: <inertia186> #{0}')
    refute_nil callback.reload.ran_at, 'did not expect nil ran_at'
    refute_nil player.reload.last_chat, 'did not expect nil last_chat'

    callback.update_attribute(:ran_at, nil)
    player.update_attribute(:last_chat, nil)
    ServerCallback::AnyPlayerEntry.handle('[15:04:50] [Server thread/INFO]: <inertia186> #{1/0}')
    refute_nil callback.reload.ran_at, 'did not expect nil ran_at'
    refute_nil player.reload.last_chat, 'did not expect nil last_chat'
  end

  def test_latest_player_ip
    ServerCallback::ServerEntry.handle('[17:45:49] [Server thread/INFO]: inertia186[/127.0.0.1:63640] logged in with entity id 7477 at (15.11891680919476, 63.0, 296.4194632969733)')
    refute_nil ServerCallback.find_by_name('Latest Player IP').ran_at, 'did not expect nil ran_at'
    refute_nil Player.find_by_nick('inertia186').last_ip, 'did not expect nil last_ip'
  end

  def test_player_logged_out
    callback = ServerCallback.find_by_name('Player Logged Out')
    
    ServerCallback::ServerEntry.handle('[15:29:35] [Server thread/INFO]: inertia186 lost connection: TextComponent{text=\'Disconnected\', siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}')
    refute_nil callback.reload.ran_at, 'did not expect nil ran_at'
    refute_nil Player.find_by_nick('inertia186').last_logout_at, 'did not expect nil last_chat'

    # Variations
    
    callback.update_attribute(:ran_at, nil)
    ServerCallback::ServerEntry.handle('[11:44:45] [Server thread/INFO]: inertia186 lost connection: TranslatableComponent{key=\'disconnect.timeout\', args=[], siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}')
    refute_nil callback.reload.ran_at, 'did not expect nil ran_at'

    callback.update_attribute(:ran_at, nil)
    ServerCallback::ServerEntry.handle('[19:27:46] [Server thread/INFO]: inertia186 lost connection: TranslatableComponent{key=\'disconnect.genericReason\', args=[Internal Exception: java.io.IOException: Connection reset by peer], siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}')
    refute_nil callback.reload.ran_at, 'did not expect nil ran_at'

    callback.update_attribute(:ran_at, nil)
    ServerCallback::ServerEntry.handle('[18:28:53] [Server thread/INFO]: blackhat186 lost connection: TextComponent{text=\'Flying is not enabled on this server\', siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}')
    refute_nil callback.reload.ran_at, 'did not expect nil ran_at'

    callback.update_attribute(:ran_at, nil)
    ServerCallback::ServerEntry.handle('[10:21:31] [Server thread/INFO]: inertia186 lost connection: TextComponent{text=\'You logged in from another location\', siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}')
    refute_nil callback.reload.ran_at, 'did not expect nil ran_at'

    callback.update_attribute(:ran_at, nil)
    ServerCallback::ServerEntry.handle('[00:03:37] [Server thread/INFO]: inertia186 lost connection: TextComponent{text=\'You have been idle for too long!\', siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}')
    refute_nil callback.reload.ran_at, 'did not expect nil ran_at'

    callback.update_attribute(:ran_at, nil)
    ServerCallback::ServerEntry.handle('[03:05:08] [Server thread/INFO]: inertia186 lost connection: TextComponent{text=\'Have a Nice Day!\', siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}')
    refute_nil callback.reload.ran_at, 'did not expect nil ran_at'

    callback.update_attribute(:ran_at, nil)
    ServerCallback::ServerEntry.handle('[08:01:11] [Server thread/INFO]: jackass186 lost connection: TextComponent{text=\'disconnect.spam\', siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}')
    refute_nil callback.reload.ran_at, 'did not expect nil ran_at'

    callback.update_attribute(:ran_at, nil)
    ServerCallback::ServerEntry.handle('[11:11:38] [Server thread/INFO]: jackass186 lost connection: TextComponent{text=\'Kicked by an operator.\', siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}')
    refute_nil callback.reload.ran_at, 'did not expect nil ran_at'

    # Ignore

    callback.update_attribute(:ran_at, nil)
    ServerCallback::ServerEntry.handle('[15:12:31] [Server thread/INFO]: /127.0.0.1:50472 lost connection: Failed to verify username!')
    assert_nil callback.reload.ran_at, 'expect nil ran_at'

    ServerCallback::ServerEntry.handle('[19:06:04] [Server thread/INFO]: /127.0.0.1:52748 lost connection: Internal Exception: io.netty.handler.codec.DecoderException: The received string length is longer than maximum allowed (22 > 16)')
    assert_nil callback.reload.ran_at, 'expect nil ran_at'

    ServerCallback::ServerEntry.handle('[09:59:11] [Server thread/INFO]: com.mojang.authlib.GameProfile@77550cf1[id=<null>,name=inertia186,properties={},legacy=false] (/127.0.0.1:56157) lost connection: Authentication servers are down. Please try again later, sorry!')
    assert_nil callback.reload.ran_at, 'expect nil ran_at'

    ServerCallback::ServerEntry.handle('[13:28:33] [Server thread/INFO]: com.mojang.authlib.GameProfile@22ad3285[id=<null>,name=inertia186,properties={},legacy=false] (/127.0.0.1:53908) lost connection: Timed out')
    assert_nil callback.reload.ran_at, 'expect nil ran_at'

    ServerCallback::ServerEntry.handle('[00:22:23] [Server thread/INFO]: com.mojang.authlib.GameProfile@622ca134[id=<null>,name=inertia186,properties={},legacy=false] (/127.0.0.1:15274) lost connection: Internal Exception: java.io.IOException: Connection reset by peer')
    assert_nil callback.reload.ran_at, 'expect nil ran_at'

    ServerCallback::ServerEntry.handle('[17:01:27] [Server thread/INFO]: com.mojang.authlib.GameProfile@e509a8b[id=ffffffff-ffff-ffff-ffff-ffffffffffff,name=blackhat186,properties={textures=[com.mojang.authlib.properties.Property@6688ce2c]},legacy=false] (/127.0.0.1:57235) lost connection: You are banned from this server!')
    assert_nil callback.reload.ran_at, 'expect nil ran_at'
  end
  
  def test_autosync
    ServerCallback::ServerEntry.handle('[19:23:22] [Server thread/WARN]: inertia186 moved wrongly!')
    refute_nil ServerCallback.find_by_name('Autosync').ran_at, 'did not expect nil ran_at'
  end

  def test_search_replace
    ServerCallback::AnyPlayerEntry.handle('[15:05:10] [Server thread/INFO]: <inertia186> %s/axe/sword/')
    refute_nil ServerCallback.find_by_name('Search Replace').ran_at, 'did not expect nil ran_at'
  end
  
  def test_random_tip
    ServerCallback::AnyPlayerEntry.handle('[15:05:10] [Server thread/INFO]: <inertia186> @server tip')
    refute_nil ServerCallback.find_by_name('Random Tip').ran_at, 'did not expect nil ran_at'
    # Make sure the "pretend" option reaches the callback for simulated chat.
    assert_equal '@server tip', Player.find_by_nick('inertia186').last_chat, 'expect last chat to be @server tip'
  end
  
  def test_spam_detect
    MinecraftServerLogHandler.handle '[14:12:05] [User Authenticator #23/INFO]: UUID of player xXPlayerXx is f6ddf946-f162-8d48-a21b-ac00929fb848'
    MinecraftServerLogHandler.handle "[08:33:03] [User Authenticator #23/INFO]: UUID of player GracieBoo is a5077378-81eb-4215-96f9-16679e3401cb"

    def Server.player_nicks(selector = nil)
      ['GracieBoo', 'xXPlayerXx'] # need at least two players for spam detection to work
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

    spam_event.each_line do |line|
      # We are trying to achieve the highest code coverage possible, so this 
      # particular test flushes and blocks every line of the example log.
      # Passing a block to open like we do in other tests is "too efficient" 
      # and causes the test to skip certain spam conditions.
      
      # Note, it's good to test both ways because unflushed files more closely 
      # simulate a laggy server.
      
      f = File.open("#{Preference.path_to_server}/logs/latest.log", 'a')
      f << line.strip + "\n"
      f.close
      MinecraftServerLogHandler.handle line.strip
    end

    refute_nil ServerCallback.find_by_name('Spammy').ran_at, 'did not expect nil ran_at'
    assert Player.find_by_nick('GracieBoo').spam_ratio <= 0.1, 'expect kickable spam ratio'
  end

  def test_spam_detect_alt
    MinecraftServerLogHandler.handle '[14:12:05] [User Authenticator #23/INFO]: UUID of player xXPlayerXx is f6ddf946-f162-8d48-a21b-ac00929fb848'
    MinecraftServerLogHandler.handle "[08:33:03] [User Authenticator #23/INFO]: UUID of player GracieBoo is a5077378-81eb-4215-96f9-16679e3401cb"

    def Server.player_nicks(selector = nil)
      ['GracieBoo', 'xXPlayerXx'] # need at least two players for spam detection to work
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

    MinecraftServerLogHandler.handle "[08:33:10] [Server thread/INFO]: <GracieBoo> spamtttttttttttttttt"
    refute_nil ServerCallback.find_by_name('Spammy').ran_at, 'did not expect nil ran_at'
    assert Player.find_by_nick('GracieBoo').spam_ratio <= 0.1, 'expect kickable spam ratio'
  end

  def test_spam_detect_alt_alt
    MinecraftServerLogHandler.handle '[14:12:05] [User Authenticator #23/INFO]: UUID of player xXPlayerXx is f6ddf946-f162-8d48-a21b-ac00929fb848'
    MinecraftServerLogHandler.handle '[08:47:21] [User Authenticator #20/INFO]: UUID of player Genevieve05 is 5000277b-6f04-41d9-ba1a-f477f2b4810e'

    def Server.player_nicks(selector = nil)
      ['Genevieve05', 'xXPlayerXx'] # need at least two players for spam detection to work
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

    MinecraftServerLogHandler.handle '[08:49:03] [Server thread/INFO]: <Genevieve05> Γ¥û ╬⌐ ╬▓ ╬ª ╬ú ╬₧ Γƒü Γª╗ Γºë Γº¡ Γº┤ Γê₧ Γëî Γèò Γïì Γï░ Γï▒ Γ£û Γô╡ Γô╢ Γô╖ Γô╕ Γô╣ Γô║ Γô╗ Γô╝ Γô╜ Γô╛ ß┤ò Γ╕¿ Γ╕⌐ Γ¥¬ Γ¥½ Γô╡ Γô╢ Γô╖ Γô╕ Γô╣ Γô║ Γô╗ Γô╝ Γô╜ Γô╛ ΓÆê ΓÆë ΓÆè ΓÆï ΓÆî ΓÆì ΓÆÄ'
    refute_nil ServerCallback.find_by_name('Spammy').ran_at, 'did not expect nil ran_at'
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

    MinecraftServerLogHandler.handle "[08:33:21] [Server thread/INFO]: * GracieBoo myserver.mcpre.co.uk NEW SERVER COME JOIN"
    refute_nil ServerCallback.find_by_name('Spammy').ran_at, 'did not expect nil ran_at'
    assert Player.find_by_nick('GracieBoo').spam_ratio <= 0.1, 'expect kickable spam ratio'
  end

  def test_soundcheck
    callback = ServerCallback.find_by_name('Sound Check')
    ServerCallback::AnyPlayerEntry.handle('[15:05:10] [Server thread/INFO]: <inertia186> @server soundcheck')
    refute_nil callback.reload.ran_at, 'did not expect nil ran_at'

    def Server.player_nicks(selector = nil)
      ['inertia186']
    end
    
    Player.find_by_nick('inertia186').update_attribute(:play_sounds, false)
    
    callback.update_attribute(:ran_at, nil)
    ServerCallback::AnyPlayerEntry.handle('[15:05:10] [Server thread/INFO]: <inertia186> @server soundcheck')
    refute_nil callback.reload.ran_at, 'did not expect nil ran_at'
  end
end
