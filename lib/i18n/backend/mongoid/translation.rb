require 'mongoid'

module I18n
  module Backend
    # Mongoid model used to store actual translations to the database.
    #
    # This model expects a table like the following to be already set up in
    # your the database:
    #
    #   create_table :translations do |t|
    #     t.string :locale
    #     t.string :key
    #     t.text   :value
    #     t.text   :interpolations
    #     t.boolean :is_proc, :default => false
    #   end
    #
    # This model supports to named scopes :locale and :lookup. The :locale
    # scope simply adds a condition for a given locale:
    #
    #   I18n::Backend::Mongoid::Translation.locale(:en).all
    #   # => all translation records that belong to the :en locale
    #
    # The :lookup scope adds a condition for looking up all translations
    # that either start with the given keys (joined by an optionally given
    # separator or I18n.default_separator) or that exactly have this key.
    #
    #   # with translations present for :"foo.bar" and :"foo.baz"
    #   I18n::Backend::Mongoid::Translation.lookup(:foo)
    #   # => an array with both translation records :"foo.bar" and :"foo.baz"
    #
    #   I18n::Backend::Mongoid::Translation.lookup([:foo, :bar])
    #   I18n::Backend::Mongoid::Translation.lookup(:"foo.bar")
    #   # => an array with the translation record :"foo.bar"
    #
    # When the StoreProcs module was mixed into this model then Procs will
    # be stored to the database as Ruby code and evaluated when :value is
    # called.
    #
    #   Translation = I18n::Backend::Mongoid::Translation
    #   Translation.create \
    #     :locale => 'en'
    #     :key    => 'foo'
    #     :value  => lambda { |key, options| 'FOO' }
    #   Translation.first(:conditions => { :locale => 'en', :key => 'foo' }).value
    #   # => 'FOO'
    class Mongoid
      class Translation
        include ::Mongoid::Document

        field :locale
        field :key
        field :value,           :type => Hash
        field :interpolations,  :type => Array
        field :is_proc,         :type => Boolean, :default => false

        named_scope :locale, lambda { |locale|
          { :where => { :locale => locale.to_s } }
        }

        named_scope :lookup, lambda { |keys, *separator|
          keys = Array(keys).map! { |key| key.to_s }

          unless separator.empty?
            warn "[DEPRECATION] Giving a separator to Translation.lookup is deprecated. " <<
              "You can change the internal separator by overwriting FLATTEN_SEPARATOR."
          end

          namespace = "#{keys.last}#{I18n::Backend::Flatten::FLATTEN_SEPARATOR}.*"
          unless keys.empty?
            { :where => "['#{keys.map {|k| EscapeUtils.escape_javascript(k)) }.join("','")}'].indexOf(this.key) != -1 || this.key.match(/#{namespace}/)" }
          else
            { :where => { :key => /^#{namespace}$/ } }
          end
        }

        def self.available_locales
          Translation.find(:all, :select => 'DISTINCT locale').map { |t| t.locale.to_sym }
        end

        def interpolates?(key)
          self.interpolations.include?(key) if self.interpolations
        end

        def value
          if is_proc
            Kernel.eval(read_attribute(:value))
          else
            value = read_attribute(:value)
            value == 'f' ? false : value
          end
        end
      end
    end
  end
end
