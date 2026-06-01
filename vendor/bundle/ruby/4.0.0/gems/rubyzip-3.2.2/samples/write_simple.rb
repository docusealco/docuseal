#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '../lib'

require 'zip'

Zip::OutputStream.open('simple.zip') do |zos|
  zos.put_next_entry 'entry.txt'
  zos.puts 'Hello world'
end
