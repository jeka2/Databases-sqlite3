 require_relative '../models/address_book'
 require_relative '../models/entry'
 require 'bloc_record'
 
 BlocRecord.connect_to('db/address_bloc.sqlite')

 #Entry.find_each { |d| d.name }
 #Entry.find_each(start: 2, batch_size: 3) { |d| d.name }
 Entry.find_in_batches(start: 2, batch_size: 3) do |vals|
 	vals.each { |val| p val.name }
 end