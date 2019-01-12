require 'sqlite3'
require 'bloc_record/schema'

module Persistence

  def method_missing(m, *args, &block)
       if m[0...7] == 'update_'
        update_attribute( m[7..-1], args[0] )
       else
        super
       end
  end

	def self.included(base)
		base.extend(ClassMethods)
	end

	def save
		self.save! rescue false
	end

	def save!
		unless self.id
       	  self.id = self.class.create(BlocRecord::Utility.instance_variables_to_hash(self)).id
       	  BlocRecord::Utility.reload_obj(self)
       	  return true
    end

		fields = self.class.attributes.map { |col| "#{col}=#{BlocRecord::Utility.sql_strings(self.instance_variable_get("@#{col}"))}" }.join(",")
 
     self.class.connection.execute <<-SQL
       UPDATE #{self.class.table}
       SET #{fields}
       WHERE id = #{self.id};
     SQL
 
     true
  end

  def update_attribute(attribute, value)
     self.class.update(self.id, { attribute => value })
  end

  def update_attributes(updates)
    self.class.update(self.id, updates)
  end

	module ClassMethods

     def update_all(updates)
       update(nil, updates)
     end

     def update(ids, updates)
       if ids.instance_of? Array
        ids.each { |id| error_handler('Id\'s must all be integers') if !id.instance_of? Fixnum }
        multiple_record_update = true
       else
         error_handler('The id you provided is not an integer') if !ids.instance_of? Fixnum
       end 
       error_handler('Please make sure you\'re updating the record(s) properly') if !updates_are_viable?(updates)
       if multiple_record_update
        u = Hash[ids.zip(updates)]
        u.each do |key, val|
          value =  BlocRecord::Utility.convert_keys(val)
          set_statement = ""
          if value.count > 1
            value.each { |k, v| set_statement.concat("#{k} = #{BlocRecord::Utility.sql_strings(v)},") }
          else
            set_statement = set_statement.concat("#{value.keys[0]} = #{BlocRecord::Utility.sql_strings(value.values[0])},")
          end
          set_statement.slice!(-1)
          connection.execute <<-SQL
            UPDATE #{table}
            SET #{set_statement}
            WHERE id = #{key};
          SQL
          
        end
        return true
       end
       updates = BlocRecord::Utility.convert_keys(updates)
       updates.delete "id"
       updates_array = updates.map { |key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}" }
       if ids.class == Fixnum
         where_clause = "WHERE id = #{ids};"
       elsif ids.class == Array
         where_clause = ids.empty? ? ";" : "WHERE id IN (#{ids.join(",")});"
       else
         where_clause = ";"
       end

       connection.execute <<-SQL
         UPDATE #{table}
         SET #{updates_array * ","} #{where_clause}
       SQL

       true
     end

     def create(attrs)
       attrs = BlocRecord::Utility.convert_keys(attrs)
       attrs.delete "id"
       vals = attributes.map { |key| BlocRecord::Utility.sql_strings(attrs[key]) }
 
       connection.execute <<-SQL
         INSERT INTO #{table} (#{attributes.join ","})
         VALUES (#{vals.join ","});
       SQL
 
       data = Hash[attributes.zip attrs.values]
       data["id"] = connection.execute("SELECT last_insert_rowid();")[0][0]
       new(data)
     end

       private
        def error_handler(error)
          p error
          exit(0)
        end

        def updates_are_viable?(updates) ##CHECKS FOR PROPER KEYS IN ALL THE RECORDS. :NAME WOULD RETURN TRUE WHILE :NAM WOULD RETURN FALSE
          key_check = []
          updates.each do |update|
            if update.instance_of? Array
              key = update[0]
            elsif update.instance_of? Hash
              key = update.keys[0].to_s
            end
            self.columns.each do |col|
              if col.to_s == key
                key_check << 'exists'
                break
              end
            end
          end
          if key_check.length != updates.length ##IF THE LENGTHS ARE DIFFERENT, ONE OR MORE OF THE KEY NAMES DID NOT CORRESPOND TO AN EXISTING COLUMN NAME
            return false
          else
            return true
          end
        end
   end

end