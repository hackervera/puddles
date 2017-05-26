require "./lifeform"
require "./magic"

class Player < Lifeform
  include Magic
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

  def get(thing_name)
    thing = room.find(thing_name)
    raise NotAnItem.new if !thing.is_a? Item
    @inventory << thing
    room.contents.delete(thing)
  end

  def get_from_pack(thing_name)
    thing = @inventory.find do |item|
      item.name == thing_name
    end.as(Item)
    @inventory.delete(thing)
    room.contents << thing
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
