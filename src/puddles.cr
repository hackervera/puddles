require "socket"
require "colorize"

class Thing
  @inventory : Array(Item)
  property :inventory, :name, :description

    getter :name, :description
  @name : String 
  @description : String

  def initialize(@name, @description)
    @inventory = [] of Item
  end
end

class ClientManagerClass
  property :clients
  @clients : Array(TCPSocket)
  def initialize(@clients)
  end
end

class Lifeform < Thing
  getter :alive
  def attack(player)
    if @alive
      @alive = false
      "Awww... you killed the poor #{name}\n"
    else
      "The #{name} is already dead, give it a rest, man.\n"
    end
  end

  def display_inventory
    @inventory.as(Array(Item)).map { |i| i.name + "\n" }.join
  end
end

class Item < Thing


  def to_s
    "A #{@name} is lying on the ground here\n"
  end


end

class Monster < Lifeform

  def initialize(@name, @description, @inventory = [] of Item)
    @alive = true
  end

  def to_s
    if @alive
      "A #{@name.colorize(:red)} is here minding its own business\n"
    else
      "The corpse of a dead #{@name} is rotting here\n"
    end
  end
end

Rooms = [
  Room.new(
    description: "You are in the starting room. Nothing much is here yet.\n",
    contents: [
      Monster.new("bunny", "A fluffy bunny\n", [Item.new("foot", "A lucky rabbit's foot\n")]),
      Item.new("coin", "A shiny gold coin\n"),
    ]
  ),
]

class Room
  property :contents
  @description : String
  @contents : Array(Item | Lifeform)

  def initialize(@description, @contents)
  end

  def display_contents
    @description + @contents.map(&.to_s).join
  end

  def find(name)
    p name
    thing = @contents.find do |thing|
      p thing.name
      thing.name == name
    end
    raise ThingNotFound.new if thing.nil?
    thing
  end

  def broadcast(msg, player)
    contents.each do |thing|
      if thing.class == Player && thing != player
        thing.as(Player).socket << msg
      end
    end
  end
end

class Player < Lifeform
  @socket : TCPSocket
  @room : Room
  getter :room, :socket

  def initialize(@socket)
    @logged_in = :false
    @alive = true
    @inventory = [Item.new("card", "A magic playing card\n")]
    @name = "placeholder"
    @description = "placeholder"
    @room = Rooms.first
  end

  def login(name, password)
    @logged_in = true
    @name = name
    @room.contents << self
  end

  def loot(thing_name)
    thing = room.find(thing_name)
    raise NotDeadYet.new if thing.is_a? Lifeform && thing.as(Lifeform).alive
    inv = @inventory.as(Array(Item))
    goods = thing.inventory.as(Array(Item))
    raise InvalidLootTarget.new if goods.empty?
    inv += goods
    @inventory = inv
    thing.inventory = [] of Item
    goods_display = goods.map(&.name).join(",")
    case thing
    when  Lifeform
      "You stole #{goods_display} from the defenseless corpse of #{thing.name}\n"
    when  Item
      "You stole #{goods_display} from #{thing.name}\n"
    end

  rescue NotDeadYet
    "You have to kill them before you can loot their corpse!\n"
  rescue ThingNotFound
    "You can loot something that isn't here!\n"
  rescue InvalidLootTarget
    "#{thing.as(Thing).name} has nothing for you to loot\n"
  end

  def to_s
    if @alive
      "A player named #{@name.colorize(:red)} is here minding their own business\n"
    else
      "The corpse of a dead player named #{@name.colorize(:red)} is rotting here\n"
    end
  end
end

class InvalidLootTarget < Exception
end

class BadAuth < Exception
end

class ThingNotFound < Exception
end

class NotDeadYet < Exception
end

class InvalidLootTarget < Exception
end

server = TCPServer.new("localhost", 1234)
ClientManager = ClientManagerClass.new([] of TCPSocket)

def parse(player, client)
  case client.gets
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
      player.room.find($1).description
    rescue ThingNotFound
      "Could not find what you're looking for\n"
    end
  when /^attack (.*)/
    begin
      player.room.broadcast("WTF!! #{player.name} is attacking #{$1}\n", player)
      player.room.find($1).as(Lifeform).attack(player)
    rescue TypeCastError
      "That isn't a living thing!\n"
    rescue ThingNotFound
      "What? #{$1} doesn't even exist, man\n"
    end
  when /say (.*)/
    ClientManager.clients.each { |c| c << "#{player.name} says: #{$1}\n" }
  when "i"
    p "#{player} inv is #{player.inventory}"
    "Your pack contains: \n" +
      player.display_inventory +
      "Use `get THING from pack` to remove item\n"
  when /^loot (.*)/
    player.loot($1)
  else
    "I'm not sure I understood that command\n"
  end
end

def login(client)
  client << "Welcome to Puddles. A crystal language based MUD\n"
  client << "Enter your name to continue: "
  name = client.gets
  player = Player.new(client)
  player.name = name.as(String)
  player.room.contents << player
  client << player.room.display_contents
  player.room.broadcast("#{player.name} has entered the room\n", player)
  spawn do
    loop do
      response = parse(player, client)
      client << response
    end
  end
end

spawn do
  loop do
    ClientManager.clients = ClientManager.clients.reject do |client|
      client.closed?
    end
    sleep 2
  end
end

loop do
  client = server.accept
  ClientManager.clients << client
  login(client)
end
