require "./lifeform"
require "./mercantile"

class NPC
  include Lifeform
  YAML.mapping(
    wares: Array(Item),
    name: String,
    description: String,
    display_name: String,
  )

end
