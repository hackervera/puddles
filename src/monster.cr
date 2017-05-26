require "./lifeform"

class Monster
  YAML.mapping(
    name: String,
    description: String,
    inventory: Array(Item),
    display_name: String,
  )
  include Lifeform

  def initialize(@name, @description, @inventory = [] of Item, display_name = "")
    @display_name = display_name || @name
  end


end
