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
        exit(0)
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
      exit(0)
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

  def find_each(batch_support = {})
    return error_handler("no data provided") unless block_given? || !batch_support.empty?
    unless batch_support.empty?
      start = batch_support[:start]
      batch_size = batch_support[:batch_size]
      rows = connection.execute <<-SQL
         SELECT #{columns.join ","} FROM #{table}
         LIMIT #{batch_size}
         OFFSET #{start}; 
      SQL
      rows = rows_to_array(rows)
      rows.each { |obj| p "Record by id of:#{obj.id} is #{yield(obj)}" }
    else
      self.all.each { |obj| p "Record by id of:#{obj.id} is #{yield(obj)}" }
    end
  end

  def find_in_batches(batch_support = {})
    return error_handler("no data provided") unless block_given? && !batch_support.empty?
    start = batch_support[:start]
    batch_size = batch_support[:batch_size]
    rows = connection.execute <<-SQL
         SELECT #{columns.join ","} FROM #{table}
         LIMIT #{batch_size}
         OFFSET #{start}; 
    SQL
    rows = rows_to_array(rows)
    yield(rows)
  end

  def take(num=1)
     begin 
      raise "Wrong argument type" if !(num.instance_of? Fixnum)
      raise "The number exceeds number of records" if self.count > num
      raise "Please provide a proper number" if num < 1
     rescue RuntimeError => e
      p e.message
      exit(0)
     end
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
   def error_handler(err)
    if err === "no data provided"
      p "No blocks or arguments provided"
    end
   end

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