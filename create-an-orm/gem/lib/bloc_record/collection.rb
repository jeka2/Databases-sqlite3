module BlocRecord
   class Collection < Array
     def update_all(updates)
       ids = self.map(&:id)
       self.any? ? self.first.class.update(ids, updates) : false
     end

     def take
       take_array = []
       sample = self.each { |x| take_array << x }.sample
       sample
     end

     def where(*args)
     	id_condition = ""
     	self.each { |obj| id_condition.concat("#{obj.id} OR ") }
     	id_condition = id_condition[0...-3]
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
        p expression
     end
     end
   end
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