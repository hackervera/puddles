require "./monster"
require "./mercantile"

class NPC < Monster
  include Mercantile
end
