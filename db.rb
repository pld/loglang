require 'rubygems'
require 'active_record'
require 'pg'

# create a class for employee records (the class is singular but the table is plural)
class ActionLog < ActiveRecord::Base
  set_table_name "actionlog"
  attr_accessor :queries, :terms
end

# connect to the database
ActiveRecord::Base.establish_connection(:adapter => 'postgresql',
                                        :host => 'localhost',
                                        :username => 'postgres',
                                        :database => 'logclef2009_UTF8');
                                        