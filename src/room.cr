require "yaml"
require "./item"

class Exit
  YAML.mapping(
    name: String,
    direction: String
  )
end

class Room
  def initialize
    @description = ""
    @name = ""
    @exit_rooms = [] of Exit
    @contents = [] of Item | NPC | Player | Monster 
  end

  YAML.mapping(
    description: String,
    name: String,
    exit_rooms: Array(Exit),
    contents: Array(Monster | Player | Item | NPC)
  )
  property :contents

  # @contents : Array(Item | Lifeform)

  # def initialize(@description, @contents, @name, @exit_rooms)

  # end

  def display_contents
    @description + "\n" + @contents.map(&.to_s).join +
      "Exits: " + exit_rooms.map(&.direction).join(", ") + "\n"
  end

  def find(name)
    thing = @contents.find do |thing|
      thing.name == name
    end
    raise ThingNotFound.new if thing.nil?
    thing
  end

  def broadcast(msg)
    contents.each do |thing|
      if thing.class == Player
        thing.as(Player).socket.as(TCPSocket) << "[room broadcast] #{msg}\n"
      end
    end
  end
end
