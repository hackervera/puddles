require "socket"
require "colorize"

class Lifeform
  property :inventory
  property :description
  @name : String | Nil
  @inventory : Array(Item) | Nil
  @description : String | Nil
  getter :name
  
  def attack(player)
    if @alive
      @alive = false
      "Awww... you killed the poor #{name}\n"
    else
      "The #{name} is already dead, give it a rest, man.\n"
    end
  end

  def display_inventory
    @inventory.as(Array(Item)).map{|i| i.name + "\n"}.join
  end
end

class Item
  getter :name, :description
  @name : String
  @description : String

  def initialize(@name, @description)
  end

  def to_s
    "A #{@name} is lying on the ground here\n"
  end
end

class Monster < Lifeform
  getter :name, :description

  def initialize(@name, @description)
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
      Monster.new("bunny", "A fluffy bunny\n").as(Lifeform | Item),
      Item.new("coin", "A shiny gold coin\n")
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
  @name : String | Nil
  getter :room, :name, :socket

  def initialize(@socket)
    @logged_in = :false
    @alive = true
    @inventory = [Item.new("card", "A magic playing card\n")]

    @room = Rooms.first
  end

  def login(name, password)
    @logged_in = true
    @name = name
    @room.contents << self
  end

  def to_s
    if @alive
      "A player named #{@name.colorize(:red)} is here minding their own business\n"
    else
      "The corpse of a dead player #{@name} is rotting here\n"
    end
  end
end

class BadAuth < Exception
end

class ThingNotFound < Exception
end

server = TCPServer.new("localhost", 1234)
Clients = [] of TCPSocket

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
    Clients.each { |c| c << "#{player.name} says: #{$1}\n" }
  when "i"
    "Your pack contains: \n" +
    player.display_inventory + 
    "Use `get THING from pack` to remove item\n"

  else
    "I'm not sure I understood that command\n"
  end
end

def login(client)
  client << "Welcome to Puddles. A crystal language based MUD\n"
  player = Player.new(client)
  spawn do
    loop do
      response = parse(player, client)
      client << response
    end
  end
end

loop do
  client = server.accept
  Clients << client
  login(client)
end
