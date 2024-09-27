# frozen_string_literal: true

require 'fileutils'
require 'pathname'

def tmp_tika_config_dir
  Pathname.new("/tmp/colore_test.#{Process.pid}.tika")
end

def setup_tika_config
  allow(Colore::C_.config).to receive(:tika_config_directory).and_return tmp_tika_config_dir

  FileUtils.rm_rf tmp_tika_config_dir
  FileUtils.mkdir_p tmp_tika_config_dir
end

def delete_tika_config
  FileUtils.rm_rf tmp_tika_config_dir
end
