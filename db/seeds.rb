method ||= :create # Switch to :create! if you want to test full validation.

Preference.send method, key: Preference::WEB_ADMIN_PASSWORD, value: '123456', system: 'f'
Preference.send method, key: Preference::PATH_TO_SERVER, value: '/path/to/minecraft/server', system: 'f'
Preference.send method, key: Preference::COMMAND_SCHEME, value: 'rcon', system: 'f'
Preference.send method, key: Preference::MOTD, value: 'Welcome to the server!', system: 'f'
Preference.send method, key: Preference::RULES_JSON, value: "{\"color\": \"yellow\", \"text\": \"Server Rules\" }\n{\"color\": \"yellow\", \"text\": \"===\" }\n{\"color\": \"yellow\", \"text\": \"  1. No abusive chat.\" }\n{\"color\": \"yellow\", \"text\": \"  2. No annoying chat.\" }\n{\"color\": \"yellow\", \"text\": \"  3. Do not intentionally cause lag or crash the server nor threaten to do so.\" }\n{\"text\": \"\" }\n{\"color\": \"yellow\", \"text\": \"You will be banned for the violation of the above rules.\" }\n{\"text\": \"\" }\n{ \"color\": \"yellow\", \"text\": \"To get a random tip, type: \", \"extra\": [{\"text\": \"@server tip\", \"color\": \"dark_purple\", \"underlined\": \"true\", \"clickEvent\": {\"action\": \"run_command\", \"value\": \"@server tip\"}, \"hoverEvent\": {\"action\": \"show_text\", \"value\": \"Not Really That Helpful\"}}] }", system: 'f'
Preference.send method, key: Preference::TUTORIAL_JSON, value: "{ \"color\": \"yellow\", \"text\": \"Don't die.\" }", system: 'f'
Preference.send method, key: Preference::IRC_ENABLED, value: 'false', system: 'f'
Preference.send method, key: Preference::IRC_INFO, value: 'Example: My Minecraft Server - hostname or IP - http://web-site-url', system: 'f'
Preference.send method, key: Preference::IRC_WEB_CHAT_ENABLED, value: 'false', system: 'f'
Preference.send method, key: Preference::IRC_WEB_CHAT_URL_LABEL, value: 'freenode.net', system: 'f'
Preference.send method, key: Preference::IRC_WEB_CHAT_URL, value: 'http://webchat.freenode.net/?channels=%23my_channel&uio=d4', system: 'f'
Preference.send method, key: Preference::IRC_SERVER_HOST, value: 'irc.freenode.net', system: 'f'
Preference.send method, key: Preference::IRC_SERVER_PORT, value: '8000', system: 'f'
Preference.send method, key: Preference::IRC_NICK, value: "cobblebot#{Random.rand(100)}", system: 'f'
Preference.send method, key: Preference::IRC_CHANNEL, value: '#my_channel', system: 'f'
Preference.send method, key: Preference::IRC_CHANNEL_OPS, value: '', system: 'f'
Preference.send method, key: Preference::IRC_NICKSERV_PASSWORD, value: 'secret', system: 'f'

# System/Utility/Important ...
ServerCallback::PlayerChat.send method, name: 'Check Version', pattern: "/^@server version$/i", command: "say \"@a\", \"CobbleBot version %cobblebot_version%\"\nsay_link \"@a\", \"http://github.com/inertia186/cobblebot\", only_title: true", system: 't'
ServerCallback::PlayerChat.send method, name: 'Autolink', pattern: "/http/i", command: "say_link \"@a\", \"%message%\", nick: \"%nick%\"", system: 't'
ServerCallback::ServerEntry.send method, name: 'Message of the Day', pattern: "/([a-z0-9_]+) joined the game/i", command: "tell_motd \"%1%\"", system: 't'
ServerCallback::PlayerChat.send method, name: 'Message of the Day (self)', pattern: "/^@server motd$/i", command: "tell_motd \"%nick%\"", system: 't'
ServerCallback::PlayerChat.send method, name: 'Sync Me', pattern: "/^@server syncme$/i", command: "# This command will sometimes help players who are stuck.\nplay_sound \"%nick%\", \"smb_pipe\"\ntp \"%nick%\", \"~ ~ ~\"", cooldown: '+3 seconds', system: 't'
ServerCallback::ServerEntry.send method, name: 'Autosync', pattern: "/^([a-zA-Z0-9_]+) moved wrongly!/", command: "# This command will sometimes help players who are stuck, automatically.\ntp \"%1%\", \"~ ~ ~\"", system: 't'
ServerCallback::PlayerChat.send method, name: 'Sound Check', pattern: "/^@server soundcheck$/", command: "# This command allows the player to test their sound configuration in\n# CobbleBot.  There is additional logic to demonstrate how commands\n# can interact with players, not just respond blindly.  This command\n# changes which sound to use depending on how many times the\n# command has been used.\n\n@@sound_check ||= 0\n@@sound_check = 1 + @@sound_check\n\nif @@sound_check == 4\n  play_sound \"%nick%\", \"sound_check_b\"\nelsif @@sound_check > 7\n  play_sound \"%nick%\", \"sound_check_c\"\n  @@sound_check = 0\nelse\n  play_sound \"%nick%\", \"sound_check_a\"\nend", system: 't'
ServerCallback::ServerEntry.send method, name: 'Player Authenticated', pattern: "/UUID of player ([a-zA-Z0-9_]+) is ([a-fA-Z0-9-]+)/", command: "irc_event \"%1% joined the game\"\nplayer_authenticated \"%1%\", \"%2%\"", system: 't'
ServerCallback::PlayerChat.send method, name: 'Latest Player Chat', pattern: "/.*/", command: "update_player_last_chat \"%nick%\", \"%message%\", options", system: 't'
ServerCallback::ServerEntry.send method, name: 'Latest Player IP', pattern: "/([a-zA-Z0-9_]+)\\[\\/([0-9\.]+):.+\\] logged in with entity id/", command: "update_player_last_ip \"%1%\", \"%2%\"", system: 't'
ServerCallback::ServerEntry.send method, name: 'Player Logged Out', pattern: "/^([a-zA-Z0-9_]+) lost connection/", command: "irc_event \"%1% left the game\"\ntouch_player_last_logged_out \"%1%\"", system: 't'
ServerCallback::PlayerChat.send method, name: 'Player Check', pattern: "/^@server playercheck ([a-z0-9_]+)$/i", command: "say_playercheck \"@a\", \"%1%\"", system: 't'
ServerCallback::PlayerChat.send method, name: 'IRC Reply', pattern: "/^@irc (.*)$/i", command: "irc_reply \"%nick%\", \"%1%\"", system: 't'
ServerCallback::PlayerChat.send method, name: 'Slap', pattern: "/^@server slap(.*)/i", command: "say_slap \"@a\", \"%nick%\", \"%1%\"", system: 't'
ServerCallback::PlayerChat.send method, name: 'Add Tip', pattern: "/^@server addtip (.*)/i", command: "add_tip \"%nick%\", \"%1%\"", system: 't'
ServerCallback::PlayerChat.send method, name: 'Random Tip', pattern: "/^@server tip(.*)/i", command: "say_random_tip \"@a\", \"%nick%\", \"%1%\"", system: 't'
ServerCallback::PlayerChat.send method, name: 'Tip Info', pattern: "/^@server tips/i", command: "tips", system: 't'
ServerCallback::PlayerChat.send method, name: 'Rules', pattern: "/^@server rules/i", command: "say_rules \"%nick%\"", system: 't'
ServerCallback::PlayerChat.send method, name: 'Tutorial', pattern: "/^@server tutorial/i", command: "say_tutorial \"%nick%\"", system: 't'
ServerCallback::ServerEntry.send method, name: 'Cleaned Up Stats', pattern: "/Invalid statistic in .\\/.+\\/stats\\/(.+)\\.json: (.+)/", command: "uuid = \"%1%\"\nmsg = \"%2%\"\nplayer = Player.find_by_uuid uuid\n\ntell player.nick, msg if !!player", system: 't'
ServerCallback::AnyPlayerEntry.send method, name: 'Spammy', pattern: "/.*/i", command: "detect_spam \"%nick%\", \"%message%\"", system: 't'
ServerCallback::PlayerChat.send method, name: 'Toggle Sounds', pattern: "/^@server togglesounds$/i", command: "player = Server.players.find_by_nick(\"%nick%\")\n\nif !!player\n  player.toggle_play_sounds!\n  if ServerCallback.ready.where(name: 'Sound Check').any?\n    player.tell('To test, type: @server soundcheck')\n  end\nend\n\nplayer", system: 't'

# Player initialted sounds ...
ServerCallback::PlayerChat.send method, name: 'To The Batcave!', pattern: "/^to the/i", command: "play_sound \"@a\", \"to_the_batcave\"", cooldown: '+15 minutes', system: 'f'
ServerCallback::PlayerChat.send method, name: 'boo', pattern: "/halloween/i", command: "play_sound \"@a\", \"mk64_boo_laugh\"", cooldown: '+15 minutes', system: 'f'
ServerCallback::PlayerChat.send method, name: 'SEGA', pattern: "/blast processing/i", command: "play_sound \"@a\", \"sega\"", cooldown: '+15 minutes', system: 'f'
ServerCallback::PlayerChat.send method, name: 'Soon', pattern: "/soon/i", command: "play_sound \"@a\", \"smb_warning\"", cooldown: '+15 minutes', system: 'f'
ServerCallback::PlayerChat.send method, name: 'Navi', pattern: "/!!!/", command: "play_sound \"@a\", \"oot_navi_hey\"", cooldown: '+15 minutes', system: 'f'
ServerCallback::PlayerChat.send method, name: 'The More You Know', pattern: "/tmyk/i", command: "play_sound \"@a\", \"cf_tmyk\"", cooldown: '+15 minutes', system: 'f'
ServerCallback::PlayerChat.send method, name: 'TROLOLO', pattern: "/trololo/i", command: "play_sound \"@a\", \"cf_trololo\"", cooldown: '+2 hours', system: 'f'
ServerCallback::PlayerChat.send method, name: 'Bueller?', pattern: "/^anyone[^ ]*$/i", command: "# This sound is a little different in how it behaves.  Once the command is\r\n# triggered, it waits 5 seconds, then it checks to see if the player has typed \r\n# anything new.  If not, the sound plays.\r\n#\r\n# Thus, it doesn't always play, but it will always go into cooldown if it is\r\n# triggered.\r\n\r\nThread.start do\r\n  sleep 5\r\n  if \"%message%\" == find_latest_chat_by_nick(\"%nick%\")\r\n    play_sound \"@a\", \"cf_bueller\"\r\n  end\r\nend", cooldown: '+15 minutes', system: 'f'
ServerCallback::PlayerChat.send method, name: 'Oops', pattern: "/oops/i", command: "play_sound \"@a\", \"cf_wups\"", system: 'f'

# Death sounds ...
ServerCallback::ServerEntry.send method, name: 'Slain', pattern: "/was slain by/", command: "play_sound \"@a\", \"smb_mario_die\"", cooldown: '+15 minutes', system: 'f'
ServerCallback::ServerEntry.send method, name: 'Shot', pattern: "/was shot by/", command: "play_sound \"@a\", \"smb3_player_down\"", cooldown: '+15 minutes', system: 'f'
ServerCallback::ServerEntry.send method, name: 'Fell Out of the World', pattern: "/^[a-zA-A0-9_]+ fell out of the world/", command: "play_sound \"@a\", \"goofy_holler\"", cooldown: '+15 minutes', system: 'f'
ServerCallback::ServerEntry.send method, name: 'Knocked Into the Void', pattern: "/was knocked into the void/", command: "play_sound \"@a\", \"goofy_holler\"", cooldown: '+15 minutes', system: 'f'
ServerCallback::ServerEntry.send method, name: 'Fell', pattern: "/^[a-zA-Z0-9_]+ fell from a high place/", command: "play_sound \"@a\", \"fallen\"", cooldown: '+15 minutes', system: 'f'
ServerCallback::ServerEntry.send method, name: 'Doomed to Fall', pattern: "/was doomed to fall/", command: "play_sound \"@a\", \"wilhelm\"", cooldown: '+15 minutes', system: 'f'
ServerCallback::ServerEntry.send method, name: 'Hit the Ground Too Hard', pattern: "/hit the ground too hard/", command: "play_sound \"@a\", \"fallen\"", cooldown: '+15 minutes', system: 'f'
ServerCallback::ServerEntry.send method, name: 'Starved to Death', pattern: "/starved to death/", command: "play_sound \"@a\", \"sm64_mario_mamma_mia\"", cooldown: '+15 minutes', system: 'f'
ServerCallback::ServerEntry.send method, name: 'Withered Away', pattern: "/withered away/", command: "play_sound \"@a\", \"mk64_boo_laugh\"", cooldown: '+15 minutes', system: 'f'
ServerCallback::ServerEntry.send method, name: 'Killed by Witch', pattern: "/killed by Witch/", command: "play_sound \"@a\", \"mk64_boo_laugh\"", cooldown: '+15 minutes', system: 'f'
ServerCallback::ServerEntry.send method, name: 'Killed Using Magic', pattern: "/was killed.*using magic/", command: "play_sound \"@a\", \"family_guy_bruce_oh_no\"", cooldown: '+15 minutes', system: 'f'
ServerCallback::ServerEntry.send method, name: 'Thorns', pattern: "/was killed trying to hurt/", command: "play_sound \"@a\", \"loz_shield\"", system: 'f'
ServerCallback::ServerEntry.send method, name: 'Burnt', pattern: "/was burnt to a crisp/", command: "play_sound \"@a\", \"family_guy_bruce_oh_no\"", system: 'f'
ServerCallback::ServerEntry.send method, name: 'Burned', pattern: "/burned to death/", command: "play_sound \"@a\", \"loz_die\"", cooldown: '+15 minutes', system: 'f'
ServerCallback::ServerEntry.send method, name: 'Lava Swim', pattern: "/tried to swim in lava/", command: "play_sound \"@a\", \"loz_die\"", cooldown: '+15 minutes', system: 'f'
ServerCallback::ServerEntry.send method, name: 'Cactus Death', pattern: "/pricked/", command: "play_sound \"@a\", \"loz_shield\"", system: 'f'
ServerCallback::ServerEntry.send method, name: 'Sploded to Death', pattern: "/was blown up by/", command: "play_sound \"@a\", \"sadtrombone\"", cooldown: '+15 minutes', system: 'f'
ServerCallback::ServerEntry.send method, name: 'Anvil Death', pattern: "/squashed/", command: "play_sound \"@a\", \"oot_navi_watch_out\"", system: 'f'
ServerCallback::ServerEntry.send method, name: 'Bat Death?', pattern: "/by Bat/", command: "play_sound \"@a\", \"to_the_batcave\"", system: 'f'
ServerCallback::ServerEntry.send method, name: 'Fireballed to Death', pattern: "/fireballed/", command: "play_sound \"@a\", \"family_guy_bruce_oh_no\"", system: 'f'
ServerCallback::ServerEntry.send method, name: 'Just Died', pattern: "/died$/", command: "play_sound \"@a\", \"family_guy_bruce_what\"", system: 'f'

# Server sounds ...
ServerCallback::ServerEntry.send method, name: 'Flying Kick', pattern: "/was kicked for floating too long/", command: "play_sound \"@a\", \"smas_smb3_thud\"", system: 'f'
ServerCallback::ServerEntry.send method, name: 'Idle Kick', pattern: "/You have been idle for too long/", command: "play_sound \"@a\", \"smb3_pause\"", system: 'f'
ServerCallback::ServerEntry.send method, name: 'Another Client', pattern: "/You logged in from another location$/", command: "play_sound \"@a\", \"family_guy_bruce_what\"", system: 'f'

# Achievement sounds ...
ServerCallback::ServerEntry.send method, name: 'The Lie', pattern: "/The Lie/", command: "play_sound \"@a\", \"portal_still_alive\"", system: 'f'
ServerCallback::ServerEntry.send method, name: 'On A Rail', pattern: "/On A Rail/", command: "play_sound \"@a\", \"smw_course_clear\"", system: 'f'
ServerCallback::ServerEntry.send method, name: 'When Pigs Fly', pattern: "/When Pigs Fly/", command: "play_sound \"@a\", \"cf_rumble\"", system: 'f'
ServerCallback::ServerEntry.send method, name: 'Sniper Duel', pattern: "/Sniper Duel/", command: "play_sound \"@a\", \"excellent\"", system: 'f'
ServerCallback::ServerEntry.send method, name: 'DIAMONDS', pattern: "/DIAMONDS/", command: "play_sound \"@a\", \"loz_secret\"", system: 'f'
ServerCallback::ServerEntry.send method, name: 'We Need to Go Deeper', pattern: "/We Need to Go Deeper/", command: "play_sound \"@a\", \"sm64_bowser_message\"", cooldown: '+15 minutes', system: 'f'
ServerCallback::ServerEntry.send method, name: 'Return to Sender', pattern: "/Return to Sender/", command: "play_sound \"@a\", \"excellent\"", system: 'f'
ServerCallback::ServerEntry.send method, name: 'Into Fire', pattern: "/Into Fire/", command: "play_sound \"@a\", \"loz_fanfare\"", system: 'f'
ServerCallback::ServerEntry.send method, name: 'Local Brewery', pattern: "/Local Brewery/", command: "play_sound \"@a\", \"smb_powerup\"", system: 'f'
ServerCallback::ServerEntry.send method, name: 'The End', pattern: "/The End/", command: "play_sound \"@a\", \"smb_pipe\"", system: 'f'
ServerCallback::ServerEntry.send method, name: 'Enchanter', pattern: "/Enchanter/", command: "play_sound \"@a\", \"smb_powerup\"", system: 'f'
ServerCallback::ServerEntry.send method, name: 'Overkill', pattern: "/Overkill/", command: "play_sound \"@a\", \"excellent\"", system: 'f'
ServerCallback::ServerEntry.send method, name: 'Librarian', pattern: "/Librarian/", command: "play_sound \"@a\", \"loz_secret\"", system: 'f'
ServerCallback::ServerEntry.send method, name: 'Adventuring Time', pattern: "/Adventuring Time/", command: "play_sound \"@a\", \"mk64_racestart\"", system: 'f'
ServerCallback::ServerEntry.send method, name: 'The Beginning', pattern: "/The Beginning[^\\?]/", command: "play_sound \"@a\", \"loz_secret\"", system: 'f'
ServerCallback::ServerEntry.send method, name: 'Beaconator', pattern: "/Beaconator/", command: "play_sound \"@a\", \"smb_powerup\"", system: 'f'
ServerCallback::ServerEntry.send method, name: 'Repopulation', pattern: "/Repopulation/", command: "play_sound \"@a\", \"smb_1up\"", system: 'f'
ServerCallback::ServerEntry.send method, name: 'Diamonds to you', pattern: "/Diamonds to you/", command: "play_sound \"@a\", \"smb_coin\"", system: 'f'
ServerCallback::ServerEntry.send method, name: 'Overpowered', pattern: "/Overpowered/", command: "play_sound \"@a\", \"sm64_key_get\"", system: 'f'

# Miscellaneous
ServerCallback::PlayerChat.send method, name: 'Number Guess', pattern: "/^@server numberguess(.*)$/i", command: "# Number Guess.  This is a demonstration of how to store variables.  A new\n# number is picked every so often, usually whenever the worker restarts.\n\nargs = \"%1%\"\n\nif args.empty?\n  say \"@a\", \"Pick a number between 1 and 1000.  Each guess costs one Level of XP.  If you win, you get levels as a prize (more guesses = lower prize).  There is a random time limit on the secret number.  Multiple players may play simultaneously, but only the first correct guess wins. To guess, type: @server numberguess <guess>\", color: \"dark_purple\", as: \"Server\"\n\n  return\nend\n\nif @number.nil?\n  say \"@a\", \"A new secret number has been picked.\", color: \"green\", as: \"Server\"\n  @number ||= Random.rand(1000) + 1\n  @guess_count = 14\nend\n\nguess = args.split(' ')[0].to_i\n\nexecute \"xp -1L %nick%\"\n\n# Unfortunately, there's not a simple way to tell if the player reaches zero levels.\n\n@guess_count = @guess_count - 1\n\nsay \"@a\", \"%nick% guessed \#{guess}.  Too high.  Try again.\", color: \"red\", as: \"Server\" and return if guess > @number\nsay \"@a\", \"%nick% guessed \#{guess}.  Too low.  Try again.\", color: \"gold\", as: \"Server\" and return if guess < @number\n\n@guess_count = 0 if @guess_count < 0\nsay \"@a\", \"%nick% guessed it and won \#{pluralize @guess_count, 'level'}!  The number was \#{guess}!\", color: \"green\", as: \"Server\"\nexecute \"xp \#{@guess_count}L %nick%\"\n@number = nil", system: 'f'
ServerCallback::PlayerChat.send method, name: 'Grammar Nazi #001', pattern: "/([a-z]+ould) of/i", command: "# When people say \"could of\" or similar, this command corrects them with\n# \"could have\" or similar.\n\nreturn if \"%message%\" =~ /of course/i\n\nThread.start do\n  sleep 5 # Don't reply right away.\n  say \"@a\", \"*%1% have\"\nend", cooldown: '+30 seconds', system: 'f'
ServerCallback::PlayerChat.send method, name: 'Dijon?', pattern: "/an expensive ([a-z]{4,})/i", command: "Thread.start do\n  sleep 5\n  say \"@a\", \"Dijon %1%?\"\nend", cooldown: '+30 seconds', system: 'f'
ServerCallback::PlayerChat.send method, name: 'Embiggen', pattern: "/embiggen/i", command: "Thread.start do\n  sleep 5\n  say \"@a\", \"... a perfectly cromulent word.\"\nend", cooldown: '+30 seconds', system: 'f'
ServerCallback::PlayerChat.send method, name: 'Captain Obvious', pattern: "/([a-z]+) [a-z]+ (is|are) \\1/i", command: "Thread.start do\n  sleep 5\n  say \"@a\", \"We have a Captain Obvious over here.\"\nend", cooldown: '+30 seconds', system: 'f'
ServerCallback::PlayerChat.send method, name: 'CAPS', pattern: "/[A-Z]* [A-Z]* [A-Z]* [A-Z]*/", command: "say \"@a\", \"Easy on the caps, please.\"", cooldown: '+30 seconds', system: 'f'
ServerCallback::PlayerChat.send method, name: 'Festivus', pattern: "/festivus/i", command: "say \"@a\", \"... for the rest of us!\"", system: 'f'
ServerCallback::PlayerChat.send method, name: 'Muscallonge', pattern: "/muscallonge/i", command: "say \"@a\", \"You mean, the fish?\"", system: 'f'
ServerCallback::PlayerChat.send method, name: 'Search Replace', pattern: "/^%s\\/([^\\/]*)\\/([^\\/]*)[\\/]{0,1}$/i", command: "corrected = find_latest_chat_by_nick(\"%nick%\", \"%1%\")\n\nif corrected.nil?\n  all_nicks.each do |nick|\n    corrected = find_latest_chat_by_nick(nick, \"%1%\")\n    unless corrected.nil?\n      corrected.gsub!(/%1%/i, \"%2%\")\n      return emote \"@a\", \"thinks \#{nick} meant: \#{corrected}\", as: \"%nick%\"\n    end    \n  end\nelse\n  corrected.gsub!(/%1%/i, \"%2%\")\n  emote \"@a\", \"meant: \#{corrected}\", as: \"%nick%\"\nend", system: 'f'
ServerCallback::PlayerChat.send method, name: 'Florida Man', pattern: "/^@server floridaman$/i", command: "url = \"https://ajax.googleapis.com/ajax/services/search/news?v=1.0&q=florida%20man\"\nresponse = Net::HTTP.get_response(URI.parse(url))\njson = JSON.parse(response.body)\narticle = json['responseData']['results'].sample\n\nif !!article\n  title = CGI.unescapeHTML(article['titleNoFormatting']).gsub(/\"/, '\\\"')\n  say \"@a\", title, color: \"white\", as: \"Google\"\nend", system: 'f'

# Tips
Message::Tip.send method, body: 'Create a zombie-proof door by raising it by one block.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'If you\'re planning to jump from someplace high, make sure you have a water bucket in your hand and spam space bar and you might just survive.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'If you sprint and jump at the same time it\'s faster than just sprinting.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'If you\'re in lava and you\'re about to die, just place down a water bucket.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'Throw your garbage away in cactus.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'If you have a fire resistance potion a pillar of lava can be used as a quick drop.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'If you\'re going on a ride in a boat push the boat out before hopping in. This gives your boat a little speed boost.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'To get the most out of your glowstone use a silk touch tool.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'Sand and gravel can be broken by saplings, rails, flowers, mushrooms, torches, redstone torches, levers, fence gates, and even string.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'You can get the maximum effect of a splash potion by throwing it in the sky and having it land on your body.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'If you\'re going up against silverfish, use the lighter so they can\'t reproduce.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'If you\'re fighting against the Wither, do so in a confined space so it can\'t maneuver and hurt you.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'If you open your inventory you can shift-click your armor on and off.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'In your inventory screen, you can use the hotkey numbers on your keyboard to choose where you want things to go. This also works with items.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'You can create a pool of water that can be infinitely used by putting two water sources in two corners of a square and taking water from each of the corners.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'The best lawnmower is a water bucket The best way to get rid of cobwebs is to use a water bucket, too.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'You can hop across entire oceans with enough skill and lily pads.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'When adventuring in caves you can use torches to block off water sources.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'While in water the following things give a little airpocket: fences, nether fences, iron bars, glass panes, fence gates, trap doors, ladders, slabs, doors, cobblestone walls, and signs.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'You can kill endermen easily by hitting them in the feet.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'Save the durability of your weapons by hitting monsters manually - by clicking slowly.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'Mushroom biomes have special properties: monsters don\'t spawn in at night.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'You can shoot/hit fireballs back at ghasts with arrows, your fist, and even snowballs.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'You can sneak while climbing up and down ladders so other players won\'t be able to detect you.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'When growing jungle trees, birch trees and spruce trees place them two blocks away from each other so they can grow. Oak saplings can be grown side by side.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'If ice has no solid block underneath it, nothing will happen when you break it. If ice has a solid block underneath it, it\'ll turn into water.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'If you have a pumpkin on your head endermen will not attack you. You can attack them without being attacked in return.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'While in water, creepers don\'t do any environmental damage. Neither does TNT.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'Monsters like the Blaze can be hurt with snowballs.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'When editing signs, you can use the up and down arrow keys to select the text row.', keywords: 'minecraft tip'
Message::Tip.send method, body: 'Never pet a burning dog.', keywords: 'wolf'
Message::Tip.send method, body: 'Sometimes spawning in the ocean is better.', keywords: 'water'
Message::Tip.send method, body: 'There is no Dana ...', keywords: 'only zuul'
Message::Tip.send method, body: 'Boats are broken.  They will always be broken.', keywords: 'lag world bedrock fell'
Message::Tip.send method, body: 'Wash dies.', keywords: 'firefly'
Message::Tip.send method, body: 'When in the ocean, try a bucket.', keywords: 'survive'
Message::Tip.send method, body: 'Cheating might cause hunger.', keywords: 'flying speed hacks cheaters'
Message::Tip.send method, body: 'You will never find a more wretched hive of scum and villainy.', keywords: 'obiwan'
Message::Tip.send method, body: 'Always dedotate your dedotated wam dedotation.', keywords: 'dedicated ram'
Message::Tip.send method, body: 'Server is up, what more do you want?', keywords: 'down'
Message::Tip.send method, body: 'Herobrine is alyways watching...', keywords: 'never'
Message::Tip.send method, body: 'slap @r', keywords: 'fish slappers'
Message::Tip.send method, body: '>mfw', keywords: 'my face when'
