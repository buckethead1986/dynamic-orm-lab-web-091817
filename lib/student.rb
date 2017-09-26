require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'interactive_record.rb'

class Student < InteractiveRecord
  self.column_names.each do |column_name| #column names is an inherited method from InteractiveRecord. run each on it to grab each column name and convert it to an accessor
    attr_accessor column_name.to_sym
  end
end
