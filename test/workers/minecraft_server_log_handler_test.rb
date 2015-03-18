require 'test_helper'

class MinecraftServerLogHandlerTest < ActiveSupport::TestCase
  def setup
    sym = :create!; eval File.read "#{Rails.root}/db/seeds.rb"
  end

  def test_check_version
    MinecraftServerLogHandler.send(:handle_player_chat, '[15:17:25] [Server thread/INFO]: <inertia186> @server version')
    refute_nil ServerCallback.find_by_name('Check Version').ran_at, 'did not expect nil ran_at'
  end

  def test_playercheck
    MinecraftServerLogHandler.send(:handle_player_chat, '[08:23:03] [Server thread/INFO]: <inertia186> @server playercheck inertia186')
    refute_nil ServerCallback.find_by_name('Player Check').ran_at, 'did not expect nil ran_at'
  end

  def test_player_authenticated
    assert_difference -> { Player.count }, 1, 'expect new player' do
      MinecraftServerLogHandler.send(:handle_server_message, '[14:12:05] [User Authenticator #23/INFO]: UUID of player xXPlayerXx is f6ddf946-f162-8d48-a21b-ac00929fb848')
    end
    refute_nil ServerCallback.find_by_name('Player Authenticated').ran_at, 'did not expect nil ran_at'

    assert_no_difference -> { Player.count }, 'did not expect new player' do
      MinecraftServerLogHandler.send(:handle_server_message, '[14:12:05] [User Authenticator #23/INFO]: UUID of player xXPlayerXx is f6ddf946-f162-8d48-a21b-ac00929fb848')
    end

    player = Player.last
    assert_nil player.last_nick, 'expect last_nick to be nil'

    assert_no_difference -> { Player.count }, 'did not expect new player' do
      MinecraftServerLogHandler.send(:handle_server_message, '[14:12:05] [User Authenticator #23/INFO]: UUID of player zZPlayerZz is f6ddf946-f162-8d48-a21b-ac00929fb848')
    end

    player.reload
    assert_equal player.nick, 'zZPlayerZz', 'expected nick to update to new nick'
    refute_nil player.last_nick, 'expect last_nick to update'
    refute_equal player.nick, player.last_nick, 'expect last_nick not to be equal to nick'
  end

  def test_latest_player_chat
    MinecraftServerLogHandler.send(:handle_player_chat, '[15:04:50] [Server thread/INFO]: <inertia186> Hello!')
    refute_nil ServerCallback.find_by_name('Latest Player Chat').ran_at, 'did not expect nil ran_at'
    refute_nil Player.find_by_nick('inertia186').last_chat, 'did not expect nil last_chat'
  end

  def test_latest_player_ip
    MinecraftServerLogHandler.send(:handle_server_message, '[17:45:49] [Server thread/INFO]: inertia186[/127.0.0.1:63640] logged in with entity id 7477 at (15.11891680919476, 63.0, 296.4194632969733)')
    refute_nil ServerCallback.find_by_name('Latest Player IP').ran_at, 'did not expect nil ran_at'
    refute_nil Player.find_by_nick('inertia186').last_ip, 'did not expect nil last_ip'
  end

  def test_player_logged_out
    callback = ServerCallback.find_by_name('Player Logged Out')
    
    MinecraftServerLogHandler.send(:handle_server_message, '[15:29:35] [Server thread/INFO]: inertia186 lost connection: TextComponent{text=\'Disconnected\', siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}')
    refute_nil callback.reload.ran_at, 'did not expect nil ran_at'
    refute_nil Player.find_by_nick('inertia186').last_logout_at, 'did not expect nil last_chat'

    # Variations
    
    callback.update_attribute(:ran_at, nil)
    MinecraftServerLogHandler.send(:handle_server_message, '[11:44:45] [Server thread/INFO]: inertia186 lost connection: TranslatableComponent{key=\'disconnect.timeout\', args=[], siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}')
    refute_nil callback.reload.ran_at, 'did not expect nil ran_at'

    callback.update_attribute(:ran_at, nil)
    MinecraftServerLogHandler.send(:handle_server_message, '[19:27:46] [Server thread/INFO]: inertia186 lost connection: TranslatableComponent{key=\'disconnect.genericReason\', args=[Internal Exception: java.io.IOException: Connection reset by peer], siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}')
    refute_nil callback.reload.ran_at, 'did not expect nil ran_at'

    callback.update_attribute(:ran_at, nil)
    MinecraftServerLogHandler.send(:handle_server_message, '[18:28:53] [Server thread/INFO]: blackhat186 lost connection: TextComponent{text=\'Flying is not enabled on this server\', siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}')
    refute_nil callback.reload.ran_at, 'did not expect nil ran_at'

    callback.update_attribute(:ran_at, nil)
    MinecraftServerLogHandler.send(:handle_server_message, '[10:21:31] [Server thread/INFO]: inertia186 lost connection: TextComponent{text=\'You logged in from another location\', siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}')
    refute_nil callback.reload.ran_at, 'did not expect nil ran_at'

    callback.update_attribute(:ran_at, nil)
    MinecraftServerLogHandler.send(:handle_server_message, '[00:03:37] [Server thread/INFO]: inertia186 lost connection: TextComponent{text=\'You have been idle for too long!\', siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}')
    refute_nil callback.reload.ran_at, 'did not expect nil ran_at'

    callback.update_attribute(:ran_at, nil)
    MinecraftServerLogHandler.send(:handle_server_message, '[03:05:08] [Server thread/INFO]: inertia186 lost connection: TextComponent{text=\'Have a Nice Day!\', siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}')
    refute_nil callback.reload.ran_at, 'did not expect nil ran_at'

    callback.update_attribute(:ran_at, nil)
    MinecraftServerLogHandler.send(:handle_server_message, '[08:01:11] [Server thread/INFO]: jackass186 lost connection: TextComponent{text=\'disconnect.spam\', siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}')
    refute_nil callback.reload.ran_at, 'did not expect nil ran_at'

    callback.update_attribute(:ran_at, nil)
    MinecraftServerLogHandler.send(:handle_server_message, '[11:11:38] [Server thread/INFO]: jackass186 lost connection: TextComponent{text=\'Kicked by an operator.\', siblings=[], style=Style{hasParent=false, color=null, bold=null, italic=null, underlined=null, obfuscated=null, clickEvent=null, hoverEvent=null, insertion=null}}')
    refute_nil callback.reload.ran_at, 'did not expect nil ran_at'

    # Ignore

    callback.update_attribute(:ran_at, nil)
    MinecraftServerLogHandler.send(:handle_server_message, '[15:12:31] [Server thread/INFO]: /127.0.0.1:50472 lost connection: Failed to verify username!')
    assert_nil callback.reload.ran_at, 'expect nil ran_at'

    MinecraftServerLogHandler.send(:handle_server_message, '[19:06:04] [Server thread/INFO]: /127.0.0.1:52748 lost connection: Internal Exception: io.netty.handler.codec.DecoderException: The received string length is longer than maximum allowed (22 > 16)')
    assert_nil callback.reload.ran_at, 'expect nil ran_at'

    MinecraftServerLogHandler.send(:handle_server_message, '[09:59:11] [Server thread/INFO]: com.mojang.authlib.GameProfile@77550cf1[id=<null>,name=inertia186,properties={},legacy=false] (/127.0.0.1:56157) lost connection: Authentication servers are down. Please try again later, sorry!')
    assert_nil callback.reload.ran_at, 'expect nil ran_at'

    MinecraftServerLogHandler.send(:handle_server_message, '[13:28:33] [Server thread/INFO]: com.mojang.authlib.GameProfile@22ad3285[id=<null>,name=inertia186,properties={},legacy=false] (/127.0.0.1:53908) lost connection: Timed out')
    assert_nil callback.reload.ran_at, 'expect nil ran_at'

    MinecraftServerLogHandler.send(:handle_server_message, '[00:22:23] [Server thread/INFO]: com.mojang.authlib.GameProfile@622ca134[id=<null>,name=inertia186,properties={},legacy=false] (/127.0.0.1:15274) lost connection: Internal Exception: java.io.IOException: Connection reset by peer')
    assert_nil callback.reload.ran_at, 'expect nil ran_at'

    MinecraftServerLogHandler.send(:handle_server_message, '[17:01:27] [Server thread/INFO]: com.mojang.authlib.GameProfile@e509a8b[id=ffffffff-ffff-ffff-ffff-ffffffffffff,name=blackhat186,properties={textures=[com.mojang.authlib.properties.Property@6688ce2c]},legacy=false] (/127.0.0.1:57235) lost connection: You are banned from this server!')
    assert_nil callback.reload.ran_at, 'expect nil ran_at'
  end
  
  def test_autosync
    MinecraftServerLogHandler.send(:handle_server_message, '[19:23:22] [Server thread/WARN]: inertia186 moved wrongly!')
    refute_nil ServerCallback.find_by_name('Autosync').ran_at, 'did not expect nil ran_at'
  end
end