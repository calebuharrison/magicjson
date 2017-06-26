# Main MagicJSON module.
#
# Upon inclusion, its macros will be available in the
# module, class or struct that included it. Including
# modules or extending classes that either directly or
# indirectly include MagicJSON will also copy these
# macros to the target type. MagicJSON is like a virus -
# if an ancestor of a type has it, the type has
# it too.
#
# When multiple types that contain MagicJSON data are
# included or extended, the data will be merged in the
# expected order. First data from the parent will be
# merged, then the data defined in the type body.
# Included modules will be merged in the
# same order as they are included. Note that if you
# set options and/or define fields before including
# modules that use MagicJSON, these modules may override
# whatever you have set.
#
# The merge logic is very simple - if module A defines a
# field `x` of type `String` with `getter: true` and
# module B defines a field `x` of type `Int32` without
# specifying a getter, assuming B is included after A,
# the including type will have a field `x` of type Int32
# without a getter. The same logic (shallow merging)
# is also used for API config and defaults.
#
# Modules and abstract types that include MagicJSON and
# specify fields only serve to hold data. They will not
# be validated and the serializer/deserializer code
# will not be generated inside them.
module MagicJSON
  # Register a field. Only *type_decl* is required.
  #
  # *type_decl* is the type declaration of the field in the format `a : String`.
  # If the name of the field ends with a question mark (`?`) or an exclamation
  # mark (`!`), the instance variable holding the value of the field will have
  # the last character stripped out.
  #
  # *converter* is used for specifying the converter.
  # A converter is a type with an input method and an output method. During parsing,
  # if the field has an assigned converter, the input method of the converter will
  # be called with the JSON::PullParser and optional extra fields. When the object
  # is serialized, the output method of the converter will be called with the value
  # of the field, the JSON::Builder and optional extra fields.
  #
  # The *converter* argument can be either a type
  # or a hash/named tuple in the following format:
  #
  # ```
  # {
  #   type:               SomeConverter,      # required
  #   input_method_name:  "from_something",   # optional, nil for default
  #   output_method_name: "to_something",     # optional, nil for default
  #   pass_extra_fields:  {:some_field_name}, # optional, nil for default, false for the equivalent of an empty tuple/array
  # }
  # ```
  #
  # `type` specifies the type (struct, class or module) that will be the target
  # for the input method and the output method.
  #
  # `input_method_name` and `output_method_name` allow you to control the names
  # of these methods.
  #
  # `pass_extra_fields` allows you to choose which fields marked as `extra_field`
  # should be passed into the input and output method of the converter.
  #
  #
  # When the value of *converter* is just a type, the `input_method_name`,
  # `output_method_name` and `pass_extra_fields` are inherited from the defaults
  # (by default, `from_json`, `to_json` and no extra fields).
  #
  # Example of a converter:
  # ```
  # module SnowflakeConverter
  #   # The API sends 64bit unsigned int IDs called "snowflakes" as strings
  #   # to avoid losing precision
  #
  #   def self.from_json(parser : JSON::PullParser)
  #     parser.read_string.to_u64
  #   end
  #
  #   def self.to_json(value : UInt64, builder : JSON::Builder)
  #     builder.scalar value.to_s
  #   end
  # end
  # ```
  #
  # *emit_null* is a boolean that determines whether `nil` values for nilable
  # fields should be serialized as `null` or not serialized at all (`nil` for default,
  # `false` for not emitting anything at all, `true` to emit `null`s).
  #
  # *extra_field* determines whether this field is a part of the serialized object,
  # or an extra argument that needs to be externally passed. `true` to define the
  # field as an extra field, `false` or `nil` to define it as a normal field.
  #
  # Extra fields need to be passed into the JSON input method (by default `from_json`).
  # Extra fields can also be passed to converters (both in the input and output method).
  # The output method (`to_json`) cannot be modified and cannot take in extra fields.
  #
  # *dont_deserialize* defines that this field does not exist in the JSON payload even
  # though it is not an extra field. Only fields with a default value can use this.
  # `nil` for default, `true` to not deserialize, `false` to deserialize.
  #
  # *dont_serialize* defines that this field should not be serialized in `to_json`,
  # even though it is not an extra field. As opposed to *dont_deserialize*,
  # this option can be enabled for any field. `nil` for default, `true` to
  # not serialize, `false` to serialize.
  #
  # *key* specifies the key that this field uses. By default (when *key* is `nil`),
  # the key is the same as the name of the field, however sometimes it might be
  # desirable to use a different field name on the Crystal side. For example, you
  # might want to have a question mark at the end of boolean fields:
  #
  # ```
  # struct User
  #   include MagicJSON
  #
  #   field username : String
  #   field bot? : Bool, key: "bot"
  # end
  # ```
  #
  # *pass_extra_fields* is for passing extra fields to the initializer of the
  # type of this field when parsing. Its semantics are identical to *converter*'s
  # `pass_extra_fields` setting. `nil` for default, `false` for an empty list,
  # or a tuple/array literal with a list of names of extra fields (strings or
  # symbols). This property is only taken into account when the field does not
  # have a converter.
  #
  # *getter* specifies that a getter method (with the same name as the field)
  # should be generated. `nil` for default, `false` for no getter, `true` for
  # getter.
  #
  # *setter* specifies that a setter method (with the same name as the field)
  # should be generated. `nil` for default, `false` for no setter, `true` for
  # setter.
  #
  # *property* serves as a shortcut for *getter* and *setter*. When it is `nil`,
  # it will not touch the *getter* or *setter* options. When it is `false`, it
  # is the equivalent to specifying `setter: false, getter: false`. When it is
  # `true`, it's the equivalent of specifying `setter: true, getter: true`.
  # *property* takes precedence over *setter* and *getter* when it's set to a
  # value other than `nil`.
  macro field(type_decl, converter = nil, emit_null = nil,
              extra_field = nil, dont_deserialize = nil,
              dont_serialize = nil, key = nil, pass_extra_fields = nil,
              getter = nil, setter = nil, property = nil)
    {% raise "Don't try to call MagicJSON macros directly! Use 'include MagicJSON' and then call the macros like 'field a : Int32', not 'MagicJSON.field a : Int32'." %}
  end

  # Modify general configuration.
  #
  # Using this macro you can change the options that fit neither in specific
  # fields nor in defaults. These apply to the whole type and every type
  # that includes it (unless the options are overriden by another macro call).
  #
  # *input_method_name* specifies the name of the method defined on the metaclass
  # that takes in JSON data and optionally extra fields. The default name (when
  # this field is `nil`) is `from_json`.
  #
  # *strict* is used to control strict mode on the parser. When `nil` or `false`,
  # fields found in the input JSON data that aren't defined will be ignored.
  # When `true`, any unknown fields will cause an exception to be raised.
  macro json_api_config(input_method_name = nil, strict = nil)
    {% raise "Don't try to call MagicJSON macros directly! Use 'include MagicJSON' and then call the macros like 'json_api_config strict: true' not 'MagicJSON.json_api_config strict: true'." %}
  end

  # Modify default field options.
  #
  # The options in this macro correspond to the options in `field` (although,
  # not all `field` options have configurable defaults).
  #
  # When evaluating field options, first the option specified on the actual
  # field is checked, then if is isn't present (or set to `nil`), the default
  # option specified with this macro is checked. When that isn't present
  # either, in all cases except *converter* a hardcoded default is used.
  #
  # If there is no default *converter* and a field hasn't specified a *converter*
  # itself, no converter will be used on it. Instead, the `new` method will be ran
  # on the type (or the type union), with optional extra fields.
  #
  # Hardcoded defaults:
  #
  # * *emit_null* - `false`
  # * *dont_deserialize* - `false`
  # * *dont_serialize* - `false`
  # * *pass_extra_fields* - `false` (no extra fields)
  # * *getter* - `false`
  # * *setter* - `false`
  #
  # The semantics of *property* are identical to `field`'s.
  macro json_defaults(converter = nil, emit_null = nil,
                      dont_deserialize = nil, dont_serialize = nil,
                      pass_extra_fields = nil, getter = nil,
                      setter = false, property = nil)
    {% raise "Don't try to call MagicJSON macros directly! Use 'include MagicJSON' and then call the macros like 'json_defaults getter: true' not 'MagicJSON.json_defaults getter: true'." %}
  end
end
