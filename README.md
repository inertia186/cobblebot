cobblebot
=========

Minecraft Server Automation

Cobblebot is a rails application and external scripting tool that interacts with Minecraft SMP.  It primarily uses the server logs to detect events and can be configured to send commands back to the server with RCON and/or a multiplexor.

## Advantages

Cobblebot does not rely upon any Java API.  It does not require modifications to the server jar.  There are no plugins.  This means cobblebot should (theoretically) run even in snapshots.

## Disadvantages

Cobblebot is limited to information that can be gathered from the server logs.  This means that most things a player does cannot be detected.  This also means that all interaction with cobblebot will be public, for example, using @server in chat.  It can be configured to respond privately.

## TODO

  * Design a simple DSL for expressing callback events.
  * Implement test cases for DSL callback events.

## Resource Pack

Cobblebot can be configured to trigger sound events.  To enable the default sounds, make sure your server.properties points at a copy of the default cobblebot resource pack:

```
resource-pack=https\://www.dropbox.com/s/uq143k8dlftccla/swim_resource_pack.zip?dl\=1
```

To test the resource pack on the default configuration, type the command in Minecraft chat:

```
@server soundcheck
```

## Supported environments

* Minecraft 1.8.3

## Licence

I don't believe in intellectual "property".  If you do, consider cobblebot as licensed under a Creative Commons CC0 (Public Domain) License.
