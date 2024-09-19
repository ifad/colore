# frozen_string_literal: true

require 'iso-639'

module Colore
  module Utils
    # Deep conversion of all hash keys to symbols.
    def self.symbolize_keys(obj)
      case obj
      when Hash
        obj.each_with_object({}) do |(k, v), result|
          result[k.to_sym] = symbolize_keys(v)
        end
      when Array
        obj.map { |o| symbolize_keys(o) }
      else
        obj
      end
    end

    # Converts an ISO 639-1 (alpha-2) language code to its corresponding ISO 639-2 (alpha-3) code.
    #
    # @param [String] lang_alpha2 The ISO 639-1 (alpha-2) language code.
    # @return [String] The ISO 639-2 (alpha-3) language code, or `nil` if the alpha-2 code is not found.
    def self.lang_alpha3(lang_alpha2)
      ISO_639.find(lang_alpha2)&.alpha3
    end
  end
end
