require "./thing"

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
