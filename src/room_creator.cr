require "yaml"
require "./monster"
require "./room"
require "./lifeform"

class RoomCreator
  YAML.mapping(
    rooms: Array(Room)
  )
end
