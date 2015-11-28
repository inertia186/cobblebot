ENV['RAILS_ENV'] ||= 'test'

if ENV["HELL_ENABLED"]
  require 'simplecov'
  SimpleCov.start 'rails'
  SimpleCov.merge_timeout 3600

  require 'database_cleaner'
end

require File.expand_path('../../config/environment', __FILE__)
require 'rcon/rcon'
require 'rails/test_help'
require 'webmock/minitest'
require "codeclimate-test-reporter"
require 'capybara/rails'
require 'capybara/poltergeist'
require 'capybara-screenshot/minitest'

if ENV["HELL_ENABLED"]
  require "minitest/hell"
else
  require "minitest/pride"
end

WebMock.disable_net_connect!(allow_localhost: true, allow: 'codeclimate.com:443')
CodeClimate::TestReporter.start

phantomjs_logger = if ENV['TESTOPTS'].to_s.include?('--verbose')
  $stdout
else
  File.open("log/test_phantomjs.log", "a")
end

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, {
    phantomjs: Phantomjs.path,
    phantomjs_logger: phantomjs_logger,
    debug: false,
    timeout: 15,
    js_errors: true,
    inspector: true,
    extensions: [
      'test/support/scripts/angular_errors.js'
    ]
  })
end

Capybara.javascript_driver = :poltergeist
Capybara.default_driver = :poltergeist
Capybara.default_max_wait_time = 15

Capybara::Screenshot.prune_strategy = { keep: 20 }

Rails.application.load_seed

module TestTools
  def skip_until_pass(options = {when_passes: "This test is now passing, please revise."}, &block)
    begin
      yield block
    rescue Minitest::Assertion
      skip 'Skipped assertion until fixed.'
    rescue ActionView::Template::Error
      skip 'Skipped template error until fixed.'
    end

    fail options[:when_passes]
  end
end

class ActionDispatch::IntegrationTest
  include TestTools
  include Capybara::DSL
  include Capybara::Angular::DSL
  include Capybara::Screenshot::MiniTestPlugin

  # Never use transactional fixtures with integration tests.
  self.use_transactional_fixtures = false

  fixtures :all

  def before_setup
    if defined? DatabaseCleaner
      DatabaseCleaner.strategy = :truncation
      DatabaseCleaner.start
    end
    super
  end

  def after_teardown
    super
    DatabaseCleaner.clean if defined? DatabaseCleaner
    Capybara.reset_session!
  end

  def admin_sign_in
    visit '/'
    find_link('Admin').click
    find_link('Log In').click
    fill_in 'admin_password', with: preferences(:web_admin_password).value
    find_button('Login').click
  end

  def ajax_sync(strategy = :skip, message = "AJAX was too slow.")
    # May become 'jQuery.ajax.active' in future releases.
    jquery_not_active = page.evaluate_script('jQuery.active').zero?
    angular_not_active = page.evaluate_script("angular.element(document.body).injector().get('$http').pendingRequests.length").zero?

    if jquery_not_active && angular_not_active
      # success
    else
      send strategy, message
    end
  end

  def admin_sign_out
    visit '/'
    find_link('Admin').click
    find_link('Admin Log Out').click
  end

  def save_screenshot(filename = Time.now.to_i)
    page.save_screenshot "tmp/capybara/manual-screenshot-#{filename}.png", :full => true
  end

  def save_screenshot_and_skip(message = nil)
    save_screenshot

    if !!message
      skip "Skipped integration: #{message}"
    else
      skip 'Skipped integration.'
    end
  end
end

class ActiveSupport::TestCase
  include TestTools

  if defined? DatabaseCleaner
    DatabaseCleaner.clean_with(:truncation)
    self.use_transactional_fixtures = false
  else
    self.use_transactional_fixtures = true
  end

  fixtures :all

  def before_setup
    if defined? DatabaseCleaner
      DatabaseCleaner.strategy = :transaction
      DatabaseCleaner.start
    end
    super
  end

  def after_teardown
    super
    DatabaseCleaner.clean if defined? DatabaseCleaner
  end

  def integrated_admin_sign_in
    params = {
      admin_password: Preference.web_admin_password
    }

    delete admin_destroy_session_url
    post admin_sessions_url(params)
  end

  def ServerCommand.kick(nick, message = "Have A Nice Day")
    super

    kicked[nick] = message
  end

  def ServerCommand.execute(command)
    commands_executed[command] = !!super
  end

  def ServerCommand.commands_executed
    @commands_executed ||= {}
  end

  def ServerCommand.reset_commands_executed
    @commands_executed = nil
  end

  def ServerCommand.kicked
    @kicked ||= {}
  end

  def response_json
    JSON.parse(response.body)
  end

  def api_version(version)
    @request.headers['Accept'] = "application/vnd.cobblebot.v#{version}"
  end

  def request_token(value)
    @request.headers['Authorization'] = %[Token token="#{value}"]
  end

  def assert_kicked(nick, &block)
    yield block

    assert ServerCommand.kicked.keys.include?(nick), "expect player kicked: #{nick}"
  end

  def refute_kicked(nick, &block)
    yield block

    refute ServerCommand.kicked.keys.include?(nick), "expect player kicked: #{nick}"
  end

  def assert_command_executed(&block)
    ServerCommand.reset_commands_executed
    yield block
    refute_equal 0, ServerCommand.commands_executed.size, 'expect command to execute'
  end

  def assert_callback_ran(callback, options = {inverted: false}, &block)
    c = if callback.class == String
      ServerCallback.find_by_name(callback)
    else
      callback
    end
    raise CobbleBotError.new(message: "Unknown callback: #{callback}") if c.nil?

    ran_at = c.ran_at
    yield block
    if !!options[:inverted]
      assert_equal ran_at, c.reload.ran_at, "did not expect callback \"#{c.name}\" to run"
      assert ran_at == c.reload.ran_at || c.error_flag_at, "callback ran or got error: #{c.last_command_output}"
    else
      refute_equal ran_at, c.reload.ran_at, "expect callback \"#{c.name}\" to run"
      refute c.error_flag_at, "callback \"#{c.name}\" ran, but got error: #{c.last_command_output}"
    end
  end

  def refute_callback_ran(callback = nil, &block)
    if callback.nil?
      ServerCallback.find_each do |c|
        !assert_callback_ran(c, inverted: true, &block)
      end
    else
      !assert_callback_ran(callback, inverted: true, &block)
    end
  rescue
    true
  end
end

class ActiveRecord::Base
  before_save do |record|
    if record.respond_to? :last_command_output
      record.last_command_output ||= 'FAKE SERVER OUTPUT'
    end
  end
end

tmp = Preference.path_to_server = "#{Rails.root}/tmp"
Dir.mkdir(tmp) unless File.exists?(tmp)

fake_logs = "#{tmp}/logs"
Dir.mkdir(fake_logs) unless File.exists?(fake_logs)
fake_latest_log = "#{fake_logs}/latest.log"

File.delete(fake_latest_log) if File.exists?(fake_latest_log)
File.open(fake_latest_log, 'a') do |f|
  startup_event = <<-DONE
    [07:38:13] [Server thread/INFO]: Starting minecraft server version 1.8.3
    [07:38:13] [Server thread/INFO]: Loading properties
    [07:38:13] [Server thread/INFO]: Default game type: SURVIVAL
    [07:38:13] [Server thread/INFO]: Generating keypair
    [07:38:13] [Server thread/INFO]: Starting Minecraft server on *:25565
    [07:38:13] [Server thread/INFO]: Using default channel type
    [07:38:13] [Server thread/INFO]: Preparing level "world"
    [07:38:14] [Server thread/INFO]: Preparing start region for level 0
    [07:38:15] [Server thread/INFO]: Preparing spawn area: 24%
    [07:38:16] [Server thread/INFO]: Preparing spawn area: 74%
    [07:38:16] [Server thread/INFO]: Done (2.656s)! For help, type "help" or "?"
    [07:38:16] [Server thread/INFO]: Starting GS4 status listener
    [07:38:16] [Server thread/INFO]: Starting remote control listener
    [07:38:16] [Query Listener #1/INFO]: Query running on 0.0.0.0:25565
    [07:38:16] [RCON Listener #2/INFO]: RCON running on 0.0.0.0:25575
    [14:58:10] [User Authenticator #3/INFO]: UUID of player inertia186 is d6edf996-6182-4d58-ac1b-4ca0321fb748
    [14:58:10] [Server thread/INFO]: inertia186[/127.0.0.1:59723] logged in with entity id 44688 at (15.557474447143854, 74.0, 249.30806519239542)
    [14:58:10] [Server thread/INFO]: inertia186 joined the game
    [15:04:50] [Server thread/INFO]: <inertia186> You try to swing an axe at Shia Labeouf.
  DONE
  startup_event.each_line do |line|
    f << line.strip + "\n"
  end
  f.sync
end

fake_server_properties = "#{tmp}/server.properties"

File.delete(fake_server_properties) if File.exists?(fake_server_properties)
File.open(fake_server_properties, 'a') do |f|
  server_properties = <<-DONE
  #Minecraft server properties
  #Thu Apr 09 07:38:13 PDT 2015
  spawn-protection=16
  max-tick-time=60000
  query.port=25565
  generator-settings=
  force-gamemode=false
  allow-nether=true
  gamemode=0
  enable-query=true
  player-idle-timeout=0
  difficulty=1
  spawn-monsters=true
  broadcast-rcon-to-ops=true
  op-permission-level=4
  resource-pack-hash=b19317b86580f607676c19c1a60d0b87
  announce-player-achievements=true
  pvp=true
  snooper-enabled=true
  level-type=DEFAULT
  hardcore=false
  enable-command-block=false
  max-players=20
  network-compression-threshold=256
  max-world-size=29999984
  rcon.port=25575
  server-port=25565
  debug=false
  server-ip=
  spawn-npcs=true
  allow-flight=false
  level-name=world
  view-distance=10
  resource-pack=https\://www.dropbox.com/s/uq143k8dlftccla/swim_resource_pack.zip?dl\=1
  spawn-animals=true
  white-list=false
  rcon.password=password
  generate-structures=true
  max-build-height=256
  online-mode=true
  level-seed=
  enable-rcon=true
  motd=A Minecraft Server
  DONE
  server_properties.each_line do |line|
    f << line.strip + "\n"
  end
  f.sync
end

fake_world = "#{tmp}/world"
Dir.mkdir(fake_world) unless File.exists?(fake_world)
fake_stats = "#{fake_world}/stats"
Dir.mkdir(fake_stats) unless File.exists?(fake_stats)
fake_inertia186_stats = "#{fake_stats}/d6edf996-6182-4d58-ac1b-4ca0321fb748.json"

File.delete(fake_inertia186_stats) if File.exists?(fake_inertia186_stats)
File.open(fake_inertia186_stats, 'a') do |f|
  inertia186_stats = <<-DONE
  {
    "stat.useItem.minecraft.bow":10,
    "achievement.buildHoe":2,
    "stat.leaveGame":212,
    "achievement.killWither":1,
    "stat.useItem.minecraft.soul_sand":4,
    "stat.useItem.minecraft.skull":3,
    "stat.useItem.minecraft.diamond_sword":22,
    "stat.useItem.minecraft.potion":3,
    "stat.jump":256,
    "stat.swimOneCm":11246,
    "stat.fallOneCm":174203,
    "achievement.buildWorkBench":2,
    "stat.crouchOneCm":148,
    "stat.craftItem.minecraft.iron_ingot":1,
    "stat.useItem.minecraft.obsidian":14,
    "stat.useItem.minecraft.dirt":1,
    "achievement.exploreAllBiomes":{
      "value":0,
      "progress":[
        "Beach",
        "ForestHills",
        "River",
        "Plains",
        "Desert",
        "The End",
        "Savanna",
        "Hell"
      ]
    },
    "achievement.overpowered":1,
    "stat.craftingTableInteraction":14,
    "stat.craftItem.minecraft.golden_apple":1,
    "stat.craftItem.minecraft.furnace":1,
    "achievement.blazeRod":1,
    "achievement.diamondsToYou":1,
    "stat.brewingstandInteraction":4,
    "stat.damageTaken":23450,
    "achievement.diamonds":10,
    "achievement.bakeCake":1,
    "stat.craftItem.minecraft.stone_pickaxe":1,
    "stat.useItem.minecraft.furnace":1,
    "stat.craftItem.minecraft.wooden_sword":1,
    "stat.flyOneCm":172678,
    "stat.useItem.minecraft.end_portal_frame":42,
    "achievement.buildPickaxe":2,
    "stat.entityKilledBy.Zombie":8,
    "stat.craftItem.minecraft.wooden_hoe":1,
    "stat.damageDealt":5255,
    "achievement.buildBetterPickaxe":1,
    "stat.timeSinceDeath":18590,
    "stat.mineBlock.minecraft.dirt":2,
    "stat.useItem.minecraft.crafting_table":3,
    "stat.craftItem.minecraft.wooden_pickaxe":1,
    "achievement.theEnd":3,
    "stat.craftItem.minecraft.cake":1,
    "stat.walkOneCm":169594,
    "stat.useItem.minecraft.torch":3,
    "stat.playerKills":2,
    "achievement.spawnWither":1,
    "stat.furnaceInteraction":2,
    "stat.craftItem.minecraft.crafting_table":1,
    "achievement.enchantments":2,
    "achievement.theEnd2":8,
    "stat.entityKilledBy.Skeleton":10,
    "achievement.overkill":22,
    "achievement.buildSword":2,
    "achievement.mineWood":1,
    "stat.useItem.minecraft.dragon_egg":1,
    "stat.sprintOneCm":13270,
    "stat.craftItem.minecraft.brewing_stand":1,
    "stat.killEntity.Skeleton":2,
    "stat.craftItem.minecraft.bookshelf":1,
    "achievement.portal":3,
    "achievement.openInventory":69,
    "stat.craftItem.minecraft.planks":4,
    "stat.useItem.minecraft.flint_and_steel":2,
    "stat.killEntity.Spider":1,
    "stat.useItem.minecraft.ender_eye":36,
    "stat.mobKills":6,
    "achievement.killEnemy":2,
    "achievement.buildFurnace":2,
    "stat.deaths":60,
    "achievement.acquireIron":1,
    "stat.drop":19,
    "stat.playOneMinute":4557311,
    "achievement.bookcase":2,
    "stat.useItem.minecraft.wooden_sword":5,
    "stat.killEntity.Zombie":2,
    "stat.useItem.minecraft.brewing_stand":1,
    "stat.diveOneCm":3574,
    "stat.craftItem.minecraft.enchanting_table":1,
    "achievement.potion":3
  }
  DONE
  inertia186_stats.each_line do |line|
    f << line.strip + "\n"
  end
  f.sync
end

fake_banned_players = "#{tmp}/banned-players.json"
File.delete(fake_banned_players) if File.exists?(fake_banned_players)
File.open(fake_banned_players, 'a') do |f|
  banned_players = <<-DONE
  [
    {
      "uuid": "3d961040-c795-4238-b273-b5a5a17b62b8",
      "name": "FreakyFalse",
      "created": "2014-10-27 14:29:42 -0700",
      "source": "Rcon",
      "expires": "forever",
      "reason": "flyhack"
    }
  ]
  DONE
  banned_players.each_line do |line|
    f << line.strip + "\n"
  end
  f.sync
end

fake_banned_ips = "#{tmp}/banned-ips.json"
File.delete(fake_banned_ips) if File.exists?(fake_banned_ips)
File.open(fake_banned_ips, 'a') do |f|
  banned_ips = <<-DONE
  [
    {
      "ip": "",
      "created": "2014-03-07 10:09:51 -0800",
      "source": "(Unknown)",
      "expires": "forever",
      "reason": "Banned by an operator."
    },
    {
      "ip": "58.171.33.123",
      "created": "2014-05-26 21:41:31 -0700",
      "source": "Rcon",
      "expires": "forever",
      "reason": "security problem detected"
    }
  ]
  DONE
  banned_ips.each_line do |line|
    f << line.strip + "\n"
  end
  f.sync
end

fake_ops = "#{tmp}/ops.json"
File.delete(fake_ops) if File.exists?(fake_ops)
File.open(fake_ops, 'a') do |f|
  ops = <<-DONE
  [
    {
      "uuid": "d6edf996-6182-4d58-ac1b-4ca0321fb748",
      "name": "inertia186",
      "level": 4
    }
  ]
  DONE
  ops.each_line do |line|
    f << line.strip + "\n"
  end
  f.sync
end

fake_whitelist = "#{tmp}/whitelist.json"
File.delete(fake_whitelist) if File.exists?(fake_whitelist)
File.open(fake_whitelist, 'a') do |f|
  whitelist = <<-DONE
  [
    {
      "uuid": "d6edf996-6182-4d58-ac1b-4ca0321fb748",
      "name": "inertia186"
    }
  ]
  DONE
  whitelist.each_line do |line|
    f << line.strip + "\n"
  end
  f.sync
end

if !!ENV['HELL_ENABLED'] # No colors in hell.
  COLORS =
    {
      "black"   => 0,
      "red"     => 1,
      "green"   => 2,
      "yellow"  => 3,
      "blue"    => 4,
      "purple"  => 5,
      "magenta" => 5,
      "cyan"    => 6,
      "white"   => 7
    }
  COLORS.each_pair do |color, value|
    CapybaraScreenshot::Helpers.send(:define_method, color) do |text|
      text if ENV['TESTOPTS'].include?('--verbose')
    end

    CapybaraScreenshot::Helpers.send(:define_method, "bright_#{color}") do |text|
      text if ENV['TESTOPTS'].include?('--verbose')
    end
  end
end

if Server.up?
  # TODO Eventually, this warning should only warn and not actually raise an
  # exception.  For now, we're just trying to be safe.
  raise CobbleBotError.new(message: "Warning, you are running a live minecraft server which tests are trying to fiddle with.")
end
