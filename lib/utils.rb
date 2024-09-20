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

    # Converts a language code to its corresponding ISO 639-2 (alpha-3) code.
    #
    # @param [String] language The ISO 639-1 (alpha-2) or ISO 639-2 (alpha-3) language code.
    # @return [String, nil] The ISO 639-2 (alpha-3) language code, or `nil` if the language is not found.
    def self.language_alpha3(language)
      ISO_639.find(language)&.alpha3
    end
  end
end
