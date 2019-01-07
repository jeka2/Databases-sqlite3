require 'sqlite3'

module Selection

	def find(*ids)
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

  def where(*args)
    if args.count > 1
       expression = args.shift
       params = args
    else
       case args.first
       when String
         expression = args.first
       when Hash
         expression_hash = BlocRecord::Utility.convert_keys(args.first)
         expression = expression_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
       end
     end

     sql = <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       WHERE #{expression};
     SQL

     rows = connection.execute(sql, params)
     rows_to_array(rows)
   end

   def order(*args)
     order_holder = []
     args.each do |val|
      if val.instance_of? Hash
        order_holder << "#{val.keys[0].to_s} #{val.values[0].to_s}"
      else
        order_holder << val.to_s
      end
     end
     if args.count > 1
       order = order_holder.join(",")
     else
       order = order_holder.first
     end
     rows = connection.execute <<-SQL
       SELECT * FROM #{table}
       ORDER BY #{order};
     SQL
     rows_to_array(rows)
    end

   def join(*args)
     if args.first.instance_of? Hash
      ##This was created with the assumption that that hash would not exceed a single key-value pair, as it would be overkill otherwise
      args = [args.keys[0].to_s, args.values[0].to_s]
      query_holder = []
      args.each_with_index do |arg, i| 
        if i == 0
          query_holder << "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id "
        else
          query_holder << "INNER JOIN #{arg} ON #{arg}.#{args[i - 1]}_id = #{args[i - 1]}.id "
        end
      end
      rows = connection.execute <<-SQL
        SELECT * FROM #{table}
        #{query_holder.join ""};
      SQL
      return
     end
     if args.count > 1
       joins = args.map { |arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}.join(" ")
       rows = connection.execute <<-SQL
         SELECT * FROM #{table} #{joins}
       SQL
     else
       case args.first
       when String
         rows = connection.execute <<-SQL
           SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(args.first)};
         SQL
       when Symbol
         rows = connection.execute <<-SQL
           SELECT * FROM #{table}
           INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id
         SQL
       end
     end
 
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

end