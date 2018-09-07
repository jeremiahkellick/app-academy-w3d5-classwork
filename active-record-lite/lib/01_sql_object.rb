require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    @columns ||= DBConnection.execute2(
      "SELECT * FROM #{table_name}"
    ).first.map(&:to_sym)
  end

  def self.finalize!
    columns.each do |column|
      define_method(column) { attributes[column] }
      define_method("#{column}=") { |value| attributes[column] = value }
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || to_s.tableize
  end

  def self.all
    parse_all(DBConnection.execute("SELECT * FROM #{table_name}"))
  end

  def self.parse_all(results)
    results.map { |obj_hash| new(obj_hash) }
  end

  def self.find(id)
    parse_all(DBConnection.execute(<<-SQL, id)).first
      SELECT * FROM #{table_name} WHERE id = ?
    SQL
  end

  def initialize(params = {})
    params.each do |attribute, value|
      attribute = attribute.to_sym
      unless self.class.columns.include?(attribute)
        raise ArgumentError, "unknown attribute '#{attribute}'"
      end
      send("#{attribute}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    attributes.values
  end

  def insert
    DBConnection.execute(<<-SQL, *attributes.values)
      INSERT INTO
        #{self.class.table_name} (#{attributes.keys.join(", ")})
      VALUES
        (#{(["?"] * attributes.length).join(", ")})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    attributes_without_id = attributes.dup
    attributes_without_id.delete(:id)
    DBConnection.execute(<<-SQL, *attributes_without_id.values)
      UPDATE
        #{self.class.table_name}
      SET
        #{attributes_without_id.keys.join(" = ?, ")} = ?
    SQL
  end

  def save
    id.nil? ? insert : update
  end
end
