module Mercantile
  class Store
    getter :wares

    def initialize(@wares = [] of Item)
    end
  end

  def create_store(items)
    @store = Store.new(items)
  end

  def wares
    @store.as(Store).wares
  end
end
