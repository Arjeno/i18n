# encoding: utf-8
$:.unshift(File.expand_path(File.dirname(__FILE__) + '/../')); $:.uniq!
require 'test_helper'

setup_mongoid

class I18nBackendMongoidTest < Test::Unit::TestCase
  def setup
    I18n.backend = I18n::Backend::Mongoid.new
    store_translations(:en, :foo => { :bar => 'bar', :baz => 'baz' })
  end

  def teardown
    I18n::Backend::Mongoid::Translation.destroy_all
    super
  end

  test "store_translations does not allow ambiguous keys (1)" do
    I18n::Backend::Mongoid::Translation.delete_all
    I18n.backend.store_translations(:en, :foo => 'foo')
    I18n.backend.store_translations(:en, :foo => { :bar => 'bar' })
    I18n.backend.store_translations(:en, :foo => { :baz => 'baz' })

    translations = I18n::Backend::Mongoid::Translation.locale(:en).lookup('foo').all
    assert_equal %w(bar baz), translations.map(&:value)

    assert_equal({ :bar => 'bar', :baz => 'baz' }, I18n.t(:foo))
  end

  test "store_translations does not allow ambiguous keys (2)" do
    I18n::Backend::Mongoid::Translation.delete_all
    I18n.backend.store_translations(:en, :foo => { :bar => 'bar' })
    I18n.backend.store_translations(:en, :foo => { :baz => 'baz' })
    I18n.backend.store_translations(:en, :foo => 'foo')

    translations = I18n::Backend::Mongoid::Translation.locale(:en).lookup('foo').all
    assert_equal %w(foo), translations.map(&:value)

    assert_equal 'foo', I18n.t(:foo)
  end
  
  test "can store translations with keys that are translations containing special chars" do
    I18n.backend.store_translations(:es, :"Pagina's" => "Pagina's" )
    assert_equal "Pagina's", I18n.t(:"Pagina's", :locale => :es)
    I18n.backend.store_translations(:es, :"a/split/key" => 'some text')
    assert_equal 'some text', I18n.t(:"a/split/key", :locale => :es)
  end

  test 'can store arrays' do
    I18n.backend.store_translations(:es, :an_array => ['first', 'second', 'last'])
    assert_equal ['first', 'second', 'last'], I18n.t(:an_array, :locale => :es)
  end

  test 'can store nil values' do
    I18n.backend.store_translations(:es, :blank => nil)
    assert_equal nil, I18n::Backend::Mongoid::Translation.last.value
  end

  test "missing translations table does not cause an error in #available_locales" do
    Mongoid.database.collections.each do |collection|
      begin
        collection.drop
      rescue
      end
    end
    assert_equal [], I18n.backend.available_locales
  end

  def test_expand_keys
    assert_equal %w(foo foo.bar foo.bar.baz), I18n.backend.send(:expand_keys, :'foo.bar.baz')
  end
end if defined?(Mongoid)
