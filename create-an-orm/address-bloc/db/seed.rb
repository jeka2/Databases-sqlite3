 require_relative '../models/address_book'
 require_relative '../models/entry'
 require 'bloc_record'
 
 BlocRecord.connect_to('db/address_bloc.sqlite')

 entries = {1 => {name: 'first_changed', phone_number: '333-333-3333'}, 2 => {phone_number: '999-999-9999'}, 3 => {name: 'third changed'}}
 e = Entry.where(id: 25)
 e.save
 Entry.where(name: 'name').where()
