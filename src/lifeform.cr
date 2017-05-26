require "yaml"

module Lifeform
  @health = 100
  @alive = true

  property :alive

  def attack(player)
    # if @alive
    #   @alive = false
    #   "Awww... you killed the poor #{name}\n"
    # else
    #   "The #{name} is already dead, give it a rest, man.\n"
    # end
    if @health > 0
      @health -= 25
      player.room.broadcast("#{player.name} punches #{name} and damages them by 25%")
      if @health < 1
        @alive = false
        player.room.broadcast("#{player.name} has defeated #{name}")
      end
    else
      "#{display_name} is already dead, give it a rest\n"
    end
  end

  def display_inventory
    @inventory.as(Array(Item)).map { |i| i.name + "\n" }.join
  end

    def to_s
    tag = @display_name == @name ? "" : " [#{@name.colorize(:red)}]"
    if @alive
      "#{@display_name}#{tag} is here minding their own business <#{self.class}>\n"
    else
      "The corpse of #{@display_name}#{tag} is rotting here\n"
    end
  end
end
