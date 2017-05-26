class Thing
  @inventory : Array(Item)
  property :inventory, :name, :description

  getter :name, :description
  @name : String
  @description : String

  def initialize(@name, @description)
    @inventory = [] of Item
  end
end
