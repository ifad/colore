# frozen_string_literal: true

module AutoHeathen
  module Config
    def load_config(defaults = {}, config_file = nil, overwrites = {})
      cfg = symbolize_keys(defaults)
      if config_file && File.exist?(config_file)
        cfg.merge! symbolize_keys(YAML::load_file(config_file))
      end
      cfg.merge! symbolize_keys(overwrites) # non-file opts have precedence
    end

    def symbolize_keys(hash)
      Colore::Utils.symbolize_keys(hash || {})
    end
  end
end
