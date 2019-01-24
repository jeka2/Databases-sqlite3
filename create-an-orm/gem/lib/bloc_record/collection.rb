module BlocRecord
   class Collection < Array
     def update_all(updates)
       ids = self.map(&:id)
       self.any? ? self.first.class.update(ids, updates) : false
     end

     def destroy_all
      id_holder = []
      self.each { |obj| id_holder << obj.id } 
      connection.execute <<-SQL
        DELETE FROM #{self[0].class.table}
        WHERE id IN (#{id_holder.join(",")});
      SQL
     end
   end
end