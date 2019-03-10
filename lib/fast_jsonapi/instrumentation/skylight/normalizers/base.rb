# frozen_string_literal: true

require "skylight"

SKYLIGHT_NORMALIZER_BASE_CLASS = begin
  ::Skylight::Core::Normalizers::Normalizer
rescue NameError # rubocop:disable Layout/RescueEnsureAlignment
  ::Skylight::Normalizers::Normalizer
end
