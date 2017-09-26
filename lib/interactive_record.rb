require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord
  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true #sets db results to come as hash, not [[array]]

    sql = "PRAGMA table_info('#{table_name}')" #memorize. this is how to get table data. #{table_name} is from self.table_name. returns an array of hashes

    table_data = DB[:conn].execute(sql) #execute the sql code we just wrote
    column_names_array = [] #empty array to push column names onto
    table_data.each do |row| #iterate over executed sql code containing table data
      column_names_array << row["name"] #table_data is giant hash, only want the "name" keys as our column names. also, its a string, not a symbol
    end
      column_names_array.compact #might have some nil values. compact gets rid of them.
  end

  def initialize(parameters = {})
    parameters.each do |property, value|
      self.send("#{property}=", value) # '#{property}=' is a goddamn setter. method. not a string, its a string passed to send which interprets it as a method. Somehow value gets passed to it, still not clear.
    end
  end

  def table_name_for_insert #we want an instance method where we already have a class method.
    self.class.table_name #instance method, self.class makes it call the class, which calls on the table_name class method above.
  end

  def col_names_for_insert #call on Class (self.class) to call column_names method, which will return "id" as well as others, so delete that value.
    self.class.column_names.delete_if {|column_name| column_name == "id"}.join(", ") #join because it returns an array, and ", " because otherwise it returns "namegrade", not "name, grade"
  end #we want to convert the coluimn names array to a comma separated string for insertion into table

  def values_for_insert
    values = [] #empty array to shovel values onto
    self.class.column_names.each do |col_name| #already got column names in other method, iterate over each
      values << "'#{send(col_name)}'" unless send(col_name).nil? #shovel values using abstract getter method via 'send method on col_name' that gets values of each column.
    end
    values.join(", ") #values are shoveled with " and ' to have final result, from 'getting' from their column name called on this instance method, to be encased in ' '
  end

  def save #ave data by inserting abstracted values, using prior methods
    sql = <<-SQL
    INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})
    SQL
    DB[:conn].execute(sql) #execute sql code above, get id of newly saved data below.
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name) #select all from table_name, class method returning abstract table name, where name = name given as parameter. execute db passing in name as ?
    sql = <<-SQL
    SELECT * FROM #{table_name} WHERE name = ?
    SQL
    DB[:conn].execute(sql, name)
  end

  def self.find_by(hash) #element passed in is {:key => "value"} format
    key = hash.keys.first #gets all keys, only 1 in this case, and get the first key from that.
    value = hash[key]
    sql = <<-SQL
    SELECT * FROM #{table_name} WHERE #{key} = '#{value}'
    SQL
    DB[:conn].execute(sql) # '#{value}'' must be in quotes otherwise its interpreted as a column/variable?
  end
  
end
