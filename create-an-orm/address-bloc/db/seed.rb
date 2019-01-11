 require_relative '../models/address_book'
 require_relative '../models/entry'
 require 'bloc_record'
 
 BlocRecord.connect_to('db/address_bloc.sqlite')


 Entry.create(address_book_id: 1, name: 'first_name', phone_number: '999-999-9999', email: 'something@something.com')
 Entry.create(address_book_id: 1, name: 'second_name', phone_number: '999-999-9998', email: 'somethingelse@something.com')
 Entry.create(address_book_id: 1, name: 'third_name', phone_number: '999-999-9997', email: 'somethingelseelse@something.com')

 entries = {1 => {name: 'first_changed', phone_number: '333-333-3333'}, 2 => {phone_number: '999-999-9999'}, 3 => {name: 'third changed'}}
 
 Entry.update_first_name(entries.keys, entries.values)
