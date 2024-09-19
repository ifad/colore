# frozen_string_literal: true

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
  end
end
