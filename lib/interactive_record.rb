require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

  def self.table_name   # creates table name
    self.to_s.downcase.pluralize
  end

  def self.column_names   # creates an array with column names without nil values
    query = "PRAGMA table_info('#{table_name}')"
    column_names = []
    DB[:conn].execute(query).each {|i|
      column_names << i["name"]
    }
    column_names.compact
  end

  def initialize(options={})    # brings in any arguments(these are column names and attr_accessors)
    options.each do |k, v|
      self.class.attr_accessor k.to_sym   # creates an attr_accessor for each key
      self.send("#{k}=", v)     # assigns the value to the key/attr_accessor
    end
  end

  def table_name_for_insert   # gets the table name for query
    self.class.table_name
  end

  def col_names_for_insert    # gets column names for query
    self.class.column_names.delete_if {|col_name| col_name == "id"}.join(", ")
  end

  def values_for_insert       # gets column values for query
    values = []   # empty array
    self.class.column_names.each {|name|  
      values << "'#{send(name)}'" unless send(name).nil?   # puts values in array unless value == nil
    } 
    values.join(", ")   # joins them with ', ' to format for query
  end

  def save  # saves instance into table, assigns id, returns instance
    query = <<-SQL
    INSERT INTO #{self.table_name_for_insert} (#{col_names_for_insert}) 
    VALUES (#{self.values_for_insert})
    SQL
    DB[:conn].execute(query)
    self.id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{self.table_name_for_insert}")[0][0] # assigns id values
    self
  end

  def self.find_by_name(name) 
    query = "SELECT * FROM students WHERE name == ?"
    DB[:conn].execute(query, name)
  end
  
  def self.find_by(identifier)  #=> array for match using any argument hash input
    query = <<-SQL
      SELECT * FROM #{self.table_name}
      WHERE #{identifier.keys.first.to_s} == '#{identifier.values.first}'
    SQL
    DB[:conn].execute(query)
  end
end