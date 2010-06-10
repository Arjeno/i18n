# encoding: utf-8
$:.unshift(File.expand_path(File.dirname(__FILE__) + '/../')); $:.uniq!
require 'test_helper'
require 'api'

class I18nSimpleBackendApiTest < Test::Unit::TestCase
  class Backend < I18n::Backend::Simple
    include I18n::Backend::Pluralization
  end

  def setup
    I18n.backend = I18n::Backend::Simple.new
    super
  end

  include Tests::Api::Basics
  include Tests::Api::Defaults
  include Tests::Api::Interpolation
  include Tests::Api::Link
  include Tests::Api::Lookup
  include Tests::Api::Pluralization
  include Tests::Api::Procs
  include Tests::Api::Localization::Date
  include Tests::Api::Localization::DateTime
  include Tests::Api::Localization::Time
  include Tests::Api::Localization::Procs

  test "make sure we use the Simple backend" do
    assert_equal I18n::Backend::Simple, I18n.backend.class
  end
end