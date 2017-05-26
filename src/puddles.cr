require "socket"
require "colorize"
require "./player"
require "./room"
require "./exceptions"
require "./npc"
require "yaml"
require "./room_creator"

Rooms = RoomCreator.from_yaml(File.read("./config/rooms.yml")).rooms
p Rooms

class ClientManagerClass
  property :clients
  @clients : Array(TCPSocket)
  @players : Hash(TCPSocket, Player)

  def initialize(@clients)
    @players = Hash(TCPSocket, Player).new
  end

  def remove(client)
    @clients.delete(client)
  end

  def find_player(client)
    @players[client]
  end

  def add_player(player, client)
    @players[client] = player
  end
end

server = TCPServer.new("0.0.0.0", 1234)
ClientManager = ClientManagerClass.new([] of TCPSocket)

def parse(player, command)
  case command
  when /connect (.*?) (.*)/
    begin
      player.login($1, $2)
      p player
      "Logged in as #{player.name}\n"
    rescue BadAuth
      "We're sorry but you entered an invalid username or password\n"
    end
  when "hello"
    "Hello there\n"
  when "l"
    player.room.display_contents
  when /^l (.*)/
    begin
      player.room.find($1).description + "\n"
    rescue ThingNotFound
      "Could not find what you're looking for\n"
    end
  when /^attack (.*)/
    begin
      player.room.find($1).as(Lifeform).attack(player)
      # rescue TypeCastError
      #   "That isn't a living thing!\n"
    rescue ThingNotFound
      "What? #{$1} doesn't even exist, man\n"
    end
  when /say (.*)/
    ClientManager.clients.each { |c| c << "#{player.name} says: #{$1}\n" }
  when "i"
    p "#{player} inv is #{player.inventory}"
    "Your pack contains: \n" +
      player.display_inventory +
      "Use `drop ITEM` to remove ITEM\n"
  when /^loot (.*)/
    begin
      player.loot($1)
    rescue InventoryEmpty
      "They don't have anything to loot\n"
    end
  when "fuzz"
    raise Exception.new
  when "commands"
    commands =<<-COMMANDS
    l - look at current room
    l NAME - look at thing named NAME
    attack NAME - attack thing named NAME
    loot NAME - loot thing named NAME
    say MESSAGE - broadcast MESSAGE to your current location
    get ITEM - put ITEM in your pack
    drop ITEM - drop ITEM on the ground
    list MERCHANT - list items for sale from MERCHANT
    buy ITEM MERCHANT - buy ITEM from MERCHANT
    COMMANDS
    commands + "\n"
  when /drop (.*)/
    begin
      player.get_from_pack($1)
      "You drop #{$1} onto the ground from your pack\n"
    rescue TypeCastError
      "That item isn't in your pack!\n"
    end
  when /get (.*)/
    begin
      player.get($1)
      player.room.broadcast("#{player.name} grabs #{$1} from room.")
      "You put #{$1} in your pack\n"
    rescue NotAnItem
      "That thing is not an item!\n"
    rescue ThingNotFound
      "That thing isn't even in this room!\n"
    end
  when /list (.*)/
    wares = player.room.find($1).as(NPC).wares.map(&.name).join("\n")
    if wares.empty?
      "Merchant has no items currently\n"
    else
      "These are the items available:\n#{wares}\n"
    end
  when /buy (.*?) (.*)/
    begin
      item =
        wares = player.room.find($2).as(NPC).wares
      item = wares.find do |item|
        item.name == $1
      end
      wares.delete(item)
      player.inventory.as(Array(Item)) << item.as(Item)
      "#{$1} added to your inventory\n"
    rescue TypeCastError
      "Merchant does not have that item available\n"
    rescue ThingNotFound
      "That isn't a Merchant\n"
    end
  when /cast (.*)/
    begin
      # player.can_magic = true
      player.cast $1
    rescue NotMagicUser
      "You are not a magic user\n"
    end
  when "n", "north"
    player.move :north, Rooms
  when "s", "south"
    player.move :south, Rooms
  when "e", "east"
    player.move :east, Rooms
  when "w", "west"
    player.move :west, Rooms
  else
    "I'm not sure I understood that command. Type `commands` to get a list of valid ones\n"
  end
end

def login(client)
  client << "Welcome to Puddles. A crystal language based MUD\n"
  client << "Enter your name to continue: "
  name = client.gets
  player = Player.new(client)
  ClientManager.add_player(player, client)
  player.name = name.as(String)
  Rooms[0].contents << player
  player.room = Rooms[0]
  client << "type `commands` to get a list of commands\n"
  client << player.room.display_contents
  player.room.broadcast("#{player.name} has entered the room\n")
  spawn do
    loop do
      begin
        response = parse(player, client.gets)
        client << response
      rescue Errno
        ClientManager.clients.delete(client)
        player.room.contents.delete(player)
        ClientManager.clients.each do |client|
          client << "#{player.name} just disconnected\n"
        end
        break
      rescue ex : Exception
        # player.room.contents.delete(player)
        # ClientManager.clients.delete(client)
        p ex.class
        p ex.message
        p ex.backtrace
      end
    end
  end
end

loop do
  client = server.accept
  ClientManager.clients << client
  login(client)
end
