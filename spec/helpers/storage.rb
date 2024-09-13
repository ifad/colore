require 'fileutils'
require 'pathname'

module StorageMixin
  include Rack::Test::Methods

  FILE_FIXTURE_PATH = File.expand_path('../fixtures/files', __dir__)

  def app
    described_class
  end

  def file_fixture(fixture_name)
    path = Pathname.new(File.join(FILE_FIXTURE_PATH, fixture_name))

    if path.exist?
      path
    else
      msg = "the directory '%s' does not contain a file named '%s'"
      raise ArgumentError.new(format(msg, FILE_FIXTURE_PATH, fixture_name))
    end
  end

  def spec_logger
    Logger.new('spec/output.log')
  end

  def tmp_storage_dir
    Pathname.new("/tmp/colore_test.#{Process.pid}")
  end

  def setup_storage
    FileUtils.rm_rf tmp_storage_dir
    FileUtils.mkdir_p tmp_storage_dir
    FileUtils.cp_r file_fixture('app'), tmp_storage_dir
    FileUtils.cp_r file_fixture('legacy'), tmp_storage_dir
  end

  def delete_storage
    FileUtils.rm_rf tmp_storage_dir
  end
end

RSpec.configure do |rspec|
  rspec.include StorageMixin
end
