class Item
  property :inventory
  @inventory : Array(Item) | Nil
  YAML.mapping(
    name: String,
    description: String,
    durability: Int32
  )

  def to_s
    "A #{@name.colorize(:red)} is lying on the ground here\n"
  end
end
