# frozen_string_literal: true

require 'fileutils'
require 'pathname'

def tmp_storage_dir
  Pathname.new('/tmp') + "colore_test.#{Process.pid}"
end

def setup_storage
  allow(Colore::C_.config).to receive(:storage_directory).and_return(tmp_storage_dir)

  FileUtils.rm_rf tmp_storage_dir
  FileUtils.mkdir_p tmp_storage_dir
  FileUtils.cp_r fixture('app'), tmp_storage_dir
  FileUtils.cp_r fixture('legacy'), tmp_storage_dir
end

def delete_storage
  FileUtils.rm_rf tmp_storage_dir
end
