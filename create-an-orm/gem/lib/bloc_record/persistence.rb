require 'sqlite3'
require 'bloc_record/schema'

module Persistence

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

  def destroy
     self.class.destroy(self.id)
  end

  def destroy_all
    p self
  end

	module ClassMethods

     def update_all(updates)
       update(nil, updates)
     end

     def destroy(*id)
       if id.length > 1
         where_clause = "WHERE id IN (#{id.join(",")});"
       else
         where_clause = "WHERE id = #{id.first};"
       end
       connection.execute <<-SQL
         DELETE FROM #{table} #{where_clause}
       SQL
 
       true
     end

     def destroy_all(conditions_hash=nil, *args)
       case conditions_hash
       when nil
        connection.execute <<-SQL
           DELETE FROM #{table}
        SQL
       when String
        if !args.empty?
          if args.count.odd? ##IF THERE IS AN APPROPRIATE NUMBER OF ELEMENTS - OR ONE CONDITION FOR EVERY VARIABLE
            key_array = [conditions_hash.delete("?")]
            value_array =  [BlocRecord::Utility.sql_strings(args[0])]
            if args.count > 1
              1.upto(args.count) do |index| 
                key_array.concat(" AND ")
                if index.odd? 
                  key_array << args[index].delete("?")
                else
                  value_array << BlocRecord::Utility.sql_strings(args[index])
                end
              end
            end
            conditions = key_array.zip(value_array)
            conditions.each do |condition|
              key = condition[0]
              value = condition[1]
              connection.execute <<-SQL
                DELETE FROM #{table}
                WHERE #{key} #{value};
              SQL
            end
          else
            puts "Please make sure you put it in the proper condition"
            exit(0)
          end
        else
          condition_string = conditions_hash
          connection.execute <<-SQL
            DELETE FROM #{table}
            WHERE #{condition_string};
          SQL
        end
       when Hash
        conditions_hash = BlocRecord::Utility.convert_keys(conditions_hash)
         conditions = conditions_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
 
         connection.execute <<-SQL
           DELETE FROM #{table}
           WHERE #{conditions};
         SQL
       end
       true
     end

     def update(ids, updates)
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
   end
end