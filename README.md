cobblebot
=========

Minecraft Server Automation ... *For Vanilla*

CobbleBot is a rails application and external scripting tool that interacts with (vanilla) Minecraft SMP.  It primarily uses the server logs to detect events and can be configured to send commands back to the server with RCON and/or a multiplexor.

There is also an optional IRC bot that allows players to interact.

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

Now you should be able to log into your Minecraft Server and interact with CobbleBot.  For example, in the Minecraft client, type:

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

## Advantages

CobbleBot does not rely upon any Java API.  It does not require modifications to the server jar.  There are no plugins to Minecraft itself.  This means CobbleBot should (theoretically) run even in snapshots.

## Disadvantages

CobbleBot is limited to information that can be gathered from the server logs.  This means that most things a player does cannot be detected.  This also means that all interaction with CobbleBot will be public, for example, using `@server` in chat.  It can be configured to respond privately.

## TODO

  * Expand DSL for more complex tasks (like in-game Mail and Web of Trust).
  * Implement more test cases for DSL callback events.

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

* Minecraft 1.8.3

## Licence

I don't believe in intellectual "property".  If you do, consider CobbleBot as licensed under a Creative Commons CC0 (Public Domain) License.
