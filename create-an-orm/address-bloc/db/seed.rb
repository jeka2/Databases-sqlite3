 require_relative '../models/address_book'
 require_relative '../models/entry'
 require 'bloc_record'
 
 BlocRecord.connect_to('db/address_bloc.sqlite')
 
 book = AddressBook.create(name: 'My Address Book')
 
 Entry.find_each { |d| p d.name }