class Room
  property :contents
  @description : String
  @contents : Array(Item | Lifeform)

  def initialize(@description, @contents)
  end

  def display_contents
    @description + @contents.map(&.to_s).join
  end

  def find(name)
    p name
    thing = @contents.find do |thing|
      p thing.name
      thing.name == name
    end
    raise ThingNotFound.new if thing.nil?
    thing
  end

  def broadcast(msg, player)
    contents.each do |thing|
      if thing.class == Player && thing != player
        begin
          thing.as(Player).socket << msg
        rescue Errno
          # Client no longer active
        end
      end
    end
  end
end
