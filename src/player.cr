require "./magic"
require "./yaml"
require "./lifeform"

class Player
  YAML.mapping(
    name: String,
    description: String,
    inventory: Array(Item),
    display_name: String,
    alive: Bool,
    room: Room
  )
  include Magic
  include Lifeform
  @socket : TCPSocket | Nil
  property :name, :inventory, :room, :socket

  def move(direction, rooms)
    room.contents.delete(self)
    exit = room.exit_rooms.find do |exit|
      exit.direction == direction.to_s
    end
    new_room = rooms.find do |room|
      room.name == exit.as(Exit).name
    end
    @room = new_room.as(Room)
    @room.contents << self
    "You move to the next room\n" +
      room.display_contents
  end

  def initialize(@socket)
    @room = Room.new
    @inventory = [] of Item
    @display_name = ""
    @alive = true
    @name = "placeholder"
    @description = "placeholder"
  end

  def login(name, password)
    @logged_in = true
    @name = name
    @room.contents << self
  end

  def get(thing_name)
    thing = room.find(thing_name)
    raise NotAnItem.new if !thing.is_a? Item
    @inventory.as(Array(Item)) << thing
    room.contents.delete(thing)
  end

  def get_from_pack(thing_name)
    thing = @inventory.as(Array(Item)).find do |item|
      item.name == thing_name
    end.as(Item)
    @inventory.as(Array(Item)).delete(thing)
    room.contents << thing
  end

  def loot(thing_name)
    thing = room.find(thing_name).as(Monster|Item)
    raise NotDeadYet.new if thing.is_a? Lifeform && thing.as(Lifeform).alive
    begin
      inv = @inventory.as(Array(Item))
    rescue TypeCastError
      raise InventoryEmpty.new
    end
    goods = thing.inventory.as(Array(Item))
    raise InvalidLootTarget.new if goods.empty?
    inv += goods
    @inventory = inv
    thing.inventory = [] of Item
    goods_display = goods.map(&.name).join(",")
    case thing
    when Lifeform
      "You stole #{goods_display} from the defenseless corpse of #{thing.name}\n"
    when Item
      "You stole #{goods_display} from #{thing.name}\n"
    end
  rescue NotDeadYet
    "You have to kill them before you can loot their corpse!\n"
  rescue ThingNotFound
    "You can loot something that isn't here!\n"
  rescue InvalidLootTarget
    "#{thing.as(Lifeform | Item).name} has nothing for you to loot\n"
  end


  def display_inventory
    @inventory.as(Array(Item)).map { |i| i.name + "\n" }.join
  end
end
