module MagicJSON
  # :nodoc:
  macro infect_further
    \{% if @type.has_constant? :MAGICJSON_OBJECT %}
      \{% for k, v in @type.ancestors.first.constant :MAGICJSON_API_CONFIG %}
        \{% MAGICJSON_API_CONFIG[k] = v %}
      \{% end %}

      \{% for k, v in @type.ancestors.first.constant :MAGICJSON_FIELDS %}
        \{% MAGICJSON_FIELDS[k] = v %}
      \{% end %}

      \{% for k, v in @type.ancestors.first.constant :MAGICJSON_DEFAULTS %}
        \{% MAGICJSON_DEFAULTS[k] = v %}
      \{% end %}
    \{% else %}
      MagicJSON.infect
      MAGICJSON_FIELDS = \{{MAGICJSON_FIELDS}}
      MAGICJSON_DEFAULTS = \{{MAGICJSON_DEFAULTS}}
      MAGICJSON_API_CONFIG = \{{MAGICJSON_API_CONFIG}}

      macro finished
        \{% if !@type.class.name.ends_with?(":Module") && !@type.abstract? %}
          MagicJSON.validate # Validation step
          MagicJSON.generate # JSON parser generation step
        \{% end %}
      end
    \{% end %}
  end

  # :nodoc:
  macro infect
    MAGICJSON_OBJECT = true

    macro json_api_config(input_method_name = nil, strict = nil)
      \{% MAGICJSON_API_CONFIG[:input_method_name] = input_method_name if input_method_name != nil %}
      \{% MAGICJSON_API_CONFIG[:strict] = strict if strict != nil %}
    end

    macro json_defaults(converter = nil, emit_null = nil,
                        dont_deserialize = nil, dont_serialize = nil,
                        pass_extra_fields = nil, getter = nil,
                        setter = false, property = nil)
      \{% if converter != nil %}
        \{% if converter.is_a?(HashLiteral) || converter.is_a?(NamedTupleLiteral) %}
          \{% MAGICJSON_DEFAULTS[:converter] = converter %}
        \{% else %}
          \{% MAGICJSON_DEFAULTS[:converter] = {type: converter}%}
        \{% end %}
      \{% end %}
      \{% MAGICJSON_DEFAULTS[:emit_null] = emit_null if emit_null != nil %}
      \{% MAGICJSON_DEFAULTS[:dont_serialize] = dont_serialize if dont_serialize != nil %}
      \{% MAGICJSON_DEFAULTS[:dont_deserialize] = dont_deserialize if dont_deserialize != nil %}
      \{% MAGICJSON_DEFAULTS[:pass_extra_fields] = pass_extra_fields if pass_extra_fields != nil %}
      \{% MAGICJSON_DEFAULTS[:getter] = getter if getter != nil %}
      \{% MAGICJSON_DEFAULTS[:setter] = setter if setter != nil %}
      \{% MAGICJSON_DEFAULTS[:setter] = MAGICJSON_DEFAULTS[:getter] = property if property != nil %}
    end

    macro field(type_decl, converter = nil, emit_null = nil,
              extra_field = nil, dont_deserialize = nil,
              dont_serialize = nil, key = nil, pass_extra_fields = nil,
              getter = nil, setter = nil, property = nil)
      \{% tuple = {type: type_decl.type} %}
      \{% if converter != nil %}
        \{% if converter.is_a?(HashLiteral) || converter.is_a?(NamedTupleLiteral) %}
          \{% tuple[:converter] = converter %}
        \{% else %}
          \{% tuple[:converter] = {type: converter} %}
        \{% end %}
      \{% end %}
      \{% tuple[:default] = type_decl.value if !type_decl.value.is_a?(Nop) %}
      \{% tuple[:has_default] = true if !type_decl.value.is_a?(Nop) %}
      \{% tuple[:emit_null] = emit_null if emit_null != nil %}
      \{% tuple[:extra_field] = extra_field if extra_field != nil %}
      \{% tuple[:dont_deserialize] = dont_deserialize if dont_deserialize != nil %}
      \{% tuple[:dont_serialize] = dont_serialize if dont_serialize != nil %}
      \{% if key == nil %}
        \{% tuple[:key] = type_decl.var.stringify %}
      \{% else %}
        \{% tuple[:key] = key %}
      \{% end %}
      \{% tuple[:pass_extra_fields] = pass_extra_fields if pass_extra_fields != nil %}
      \{% tuple[:setter] = setter if setter != nil %}
      \{% tuple[:getter] = getter if getter != nil %}
      \{% tuple[:setter] = tuple[:getter] = property if property != nil %}
      \{% if type_decl.var.stringify.ends_with?("?") || type_decl.var.stringify.ends_with?("!") %}
        \{% tuple[:ivar_name] = type_decl.var.stringify[0..-2] %}
      \{% else %}
        \{% tuple[:ivar_name] = type_decl.var.stringify %}
      \{% end %}


      \{% MAGICJSON_FIELDS[type_decl.var.stringify] = tuple %}
    end

    private macro included
      MagicJSON.infect_further
    end

    private macro inherited
      MagicJSON.infect_further
    end

    private macro finished
      \{% if !@type.class.name.ends_with?(":Module") && !@type.abstract? %}
        MagicJSON.validate # Validation step
        MagicJSON.generate # JSON parser generation step
      \{% end %}
    end
  end

  private macro included
    \{% if !@type.has_constant? :MAGICJSON_OBJECT %}
      MAGICJSON_FIELDS = {} of Nil => Nil
      MAGICJSON_DEFAULTS = {} of Nil => Nil
      MAGICJSON_API_CONFIG = {} of Nil => Nil
      MagicJSON.infect
    \{% end %}
  end
end
