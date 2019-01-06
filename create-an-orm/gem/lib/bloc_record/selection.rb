require 'sqlite3'

module Selection
  def method_missing(m, *args, &block)
    if m[0...8] === 'find_by_'
      value = args[0]
      attribute_name = validate_name(m[8..-1])
      begin 
        raise "Improper method name" if !attribute_name
      rescue RuntimeError => e
        p e.message
      end
      find_by(attribute_name, value)
    else 
      super
    end
  end

	def find(*ids)
     id_is_valid = validate_ids(*ids)
     begin 
      raise "Invalid Id" if !id_is_valid
     rescue RuntimeError => e
      p e.message
     end
     if ids.length == 1
       find_one(ids.first)
     else
       rows = connection.execute <<-SQL
         SELECT #{columns.join ","} FROM #{table}
         WHERE id IN (#{ids.join(",")});
       SQL

       rows_to_array(rows)
     end
  end

	def find_one(id)
		row = connection.get_first_row <<-SQL
			SELECT #{columns.join ","} FROM #{table}
			WHERE id = #{id};
		SQL

		init_object_from_row(row)
	end

  def find_by(attribute, value)
     rows = connection.execute <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
     SQL
 
     rows_to_array(rows)
  end

  def take(num=1)
     if num > 1
       rows = connection.execute <<-SQL
         SELECT #{columns.join ","} FROM #{table}
         ORDER BY random()
         LIMIT #{num};
       SQL
 
       rows_to_array(rows)
     else
       take_one
     end
  end

  def take_one
     row = connection.get_first_row <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       ORDER BY random()
       LIMIT 1;
     SQL
 
     init_object_from_row(row)
  end

  def first
     row = connection.get_first_row <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       ORDER BY id ASC LIMIT 1;
     SQL
 
     init_object_from_row(row)
   end
 
   def last
     row = connection.get_first_row <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       ORDER BY id DESC LIMIT 1;
     SQL
 
     init_object_from_row(row)
  end

  def all
     rows = connection.execute <<-SQL
       SELECT #{columns.join ","} FROM #{table};
     SQL
 
     rows_to_array(rows)
  end


   private
   def init_object_from_row(row)
     if row
       data = Hash[columns.zip(row)]
       new(data)
     end
   end

   def rows_to_array(rows)
     rows.map { |row| new(Hash[columns.zip(row)]) }
   end

    def validate_ids(*ids)
      ids.map { |id| return false if id < 1 }
      all_ids = []
      self.all.each { |i| all_ids << i.id }
      return all_ids.any? { |i| ids.include? i }
    end

    def validate_name(name)
      columns.each { |n| return name if n === name}
      return false
    end

end