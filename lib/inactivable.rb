# Todo : remove warning: already initialized constant inactivable
# Todo : Exceptions
# Todo : CallBacks Next
# Todo : Table Collide system
require 'inactivable/exceptions'
module Inactivable
  BACKED_AT_COLUMN_NAME = "inactivated_at"

  def self.included(base)
    base.extend ClassMethods
  end

  def inactivate!
    inactivated_object = self.class.inactivated_model_class.new(attributes.merge(BACKED_AT_COLUMN_NAME => Time.now))
    inactivated_object.send("#{self.class.primary_key}=", attributes[self.class.primary_key])
    inactivated_object.save
    self.delete ##
    inactivated_object
  end

  def reactivate!
    _attributes = attributes.clone
    _attributes.delete(nil)
    _attributes.delete(BACKED_AT_COLUMN_NAME)

    reactivated_object = self.class.reactivated_model_class.new(_attributes)
    reactivated_object.send("#{self.class.reactivated_model_class.primary_key}=", _attributes[self.class.reactivated_model_class.primary_key])
    reactivated_object.save
    puts self.inspect
    self.delete
    reactivated_object
  end

  module ClassMethods

    #TODO: make it more generic so where instead
    def inactivated_list(option)
      inactivated_model_class.find(option)
    end

    def get_other_model_name
      self.columns_hash[BACKED_AT_COLUMN_NAME].nil? ? "Inactive#{self.name}" : self.name.gsub("Inactive", "")
    end

    def inactivated_model_class
      inactivated_klass = Object.const_set(get_other_model_name, Class.new(ActiveRecord::Base))
      adjust_table_definition(inactivated_klass)
      inactivated_klass.send("primary_key=", primary_key)
      inactivated_klass.send(:include, Inactivable)
      inactivated_klass
    end

    def adjust_table_definition(model)
      is_schema_changed = false
      unless model.table_exists?
        puts "Creating #{model.table_name}"
        connection.create_table "#{model.table_name}", :id => false do |t|
          t.column :inactivated_at, :datetime
        end
        is_schema_changed = true
      else
        puts "#{model.table_name} already exists"
      end

      #TODO: add functionality to update column definition on column definition change
      self.columns_hash.each do |column_name, column_object|
        if model.columns_hash[column_name].nil?
          puts "Adding column #{column_name}"
          connection.change_table "#{model.table_name}" do |t|
            t.column(column_name, columns_hash[column_name].type)
          end
          is_schema_changed = true
        end
      end

      if is_schema_changed
        model.connection.schema_cache.clear!
        model.reset_column_information
      end
    end

    def reactivated_model_class
      reactivated_klass = Object.const_set(get_other_model_name, Class.new(ActiveRecord::Base))
      reactivated_klass.send("primary_key=", primary_key)
      reactivated_klass.send(:include, Inactivable)
      reactivated_klass
    end

  end

end