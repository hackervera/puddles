module Magic
  property :can_magic
  @can_magic : Bool | Nil

  def ensure_magic
    raise NotMagicUser.new unless @can_magic
  end

  def cast(spellname)
    ensure_magic
    "You cast #{spellname}\n"
  end
end
