require "../src/magicjson"

module SnowflakeConverter
  # JSON payloads have 64 unsigned ints as strings
  # to avoid losing precision

  def self.from_json(parser : JSON::PullParser)
    parser.read_string.to_u64
  end

  def self.to_json(value : UInt64, builder : JSON::Builder)
    builder.scalar value.to_s
  end
end

module AutoIdentifiableConverter(T)
  def self.from_chatprog_json(parser : JSON::PullParser, client : Client)
    id = parser.read_string.to_u64
    client.resolve_user id
  end

  def self.to_json(value : User, builder : JSON::Builder)
    value.id.to_s
  end
end

module APIObject
  include MagicJSON

  json_defaults getter: true
  json_api_config input_method_name: "from_chatprog_json"

  field client : Client, extra_field: true, getter: false

  module Identifiable
    include APIObject

    field id : UInt64, converter: SnowflakeConverter
  end
end

struct User
  include APIObject::Identifiable

  field username : String
  field bot? : Bool = false, key: "bot"
end

struct Message
  include APIObject::Identifiable

  field content : String
  field author : User, key: "author_id", converter: {
    type:              AutoIdentifiableConverter(User),
    input_method_name: "from_chatprog_json",
    pass_extra_fields: [:client],
  }
end

class Client
  @last_message : Message? = nil

  def initialize(@client_id : UInt64)
    @users = {} of UInt64 => User
    connect_to_chat_program
  end

  def connect_to_chat_program
    @users[@client_id] = User.from_chatprog_json %{{"id":"#{@client_id}","username":"Zatherz"}}, self
    @last_message = Message.from_chatprog_json %{{"id":"1923515","author_id":"#{@client_id}","content":"Hello, world!"}}, self
  end

  def resolve_user(id : UInt64)
    @users[id] || raise "User with ID #{id} doesn't exist"
  end

  def last_message
    @last_message.as(Message)
  end
end

client = Client.new 123_u64
msg = client.last_message
pp client.last_message.content         # => "Hello, world!"
pp client.last_message.author.id       # => 123
pp client.last_message.author.username # => "Zatherz"

# Through the use of the MagicJSON extra_field feature, converters
# and the pass_extra_fields option we were able to go directly from
# a string ID on the message object to a full user object
# using the client to resolve the ID into the user
#
# Note that this is usually not what you want - because the User
# object could change, you'd want to have a separate 'author' method
# that takes '@author_id' and resolves it using the Client.
#
# Message and User both have full access to the Client object
# under @client, and can use it for anything (a message might
# for example have a channel ID, and you could have a 'channel'
# method that returns something along the lines of
# '@client.resolve_channel @channel_id'
