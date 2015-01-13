require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.camelcase.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @name = name
    @foreign_key = options[:foreign_key] || "#{name}_id".to_sym
    @class_name = options[:class_name] || name.to_s.singularize.camelcase
    @primary_key = options[:primary_key] || :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @name = name
    @foreign_key = options[:foreign_key] || "#{self_class_name.underscore}_id".to_sym
    @class_name = options[:class_name] || "#{name.to_s.singularize.camelcase}"
    @primary_key = options[:primary_key] || :id
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    # define_method to create a new method to access the association. Within this method:
    #
    # Use send to get the value of the foreign key.
    # Use model_class to get the target model class.
    # Use where to select those models where the primary_key column is equal to the foreign key value.
    # Call first (since there should be only one such item).
    #
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options
    define_method name do
      options.model_class.where(options.primary_key => send(options.foreign_key)).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)
    define_method name do
      options.model_class.where(options.foreign_key => send(options.primary_key))
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
    @assoc_options ||= {}
    # { human: <AssocOptions#234134321> }
  end
end

class SQLObject
  extend Associatable
end
