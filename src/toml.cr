require "yaml"
puts YAML.parse(File.read("./config/rooms.yml"))
