# Include hook code here
require 'rubygems'
require 'activesupport'
require 'packed_flags'

ActiveRecord::Base.send(:extend, EX::PackedFlags::ClassMethods)
