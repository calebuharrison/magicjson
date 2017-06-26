module MagicJSON
  # :nodoc:
  macro generate
    \{% begin %}
      \{% input_method_name = MAGICJSON_API_CONFIG[:input_method_name] || "from_json" %}
      def self.\{{input_method_name.id}}(
          data : String | IO::Memory,
          \{% for k, v in MAGICJSON_FIELDS %}
            \{% if v[:extra_field] %}
              \{{k.id}} : \{{v[:type]}},
            \{% end %}
          \{% end %}
        )
        new(::JSON::PullParser.new(data),
          \{% for k, v in MAGICJSON_FIELDS %}
            \{% if v[:extra_field] %}
              \{{k.id}},
            \{% end %}
          \{% end %}
        )
      end

      \{% for k, v in MAGICJSON_FIELDS %}
        \{% if v[:default] != nil %}
          @\{{v[:ivar_name].id}} : \{{v[:type]}} = \{{v[:default]}}
        \{% else %}
          @\{{v[:ivar_name].id}} : \{{v[:type]}}
        \{% end %}
      \{% end %}

      def initialize(pull_parser : ::JSON::PullParser,
          \{% for k, v in MAGICJSON_FIELDS %}
            \{% if v[:extra_field] %}
              @\{{k.id}} : \{{v[:type]}},
            \{% end %}
          \{% end %}
        )

        \{% for k, v in MAGICJSON_FIELDS %}
          \{% if !v[:extra_field] && ((!MAGICJSON_DEFAULTS[:dont_deserialize] && v[:dont_deserialize] == nil) || v[:dont_deserialize] == false) %}
            \%found{v[:key]} = false
            \%var{v[:key]} = nil
          \{% end %}
        \{% end %}

        pull_parser.read_object do |%k|
          case %k
          \{% for k, v in MAGICJSON_FIELDS %}
            \{% if !v[:extra_field] && ((!MAGICJSON_DEFAULTS[:dont_deserialize] && v[:dont_deserialize] == nil) || v[:dont_deserialize] == false) %}
            when \{{v[:key]}}
              \%found{v[:key]} = true

              \%var{v[:key]} =
                \{% if v[:default] != nil %} pull_parser.read_null_or { \{% end %}

                \{% if (MAGICJSON_DEFAULTS[:converter] && MAGICJSON_DEFAULTS[:converter][:type] &&
                        (v[:converter] == nil || v[:converter][:type] == nil)) || (v[:converter] != nil &&
                        v[:converter][:type] != nil) %}
                  \{% converter_input_method_name = (v[:converter] && v[:converter][:input_method_name]) ||
                                                    (MAGICJSON_DEFAULTS[:converter] && MAGICJSON_DEFAULTS[:converter][:input_method_name]) ||
                                                    "from_json" %}
                  \{% extra_field_list = (v[:converter] && v[:converter][:pass_extra_fields] == false && [] of Nil) ||
                                         (v[:converter] && v[:converter][:pass_extra_fields]) ||
                                         (MAGICJSON_DEFAULTS[:converter] && MAGICJSON_DEFAULTS[:converter][:pass_extra_fields]) ||
                                         [] of Nil %}
                  \{{(v[:converter] && v[:converter][:type]) || MAGICJSON_DEFAULTS[:converter][:type]}}.\{{converter_input_method_name.id}}(
                    pull_parser,
                    \{% for ef in extra_field_list %}
                      \{% found = false %}
                      \{% found_extra = false %}
                      \{% for fk, fv in MAGICJSON_FIELDS %}
                        \{% if fk == ef.id.stringify %}
                          \{% found = true %}

                          \{% if (MAGICJSON_DEFAULTS[:extra_field] && fv[:extra_field] == nil) ||
                            fv[:extra_field] == true %}
                            \{% found_extra = true %}
                          \{% end %}
                        \{% end %}
                      \{% end %}
                      \{% raise "[#{@type.name}|#{k.id} : #{v[:type]}|converter] Extra field '#{ef.id}' doesn't exist" if !found %}
                      \{% raise "[#{@type.name}|#{k.id} : #{v[:type]}|converter] Field '#{ef.id}' isn't defined as 'extra_field'" if !found_extra %}

                      \{% if ef.id.stringify.ends_with?("?") || ef.id.stringify.ends_with?("!") %}
                        @\{{ef.id.stringify[0..-2].id}},
                      \{% else %}
                        @\{{ef.id}},
                      \{% end %}
                    \{% end %}
                  )
                \{% else %}
                  \{% extra_field_list = v[:pass_extra_fields] || MAGICJSON_DEFAULTS[:pass_extra_fields] || [] of Nil %}
                  \{% if v[:type].is_a?(Union) %}
                    ::Union(\{{v[:type]}}).new(
                  \{% else %}
                    (\{{v[:type]}}).new(
                  \{% end %}
                      pull_parser,
                      \{% for ef in extra_field_list %}
                        \{% found = false %}
                        \{% found_extra = false %}
                        \{% for fk, fv in MAGICJSON_FIELDS %}
                          \{% if fk == ef.id.stringify %}
                            \{% found = true %}

                            \{% if (MAGICJSON_DEFAULTS[:extra_field] && fv[:extra_field] == nil) ||
                              fv[:extra_field] == true %}
                              \{% found_extra = true %}
                            \{% end %}
                          \{% end %}
                        \{% end %}
                        \{% raise "[#{@type.name}|#{k.id} : #{v[:type]}] Extra field '#{ef.id}' doesn't exist" if !found %}
                        \{% raise "[#{@type.name}|#{k.id} : #{v[:type]}] Field '#{ef.id}' isn't defined as 'extra_field'" if !found_extra %}

                        \{% if ef.id.stringify.ends_with?("?") || ef.id.stringify.ends_with?("!") %}
                          @\{{ef.id.stringify[0..-2].id}},
                        \{% else %}
                          @\{{ef.id}},
                        \{% end %}
                      \{% end %}
                    )
                \{% end %}

                \{% if v[:default] != nil %} } \{% end %}
            \{% end %}
          \{% end %}
          else
            \{% if MAGICJSON_API_CONFIG[:strict] %}
              raise ::JSON::ParseException.new("Unknown json attribute: #{%k}", 0, 0)
            \{% else %}
              pull_parser.skip
            \{% end %}
          end
        end

        \{% for k, v in MAGICJSON_FIELDS %}
          \{% if !v[:extra_field] && !v[:dont_deserialize] && v[:default] == nil %}
            if !\%found{v[:key]} && \%var{v[:key]} == nil && !::Union(\{{v[:type]}}).nilable?
              raise ::JSON::ParseException.new("Missing json attribute: \{{v[:key].id}} (\{{k.id}} : \{{v[:type]}})", 0, 0)
            end
          \{% end %}
        \{% end %}

        \{% for k, v in MAGICJSON_FIELDS %}
          \{% if !v[:extra_field] && !v[:dont_deserialize] %}
            \{% if v[:default] != nil %}
              @\{{v[:ivar_name].id}} = \%var{v[:key]}.nil? ? (\{{v[:default]}}) : \%var{v[:key]}
            \{% else %}
              @\{{v[:ivar_name].id}} = \%var{v[:key]}.as(\{{v[:type]}})
            \{% end %}
          \{% end %}
        \{% end %}
      end

      def to_json(json : ::JSON::Builder)
        json.object do
          \{% for k, v in MAGICJSON_FIELDS %}
            \%var{k} = @\{{v[:ivar_name].id}}

            \{% if !v[:extra_field] && (
                     (!MAGICJSON_DEFAULTS[:dont_serialize] && v[:dont_serialize] == nil) ||
                     v[:dont_serialize] == false
                   ) %}
              \{% if !v[:emit_null] %}
                unless \%var{k} == nil
              \{% end %}
                  json.field(\{{v[:key]}}) do
                    \{% if (MAGICJSON_DEFAULTS[:converter] && MAGICJSON_DEFAULTS[:converter][:type] &&
                        (v[:converter] == nil || v[:converter][:type] == nil)) || (v[:converter] != nil &&
                        v[:converter][:type] != nil) %}
                      \{% converter_output_method_name = (v[:converter] && v[:converter][:output_method_name]) ||
                                                        (MAGICJSON_DEFAULTS[:converter] && MAGICJSON_DEFAULTS[:converter][:output_method_name]) ||
                                                        "to_json" %}
                      \{% extra_field_list = (v[:converter] && v[:converter][:pass_extra_fields] == false && [] of Nil) ||
                                         (v[:converter] && v[:converter][:pass_extra_fields]) ||
                                         (MAGICJSON_DEFAULTS[:converter] && MAGICJSON_DEFAULTS[:converter][:pass_extra_fields]) ||
                                         [] of Nil %}
                      if \%var{k}.nil?
                        nil.to_json
                      else
                        \{{(v[:converter] && v[:converter][:type]) || MAGICJSON_DEFAULTS[:converter][:type]}}.\{{converter_output_method_name.id}}(
                          \%var{k},
                          json,
                          \{% for ef in extra_field_list %}
                            \{% found = false %}
                            \{% found_extra = false %}
                            \{% for fk, fv in MAGICJSON_FIELDS %}
                              \{% if fk == ef.id.stringify %}
                                \{% found = true %}

                                \{% if (MAGICJSON_DEFAULTS[:extra_field] && fv[:extra_field] == nil) ||
                                  fv[:extra_field] == true %}
                                  \{% found_extra = true %}
                                \{% end %}
                              \{% end %}
                            \{% end %}
                            \{% raise "[#{@type.name}|#{k.id} : #{v[:type]}] Extra field '#{ef.id}' doesn't exist" if !found %}
                            \{% raise "[#{@type.name}|#{k.id} : #{v[:type]}] Field '#{ef.id}' isn't defined as 'extra_field'" if !found_extra %}

                            \{% if ef.id.stringify.ends_with?("?") || ef.id.stringify.ends_with?("!") %}
                              @\{{ef.id.stringify[0..-2].id}}
                            \{% else %}
                              @\{{ef.id}}
                            \{% end %}
                          \{% end %}
                        )
                      end
                    \{% else %}
                      \%var{k}.to_json(json)
                    \{% end %}
                  end
              \{% if !v[:emit_null] %}
                end
              \{% end %}
            \{% end %}
          \{% end %}
        end
      end

      \{% for k, v in MAGICJSON_FIELDS %}
        \{% if (MAGICJSON_DEFAULTS[:getter] && v[:getter] == nil) || v[:getter] == true %}
            def \{{k.id}} : \{{v[:type]}}
              @\{{v[:ivar_name].id}}
            end
        \{% end %}

        \{% if (MAGICJSON_DEFAULTS[:setter] && v[:setter] == nil) || v[:setter] == true %}
            def \{{k.id}}=(value : \{{v[:type]}})
              @\{{v[:ivar_name].id}} = value
            end
        \{% end %}
      \{% end %}
    \{% end %}
  end
end
