require_relative 'db_connection'
require 'active_support/inflector'

# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    table = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        "#{self.table_name}"
    SQL
    table.first.map{|col| col.to_sym}
  end

  def self.finalize!
    self.columns.each do |col|
      define_method(col) { attributes[col] }
      define_method("#{col}=")  do |value|
        attributes[col] = value
      end
    end

  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        "#{self.table_name}"
    SQL
    parse_all(results)
  end

  def self.parse_all(results)
    results.map do |hash|
      self.new(hash)
    end
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
    SELECT
      *
    FROM
      "#{self.table_name}"
    WHERE
      id = ?
    SQL
    parse_all(results).first
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      if self.class.columns.include?(attr_name) == false
        raise StandardError.new "unknown attribute '#{attr_name}'"
      end
      send("#{attr_name}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    #method that returns an array of the values for each attribute.
    #I did this by calling Array#map on SQLObject::columns,
    #calling send on the instance to get the value.
    self.class.columns.map do |col|
      send(col)
    end
  end

  def insert
    col_names = self.class.columns.join(", ")
    question_marks = (["?"] * self.class.columns.length).join(", ")
    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    col_names = self.class.columns.join("= ?, ")
    col_names << " = ?"
    DBConnection.execute(<<-SQL, *attribute_values, self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{col_names}
      WHERE
        id = ?
    SQL
  end

  def save
    if id
      update
    else
      insert
    end
  end
end
