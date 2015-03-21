sym ||= :create # Switch to :create! if you want to test full validation.

Preference.send sym, key: Preference::WEB_ADMIN_PASSWORD, value: '123456', system: 'f'
Preference.send sym, key: Preference::PATH_TO_SERVER, value: '/path/to/minecraft/server', system: 'f'
Preference.send sym, key: Preference::COMMAND_SCHEME, value: 'rcon', system: 'f'
Preference.send sym, key: Preference::MOTD, value: 'Welcome to the server!', system: 'f'
Preference.send sym, key: Preference::IRC_ENABLED, value: 'false', system: 'f'
Preference.send sym, key: Preference::IRC_INFO, value: 'Example: My Minecraft Server - hostname or IP - http://web-site-url', system: 'f'
Preference.send sym, key: Preference::IRC_WEB_CHAT_ENABLED, value: 'false', system: 'f'
Preference.send sym, key: Preference::IRC_WEB_CHAT_URL_LABEL, value: 'freenode.net', system: 'f'
Preference.send sym, key: Preference::IRC_WEB_CHAT_URL, value: 'http://webchat.freenode.net/?channels=%23my_channel&uio=d4', system: 'f'
Preference.send sym, key: Preference::IRC_SERVER_HOST, value: 'irc.freenode.net', system: 'f'
Preference.send sym, key: Preference::IRC_SERVER_PORT, value: '8000', system: 'f'
Preference.send sym, key: Preference::IRC_NICK, value: "cobblebot#{Random.rand(100)}", system: 'f'
Preference.send sym, key: Preference::IRC_CHANNEL, value: '#my_channel', system: 'f'
Preference.send sym, key: Preference::IRC_CHANNEL_OPS, value: '', system: 'f'
Preference.send sym, key: Preference::IRC_NICKSERV_PASSWORD, value: 'secret', system: 'f'

# System/Utility/Important ...
ServerCallback.send sym, name: 'Check Version', pattern: "/^@server version$/i", match_scheme: 'player_chat', command: "say \"@a\", \"CobbleBot version %cobblebot_version%\"\nsay_link \"@a\", \"http://github.com/inertia186/cobblebot\", only_title: true", system: 't'
ServerCallback.send sym, name: 'Autolink', pattern: "/http/i", match_scheme: 'player_chat', command: "say_link \"@a\", \"%message%\", nick: \"%nick%\"", system: 't'
ServerCallback.send sym, name: 'Message of the Day', pattern: "/([a-z0-9_]+) joined the game/i", match_scheme: 'server_message', command: "tell_motd \"%1%\"", system: 't'
ServerCallback.send sym, name: 'Sync Me', pattern: "/^@server syncme$/i", match_scheme: 'player_chat', command: "# This command will sometimes help players who are stuck.\nplay_sound \"%nick%\", \"smb_pipe\"\ntp \"%nick%\", \"~ ~ ~\"", cooldown: '+3 seconds', system: 't'
ServerCallback.send sym, name: 'Autosync', pattern: "/^([a-zA-Z0-9_]+) moved wrongly!/", match_scheme: 'server_message', command: "# This command will sometimes help players who are stuck, automatically.\ntp \"%1%\", \"~ ~ ~\"", system: 't'
ServerCallback.send sym, name: 'Sound Check', pattern: "/^@server soundcheck$/", match_scheme: 'player_chat', command: "# This command allows the player to test their sound configuration in\n# CobbleBot.  There is additional logic to demonstrate how commands\n# can interact with players, not just respond blindly.  This command\n# changes which sound to use depending on how many times the\n# command has been used.\n\n@@sound_check ||= 0\n@@sound_check = 1 + @@sound_check\n\nif @@sound_check == 4\n  play_sound \"%nick%\", \"sound_check_b\"\nelsif @@sound_check > 7\n  play_sound \"%nick%\", \"sound_check_c\"\n  @@sound_check = 0\nelse\n  play_sound \"%nick%\", \"sound_check_a\"\nend", system: 't'
ServerCallback.send sym, name: 'Player Authenticated', pattern: "/UUID of player ([a-zA-Z0-9_]+) is ([a-fA-Z0-9-]+)/", match_scheme: 'server_message', command: "irc_event \"%1% joined the game\"\nplayer_authenticated \"%1%\", \"%2%\"", system: 't'
ServerCallback.send sym, name: 'Latest Player Chat', pattern: "/.*/", match_scheme: 'player_chat', command: "update_player_last_chat \"%nick%\", \"%message%\"", system: 't'
ServerCallback.send sym, name: 'Latest Player IP', pattern: "/([a-zA-Z0-9_]+)\\[\\/([0-9\.]+):.+\\] logged in with entity id/", match_scheme: 'server_message', command: "update_player_last_ip \"%1%\", \"%2%\"", system: 't'
ServerCallback.send sym, name: 'Player Logged Out', pattern: "/^([a-zA-Z0-9_]+) lost connection/", match_scheme: 'server_message', command: "irc_event \"%1% left the game\"\ntouch_player_last_logged_out \"%1%\"", system: 't'
ServerCallback.send sym, name: 'Player Check', pattern: "/^@server playercheck ([a-z0-9_]+)$/i", match_scheme: 'player_chat', command: "say_playercheck \"@a\", \"%1%\"", system: 't'
ServerCallback.send sym, name: 'IRC Reply', pattern: "/^@irc (.*)$/i", match_scheme: 'player_chat', command: "irc_reply \"%nick%\", \"%1%\"", system: 't'
ServerCallback.send sym, name: 'Slap', pattern: "/^@server slap(.*)/i", match_scheme: 'player_chat', command: "target = \"%1%\".strip\n\nif target.present?\n  emote \"@a\", McSlap.slap(target)\nelse\n  emote \"@a\", \"has \#{McSlap.combinations} slap combinations, see:\"\n  say_link \"@a\", \"https://gist.github.com/inertia186/5002463\", only_title: true\nend", system: 't'

# Player initialted sounds ...
ServerCallback.send sym, name: 'To The Batcave!', pattern: "/^to the/i", match_scheme: 'player_chat', command: "play_sound \"@a\", \"to_the_batcave\"", cooldown: '+15 minutes', system: 'f'
ServerCallback.send sym, name: 'boo', pattern: "/halloween/i", match_scheme: 'player_chat', command: "play_sound \"@a\", \"mk64_boo_laugh\"", cooldown: '+15 minutes', system: 'f'
ServerCallback.send sym, name: 'SEGA', pattern: "/blast processing/i", match_scheme: 'player_chat', command: "play_sound \"@a\", \"sega\"", cooldown: '+15 minutes', system: 'f'
ServerCallback.send sym, name: 'Soon', pattern: "/soon/i", match_scheme: 'player_chat', command: "play_sound \"@a\", \"smb_warning\"", cooldown: '+15 minutes', system: 'f'
ServerCallback.send sym, name: 'Navi', pattern: "/!!!/", match_scheme: 'player_chat', command: "play_sound \"@a\", \"oot_navi_hey\"", cooldown: '+15 minutes', system: 'f'

# Death sounds ...
ServerCallback.send sym, name: 'Slain', pattern: "/was slain by/", match_scheme: 'server_message', command: "play_sound \"@a\", \"smb_mario_die\"", cooldown: '+15 minutes', system: 'f'
ServerCallback.send sym, name: 'Shot', pattern: "/was shot by/", match_scheme: 'server_message', command: "play_sound \"@a\", \"smb3_player_down\"", cooldown: '+15 minutes', system: 'f'
ServerCallback.send sym, name: 'Fell Out of the World', pattern: "/^[a-z0-9_]+ fell out of the world/", match_scheme: 'server_message', command: "play_sound \"@a\", \"goofy_holler\"", cooldown: '+15 minutes', system: 'f'
ServerCallback.send sym, name: 'Knocked Into the Void', pattern: "/was knocked into the void/", match_scheme: 'server_message', command: "play_sound \"@a\", \"goofy_holler\"", cooldown: '+15 minutes', system: 'f'
ServerCallback.send sym, name: 'Fell', pattern: "/^[a-zA-Z0-9_]+ fell from a high place/", match_scheme: 'server_message', command: "play_sound \"@a\", \"fallen\"", cooldown: '+15 minutes', system: 'f'
ServerCallback.send sym, name: 'Doomed to Fall', pattern: "/was doomed to fall/", match_scheme: 'server_message', command: "play_sound \"@a\", \"wilhelm\"", cooldown: '+15 minutes', system: 'f'
ServerCallback.send sym, name: 'Hit the Ground Too Hard', pattern: "/hit the ground too hard/", match_scheme: 'server_message', command: "play_sound \"@a\", \"fallen\"", cooldown: '+15 minutes', system: 'f'
ServerCallback.send sym, name: 'Starved to Death', pattern: "/starved to death/", match_scheme: 'server_message', command: "play_sound \"@a\", \"sm64_mario_mamma_mia\"", cooldown: '+15 minutes', system: 'f'
ServerCallback.send sym, name: 'Withered Away', pattern: "/withered away/", match_scheme: 'server_message', command: "play_sound \"@a\", \"mk64_boo_laugh\"", cooldown: '+15 minutes', system: 'f'
ServerCallback.send sym, name: 'Killed by Witch', pattern: "/killed by Witch/", match_scheme: 'server_message', command: "play_sound \"@a\", \"mk64_boo_laugh\"", cooldown: '+15 minutes', system: 'f'
ServerCallback.send sym, name: 'Killed Using Magic', pattern: "/was killed.*using magic/", match_scheme: 'server_message', command: "play_sound \"@a\", \"family_guy_bruce_oh_no\"", cooldown: '+15 minutes', system: 'f'
ServerCallback.send sym, name: 'Thorns', pattern: "/was killed trying to hurt/", match_scheme: 'server_message', command: "play_sound \"@a\", \"loz_shield\"", system: 'f'
ServerCallback.send sym, name: 'Burnt', pattern: "/was burnt to a crisp/", match_scheme: 'server_message', command: "play_sound \"@a\", \"family_guy_bruce_oh_no\"", system: 'f'
ServerCallback.send sym, name: 'Burned', pattern: "/burned to death/", match_scheme: 'server_message', command: "play_sound \"@a\", \"loz_die\"", cooldown: '+15 minutes', system: 'f'
ServerCallback.send sym, name: 'Lava Swim', pattern: "/tried to swim in lava/", match_scheme: 'server_message', command: "play_sound \"@a\", \"loz_die\"", cooldown: '+15 minutes', system: 'f'
ServerCallback.send sym, name: 'Cactus Death', pattern: "/pricked/", match_scheme: 'server_message', command: "play_sound \"@a\", \"loz_shield\"", system: 'f'
ServerCallback.send sym, name: 'Sploded Death', pattern: "/was blown up by/", match_scheme: 'server_message', command: "play_sound \"@a\", \"sadtrombone\"", cooldown: '+15 minutes', system: 'f'
ServerCallback.send sym, name: 'Anvil Death', pattern: "/squashed/", match_scheme: 'server_message', command: "play_sound \"@a\", \"oot_navi_watch_out\"", system: 'f'
ServerCallback.send sym, name: 'Bat Death?', pattern: "/by Bat/", match_scheme: 'server_message', command: "play_sound \"@a\", \"to_the_batcave\"", system: 'f'
ServerCallback.send sym, name: 'Fireball Death', pattern: "/fireballed/", match_scheme: 'server_message', command: "play_sound \"@a\", \"family_guy_bruce_oh_no\"", system: 'f'
ServerCallback.send sym, name: 'Just Died', pattern: "/died$/", match_scheme: 'server_message', command: "play_sound \"@a\", \"family_guy_bruce_what\"", system: 'f'

# Server sounds ...
ServerCallback.send sym, name: 'Flying Kick', pattern: "/was kicked for floating too long/", match_scheme: 'server_message', command: "play_sound \"@a\", \"smas_smb3_thud\"", system: 'f'
ServerCallback.send sym, name: 'Idle Kick', pattern: "/You have been idle for too long/", match_scheme: 'server_message', command: "play_sound \"@a\", \"smb3_pause\"", system: 'f'
ServerCallback.send sym, name: 'Another Client', pattern: "/You logged in from another location$/", match_scheme: 'server_message', command: "play_sound \"@a\", \"family_guy_bruce_what\"", system: 'f'

# Achievement sounds ...
ServerCallback.send sym, name: 'The Lie', pattern: "/The Lie/", match_scheme: 'server_message', command: "play_sound \"@a\", \"portal_still_alive\"", system: 'f'
ServerCallback.send sym, name: 'On A Rail', pattern: "/On A Rail/", match_scheme: 'server_message', command: "play_sound \"@a\", \"smw_course_clear\"", system: 'f'
ServerCallback.send sym, name: 'When Pigs Fly', pattern: "/When Pigs Fly/", match_scheme: 'server_message', command: "play_sound \"@a\", \"excellent\"", system: 'f'
ServerCallback.send sym, name: 'Sniper Duel', pattern: "/Sniper Duel/", match_scheme: 'server_message', command: "play_sound \"@a\", \"excellent\"", system: 'f'
ServerCallback.send sym, name: 'DIAMONDS', pattern: "/DIAMONDS/", match_scheme: 'server_message', command: "play_sound \"@a\", \"loz_secret\"", system: 'f'
ServerCallback.send sym, name: 'We Need to Go Deeper', pattern: "/We Need to Go Deeper/", match_scheme: 'server_message', command: "play_sound \"@a\", \"sm64_bowser_message\"", cooldown: '+15 minutes', system: 'f'
ServerCallback.send sym, name: 'Return to Sender', pattern: "/Return to Sender/", match_scheme: 'server_message', command: "play_sound \"@a\", \"excellent\"", system: 'f'
ServerCallback.send sym, name: 'Into Fire', pattern: "/Into Fire/", match_scheme: 'server_message', command: "play_sound \"@a\", \"loz_fanfare\"", system: 'f'
ServerCallback.send sym, name: 'Local Brewery', pattern: "/Local Brewery/", match_scheme: 'server_message', command: "play_sound \"@a\", \"smb_powerup\"", system: 'f'
ServerCallback.send sym, name: 'The End', pattern: "/The End/", match_scheme: 'server_message', command: "play_sound \"@a\", \"smb_pipe\"", system: 'f'
ServerCallback.send sym, name: 'Enchanter', pattern: "/Enchanter/", match_scheme: 'server_message', command: "play_sound \"@a\", \"smb_powerup\"", system: 'f'
ServerCallback.send sym, name: 'Overkill', pattern: "/Overkill/", match_scheme: 'server_message', command: "play_sound \"@a\", \"excellent\"", system: 'f'
ServerCallback.send sym, name: 'Librarian', pattern: "/Librarian/", match_scheme: 'server_message', command: "play_sound \"@a\", \"loz_secret\"", system: 'f'
ServerCallback.send sym, name: 'Adventuring Time', pattern: "/Adventuring Time/", match_scheme: 'server_message', command: "play_sound \"@a\", \"mk64_racestart\"", system: 'f'
ServerCallback.send sym, name: 'The Beginning', pattern: "/The Beginning[^\\?]/", match_scheme: 'server_message', command: "play_sound \"@a\", \"loz_secret\"", system: 'f'
ServerCallback.send sym, name: 'Beaconator', pattern: "/Beaconator/", match_scheme: 'server_message', command: "play_sound \"@a\", \"smb_powerup\"", system: 'f'
ServerCallback.send sym, name: 'Repopulation', pattern: "/Repopulation/", match_scheme: 'server_message', command: "play_sound \"@a\", \"smb_1up\"", system: 'f'
ServerCallback.send sym, name: 'Diamonds to you', pattern: "/Diamonds to you/", match_scheme: 'server_message', command: "play_sound \"@a\", \"smb_coin\"", system: 'f'
ServerCallback.send sym, name: 'Overpowered', pattern: "/Overpowered/", match_scheme: 'server_message', command: "play_sound \"@a\", \"sm64_key_get\"", system: 'f'

# Miscellaneous
ServerCallback.send sym, name: 'Number Guess', pattern: "/^@server numberguess(.*)$/i", match_scheme: 'player_chat', command: "# Number Guess.  This is a demonstration of how to store variables.  A new\n# number is picked every so often, usually whenever the worker restarts.\n\nargs = \"%1%\"\n\nif args.empty?\n  say \"@a\", \"Pick a number between 1 and 1000.  Each guess costs one Level of XP.  If you win, you get levels as a prize (more guesses = lower prize).  There is a random time limit on the secret number.  Multiple players may play simultaneously, but only the first correct guess wins. To guess, type: @server numberguess <guess>\", \"dark_purple\"\n\n  return\nend\n\nif @number.nil?\n  say \"@a\", \"A new secret number has been picked.\", \"green\"\n  @number ||= Random.rand(1000) + 1\n  @guess_count = 14\nend\n\nguess = args.split(' ')[0].to_i\n\nexecute \"xp -1L %nick%\"\n\n# Unfortunately, there's not a simple way to tell if the player reaches zero levels.\n\n@guess_count = @guess_count - 1\n\nsay \"@a\", \"%nick% guessed \#{guess}.  Too high.  Try again.\", \"red\" and return if guess > @number\nsay \"@a\", \"%nick% guessed \#{guess}.  Too low.  Try again.\", \"gold\" and return if guess < @number\n\n@guess_count = 0 if @guess_count < 0\nsay \"@a\", \"%nick% guessed it and won \#{pluralize @guess_count, 'level'}!  The number was \#{guess}!\", \"green\"\nexecute \"xp \#{@guess_count}L %nick%\"\n@number = nil", system: 'f'
ServerCallback.send sym, name: 'Grammar Nazi #001', pattern: "/([a-z]+ould) of/i", match_scheme: 'player_chat', command: "# When people say \"could of\" or similar, this command corrects them with\n# \"could have\" or similar.\n\nreturn if \"%message%\" =~ /of course/i\n\nThread.start do\n  sleep 5 # Don't reply right away.\n  say \"@a\", \"*%1% have\"\nend", cooldown: '+30 seconds', system: 'f'
ServerCallback.send sym, name: 'Dijon?', pattern: "/an expensive ([a-z]{4,})/i", match_scheme: 'player_chat', command: "Thread.start do\n  sleep 5\n  say \"@a\", \"Dijon %1%?\"\nend", cooldown: '+30 seconds', system: 'f'
ServerCallback.send sym, name: 'Embiggen', pattern: "/embiggen/i", match_scheme: 'player_chat', command: "Thread.start do\n  sleep 5\n  say \"@a\", \"... a perfectly cromulent word.\"\nend", cooldown: '+30 seconds', system: 'f'
ServerCallback.send sym, name: 'Captain Obvious', pattern: "/([a-z]+) [a-z]+ (is|are) \\1/i", match_scheme: 'player_chat', command: "Thread.start do\n  sleep 5\n  say \"@a\", \"We have a Captain Obvious over here.\"\nend", cooldown: '+30 seconds', system: 'f'
ServerCallback.send sym, name: 'CAPS', pattern: "/[A-Z]* [A-Z]* [A-Z]* [A-Z]*/", match_scheme: 'player_chat', command: "say \"@a\", \"Easy on the caps, please.\"", cooldown: '+30 seconds', system: 'f'
ServerCallback.send sym, name: 'Festivus', pattern: "/festivus/i", match_scheme: 'player_chat', command: "say \"@a\", \"... for the rest of us!\"", system: 'f'
