class Monster < Lifeform
  def initialize(@name, @description, @inventory = [] of Item)
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
