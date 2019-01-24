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
       key_holder = []
       value_holder = []
       record_holder = []
       args.each do |pairs|
        pairs.each do |key_value|
          key_holder <<  key_value[0].to_s
          value_holder << key_value[1]
        end
       end
       if !(key_holder - self[0].class.columns).empty?
         p "One or more of the keys you provided aren't recognized by the database"
         exit(0)
       end
       self.each do |obj|
         matches_found = 0
         0.upto(key_holder.length - 1) do |index|
          if obj.send(key_holder[index]) === value_holder[index]
            matches_found += 1 
          end
         end
         if matches_found == key_holder.length
          record_holder << obj
         end
       end
       record_holder
     end

     def not(*args)
      key_holder = []
       value_holder = []
       record_holder = []
       args.each do |pairs|
        pairs.each do |key_value|
          key_holder <<  key_value[0].to_s
          value_holder << key_value[1]
        end
       end
       if !(key_holder - self[0].class.columns).empty?
         p "One or more of the keys you provided aren't recognized by the database"
         exit(0)
       end
       self.each do |obj|
         matches_found = 0
         0.upto(key_holder.length - 1) do |index|
          if obj.send(key_holder[index]) === value_holder[index]
            matches_found += 1 
          end
         end
         unless matches_found == key_holder.length
          record_holder << obj
         end
       end
       record_holder
     end
 end
end

