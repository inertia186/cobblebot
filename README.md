cobblebot
=========

[![Build Status](https://travis-ci.org/inertia186/cobblebot.svg?branch=master)](https://travis-ci.org/inertia186/cobblebot) [![Code Climate](https://codeclimate.com/github/inertia186/cobblebot/badges/gpa.svg)](https://codeclimate.com/github/inertia186/cobblebot) [![Test Coverage](https://codeclimate.com/github/inertia186/cobblebot/badges/coverage.svg)](https://codeclimate.com/github/inertia186/cobblebot)

Minecraft Server Automation ... *For Vanilla*

CobbleBot is a rails application and external scripting tool that interacts with (vanilla) Minecraft SMP.  It primarily uses the server logs to detect events and can be configured to send commands back to the server with RCON and/or a multiplexor.

There is also an optional IRC bot that allows players to interact.

## Features

  * Player List + Today's Players
  * Server Status
  * Server Callbacks to define custom server behavior and interaction.
  * Message of the Day
  * Server Topics
  * Player tracking by UUID
  * IRC Bot with in-game messaging
  * Initial twitch.tv bot support
  * Optional Spam Detection + Warnings, Automatic Kick
  * IP Tracking
  * Web API for external administrative tasks
  * Google Translate
  * Optional Country Code lookup using db-ip.com
  * Donation Tracking
  * Tutorial and Rules templates.
  * IP Tracking (extras)
  * Web of Trust

## Installation

    $ mkdir cobblebot
    $ cd cobblebot
    $ git clone https://github.com/inertia186/cobblebot.git .
    $ bundle install
    $ rake db:migrate
    $ rake db:seed
    $ rails s
    $ open http://localhost:3000/admin/sessions/new

Now, use the default admin password to log in: `123456`

Click on the Admin drop-down, and select Preferences.

Edit the `web_admin_password` key and change it to something better.

Edit the `path_to_server` key and change it to the absolute path of your Minecraft Server.

Click on the Admin drop-down, and select Server Properties.  If it loads, then you are correctly configured.

Now install [Redis](http://redis.io/) so that you can run the monitors in the background using Resque.  This allows CobbleBot to process the server log.  Installation of Redis depends on your platform.

Mac OS X with MacPorts:

    $ sudo port install redis
    $ sudo port load redis

Ubuntu:

    $ apt-get install redis-server
    $ redis-server /etc/redis/redis.conf

Once Redis is up and running, start the CobbleBot scheduler and workers:

    $ BACKGROUND=yes RAILS_ENV='development' rake resque:scheduler
    $ TERM_CHILD=1 RAILS_ENV='development' QUEUE='minecraft_watchdog' rake resque:work
    $ TERM_CHILD=1 RAILS_ENV='development' QUEUE='minecraft_server_log_monitor' rake resque:work

If you've configured IRC, you need to start a worker for that as well:

    $ TERM_CHILD=1 RAILS_ENV='development' QUEUE='irc_bot' rake resque:work

### tmux - optional

If you like to use `tmux`, you can manage the various CobbleBot processes in a single `tmux` console.  Here's one way to go about that:

	#!/bin/bash

	BASE="$HOME/cobblebot"
	cd $BASE

	tmux start-server
	tmux new-session -d -s CobbleBot -n Project
	tmux new-window -t CobbleBot:1 -n resque-scheduler
	tmux new-window -t CobbleBot:2 -n watchdog
	tmux new-window -t CobbleBot:3 -n monitor
	tmux new-window -t CobbleBot:4 -n irc
	tmux new-window -t CobbleBot:5 -n server
	tmux new-window -t CobbleBot:6 -n dev-log

	tmux send-keys -t CobbleBot:0 "cd $BASE;" C-m
	tmux send-keys -t CobbleBot:1 "cd $BASE; RAILS_ENV='development' rake resque:scheduler" C-m
	tmux send-keys -t CobbleBot:2 "cd $BASE; TERM_CHILD=1 RAILS_ENV='development' QUEUE='minecraft_watchdog' rake resque:work" C-m
	tmux send-keys -t CobbleBot:3 "cd $BASE; TERM_CHILD=1 RAILS_ENV='development' QUEUE='minecraft_server_log_monitor' rake resque:work" C-m
	tmux send-keys -t CobbleBot:4 "cd $BASE; TERM_CHILD=1 RAILS_ENV='development' QUEUE='irc_bot' rake resque:work" C-m
	tmux send-keys -t CobbleBot:5 "sudo su steve" C-m
	tmux send-keys -t CobbleBot:6 "cd $BASE; tail -200 -f log/development.log" C-m

	tmux select-window -t CobbleBot:0
	tmux attach-session -t CobbleBot

Please note, the `CobbleBot:5` window is intended to kick off the actual Minecraft Server.  If you use the same user as CobbleBot to run your Minecraft Server, instead of `sudo su steve` you can just use `cd /path/to/minecraft_server`.

Once `CobbleBot:5` is there, you can execute the Minecraft Server:

    $ java -jar minecraft_server.jar

### Take it for a spin

Once all of the process are running, you should be able to log into your Minecraft Server and interact with CobbleBot.  For example, in the Minecraft client, type:

```
@server version
```

If IRC is enabled, players may send messages to IRC by typing, for example:

```
@irc Hello IRC!
```

In IRC, messages can be sent back to the game by typing, for example:

```
@cobblebot say Hello, Minecraft!
```

... or ...

```
@cb say Hello, Minecraft!
```

Enjoy!

## Installation Troubleshooting

### nokogiri

If you're having trouble with nokogiri, you might have some library conflicts.  One solution:

```
$ bundle config build.nokogiri --use-system-libraries
```

### better_errors

If you're having trouble with better_errors, you may need to update to a more recent version of ruby.  I suggest [rvm](https://rvm.io/).  If you have rvm, try:

```
$ rvm install 2.1.5
```

## Updating CobbleBot

Normally, migrations are simple.  The simple rake db:migrate should work but make sure the rails server is stopped.  Also stop the resque scheduler and workers.  Once everything has been stopped:

    $ cd cobblebot
    $ git pull
    $ rake db:migrate
    $ rake db:seed

Now you can start rails and resque.

Note, if you have trouble with the simple migrate, use the rake export commands to save your records and drop the database and import.  If do you see errors during migration, what follows is a more expanded method of migrating the database.

In early stages of development, migrations were non-cumulative.  This meant that early migrations required you to drop the database and start from scratch.  To mitigate this, CobbleBot can export data to CSV for re-import after the database is recreated.  As development progressed toward beta, migrations became cumulative so that export/import is not required during update.

## Export/Import

To export CobbleBot's database, make sure the rails server is stopped.  Also stop the resque scheduler and workers.  Once everything has been stopped:

    $ cd cobblebot
    $ rake cobblebot:export:preferences > preferences.csv
    $ rake cobblebot:export:players > players.csv
    $ rake cobblebot:export:links > links.csv
    $ rake cobblebot:export:server_callbacks > server_callbacks.csv
    $ rake cobblebot:export:messages > messages.csv
    $ rake cobblebot:export:ips > ips.csv
    $ rake cobblebot:export:mutes > mutes.csv
    $ rake cobblebot:export:reputations > reputations.csv
    $ rake db:migrate
    $ rake db:seed

You can import your data as follows:
    
    $ rake db:drop # only needed if previous migrations fail
    $ rake db:migrate
    $ cat preferences.csv | rake cobblebot:import:preferences
    $ cat players.csv | rake cobblebot:import:players
    $ cat links.csv | rake cobblebot:import:links
    $ cat server_callbacks.csv | rake cobblebot:import:server_callbacks
    $ cat messages.csv | rake cobblebot:import:messages
    $ cat ips.csv | rake cobblebot:import:ips
    $ cat mutes.csv | rake cobblebot:import:mutes
    $ cat reputations.csv | rake cobblebot:reputations:mutes
    $ rake db:seed
    
Now you can start rails and resque.

## Switching DBMS

The default DBMS for CobbleBot is SQLite3.  If you are getting IO errors or busy timeouts, this is due to the fact that CobbleBot is running multiple processes and SQLite3 isn't the right fit.  For light traffic servers, these errors are mitigated but not totally eliminated.

To avoid the problems associated with SQLite3, you should consider Postgres or MySQL.

Before you switch away from SQLite3, make sure you export your current database to CSV (see export steps above).

To enable Postgres, you need to change the following in database.yml (as diff):

    development:
    -  <<: *default
    -  database: db/development.sqlite3
    +  adapter: postgresql
    +  encoding: unicode
    +  database: cobblebot_development
    +  pool: 15
    +  username: cobblebot
    +  password:

Next, you need to create the postgres user and databases (assuming you've already installed Postgres):

    $ createuser -d -s cobblebot
    $ createdb -O cobblebot cobblebot_development
    $ createdb -O cobblebot cobblebot_test

Now, you can import the CSV data into Postgres (see import steps above).

Note, on Postgres, if you're attempting to drop the database and recreate it, you may need to close all existing connections first, e.g.:

    $ psql cobblebot_development -c "\
        SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity\
        WHERE pg_stat_activity.datname = 'cobblebot_development'\
        AND pid <> pg_backend_pid();"
    $ rake db:drop
    $ createdb -O cobblebot cobblebot_development

## Advantages

CobbleBot itself does not rely directly upon any Java API.  It does not require modifications to the server jar.  There are no plugins to Minecraft itself.  This means CobbleBot should (theoretically) run even in snapshots.

## Disadvantages

CobbleBot is limited to information that can be gathered from the server logs.  This means that most things a player does cannot be detected.  This also means that all interaction with CobbleBot will be public, for example, using `@server` in chat.  It can be configured to respond privately.

## TODO

  * Implement more test cases for DSL callback events.
  * Books
  * Improve twitch.tv bot support.

## Resource Pack

CobbleBot can be configured to trigger sound events.  To enable the default sounds, make sure your server.properties points at a copy of the default CobbleBot resource pack:

```
resource-pack=https\://www.dropbox.com/s/uq143k8dlftccla/swim_resource_pack.zip?dl\=1
```

To test the resource pack on the default configuration, type the command in the Minecraft client:

```
@server soundcheck
```

## Supported environments

* Minecraft 1.10 snapshots
* Minecraft 1.9.x

## Get in touch!

If you're using CobbleBot, I'd love to hear from you.  Drop me a line and tell me what you think!

## Licence

I don't believe in intellectual "property".  If you do, consider CobbleBot as licensed under a Creative Commons [![CC0](http://i.creativecommons.org/p/zero/1.0/80x15.png)] (http://creativecommons.org/publicdomain/zero/1.0/) License.
