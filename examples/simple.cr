require "../src/magicjson"

struct User
  include MagicJSON

  json_defaults getter: true
  field username : String, setter: true
end

user = User.from_json %{{"username":"Test"}}
puts user.to_json
puts user.username
user.username = "Zatherz"
puts user.to_json
puts user.username
