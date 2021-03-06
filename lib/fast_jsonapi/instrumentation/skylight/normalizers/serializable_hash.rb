# frozen_string_literal: true

require "fast_jsonapi/instrumentation/skylight/normalizers/base"
require "fast_jsonapi/instrumentation/serializable_hash"

module FastJsonapi
  module Instrumentation
    module Skylight
      module Normalizers
        class SerializableHash < SKYLIGHT_NORMALIZER_BASE_CLASS
          register FastJsonapi::ObjectSerializer::SERIALIZABLE_HASH_NOTIFICATION

          CAT = "view.#{FastJsonapi::ObjectSerializer::SERIALIZABLE_HASH_NOTIFICATION}"

          def normalize(_trace, _name, payload)
            [CAT, payload[:name], nil]
          end
        end
      end
    end
  end
end
