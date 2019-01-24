 require_relative '../models/address_book'
 require_relative '../models/entry'
 require 'bloc_record'
 
 BlocRecord.connect_to('db/address_bloc.sqlite')
 
 Entry.destroy_all("phone_number = ?", '111-111-1111')
 p Entry.all