require "../src/magicjson"

abstract struct Payload
  include MagicJSON

  json_defaults getter: true
  field client : Client, extra_field: true
end

struct User < Payload
  field username : String
  field bot? : Bool = false, key: "bot", setter: true

  def to_s(io)
    io << "@" << username
    io << " (bot)" if bot?
  end
end

struct Message < Payload
  field content : String
  field author : User, pass_extra_fields: {:client}
  # User is also a Payload and also needs a Client,
  # so we tell MagicJSON to forward the @client object
  # from Message to the new User
end

class Client
end

client = Client.new
msg = Message.from_json %{{"content":"Hello!", "author":{"username":"Zatherz", "bot":false}}}, client
puts msg.author.to_json
puts msg.author
msg.author.bot? = true
puts msg.author.to_json
puts msg.author
