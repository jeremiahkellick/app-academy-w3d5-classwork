require_relative '02_searchable'
require 'active_support/inflector'

ActiveSupport::Inflector.inflections do |inflect|
  inflect.irregular 'human', 'humans'
end

# Phase IIIa
class AssocOptions
  OPTIONS = [:foreign_key, :class_name, :primary_key]

  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    class_name.tableize
  end

  def self.options
    OPTIONS
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    name = name.to_s
    self.foreign_key = "#{name}_id".to_sym
    self.class_name = name.camelcase
    self.primary_key = :id
    options.each do |option, value|
      send("#{option}=", value) if self.class.options.include?(option)
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    name = name.to_s
    self.foreign_key = "#{self_class_name.underscore}_id".to_sym
    self.class_name = name.singularize.camelcase
    self.primary_key = :id
    options.each do |option, value|
      send("#{option}=", value) if self.class.options.include?(option)
    end
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options
    define_method(name) do
      options.model_class.find(send(options.foreign_key))
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.name, options)
    define_method(name) do
      options.model_class.where(options.foreign_key => id)
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
