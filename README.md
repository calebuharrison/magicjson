# MagicJSON

A compiletime JSON parser generator for Crystal.

The main purpose that MagicJSON is supposed to fulfill is to make working with
payloads that need external Crystal data (i.e. objects not in the payload that
need to be passed all the way from `from_json` to an instance variable) painless,
or at least much less painful than with the builtin `JSON.mapping`.

MagicJSON also supports inheritance and mixins naturally. You can, for example,
have a class that defines a field, a module that defines another field and
another module that defines yet another field. If you extend that class and 
include both modules in another class you will have 3 fields.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  magicjson:
    gitlab: zatherz/magicjson
```

## Usage

```crystal
require "magicjson"
```

Define a User with a username and a `bot?` field:

```crystal
require "magicjson"

struct User
  include MagicJSON

  json_defaults getter: true # MagicJSON supports customizable defaults!
  field username : String
  field bot? : Bool = true # As opposed to JSON.mapping, you can also easily define fields ending in question marks or exclamation marks.
end
```

## Examples

A couple of examples are available in the `examples/` directory.

## Documentation

Read the documentation [online](https://zatherz.gitlab.io/magicjson) or build it with `crystal docs`.

## Contributors

- [Zatherz](https://gitlab.com/u/Zatherz) - creator, maintainer
