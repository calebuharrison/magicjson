module MagicJSON
  # :nodoc:
  macro validate
    \{% begin %}
      \{% json_field_found = false %}
      \{% for k, v in MAGICJSON_FIELDS %}
        \{% if ((MAGICJSON_DEFAULTS[:dont_deserialize] && v[:dont_deserialize] == nil) || v[:dont_deserialize] == true) && v[:default].is_a?(Nop) %}
          \{% raise "[#{@type.name}|#{k.id} : #{v[:type]}] Only fields with a default value can have 'dont_deserialize' enabled" %}
        \{% end %}

        # this macro is horrible, but it does its job well
        # it checks if emit_null is set to 'true', and if it is,
        # verifies that it is either literally just Nil
        # or a union that contains a Nil, otherwise it errors at
        # compiletime
        # unfortunately, it's not recursive

        \{% if ((MAGICJSON_DEFAULTS[:emit_null] && v[:emit_null] == nil) || v[:emit_null] == true) &&
           !(v[:type].is_a?(Path) &&
            v[:type].names.size != 1 &&
            v[:type].names[0] != "Nil".id) &&

           !(v[:type].is_a?(Union) &&
            v[:type].types.any? do |t|
              #TODO 'Path#global?' is broken?
              !t.is_a?(Union) && !t.is_a?(Generic) && t.names.size == 1 && t.names[0] == "Nil".id && t.resolve == ::Nil
            end) %}

          \{% raise "[#{@type.name}|#{k.id} : #{v[:type]}] Option 'emit_null' is invalid when the type can not be nil.\nIf your code looks like 'String | Int32?', refactor it to 'String | Int32 | Nil', as 'String | Int32?' is the same as 'Union(String, Union(Int32, Nil))'" %}
        \{% end %}

        \{% if !v[:extra_field] && ((!MAGICJSON_DEFAULTS[:dont_deserialize] && v[:dont_deserialize] == nil) || v[:dont_deserialize] == false) %}
          \{% json_field_found = true %}
        \{% end %}
      \{% end %}

      \{% if !json_field_found %}
          \{% raise "[#{@type.name}] You have no actual JSON fields! You either have no MagicJSON fields at all, or all your fields are either 'extra_field' or 'dont_serialize'." %}
      \{% end %}
    \{% end %}
  end
end
