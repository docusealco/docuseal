# frozen_string_literal: true

module Zip
  class ExtraField < Hash # :nodoc:all
    ID_MAP = {}

    def initialize(binstr = nil, local: false)
      merge(binstr, local: local) if binstr
    end

    def extra_field_type_exist(binstr, id, len, index)
      field_name = ID_MAP[id].name
      if member?(field_name)
        self[field_name].merge(binstr[index, len + 4])
      else
        field_obj        = ID_MAP[id].new(binstr[index, len + 4])
        self[field_name] = field_obj
      end
    end

    def extra_field_type_unknown(binstr, len, index, local)
      self[:unknown] ||= Unknown.new

      if !len || len + 4 > binstr[index..].bytesize
        self[:unknown].merge(binstr[index..], local: local)
        return
      end

      self[:unknown].merge(binstr[index, len + 4], local: local)
    end

    def merge(binstr, local: false)
      return if binstr.empty?

      i = 0
      while i < binstr.bytesize
        id  = binstr[i, 2]
        len = binstr[i + 2, 2].to_s.unpack1('v')
        if id && ID_MAP.member?(id)
          extra_field_type_exist(binstr, id, len, i)
        elsif id
          break unless extra_field_type_unknown(binstr, len, i, local)
        end
        i += len + 4
      end
    end

    def create(name)
      unless (field_class = ID_MAP.values.find { |k| k.name == name })
        raise Error, "Unknown extra field '#{name}'"
      end

      self[name] = field_class.new
    end

    # Place Unknown last, so "extra" data that is missing the proper
    # signature/size does not prevent known fields from being read back in.
    def ordered_values
      result = []
      each { |k, v| k == :unknown ? result.push(v) : result.unshift(v) }
      result
    end

    # Remove any extra fields that indicate they can be safely suppressed.
    def suppress_fields!(fields)
      reject! do |k, v|
        v.suppress? if fields == true || [*fields].include?(k)
      end
    end

    def to_local_bin
      ordered_values.map! { |v| v.to_local_bin.force_encoding('BINARY') }.join
    end

    alias to_s to_local_bin

    def to_c_dir_bin
      ordered_values.map! { |v| v.to_c_dir_bin.force_encoding('BINARY') }.join
    end

    def c_dir_size
      to_c_dir_bin.bytesize
    end

    def local_size
      to_local_bin.bytesize
    end

    alias length local_size
    alias size local_size
  end
end

require 'zip/extra_field/unknown'
require 'zip/extra_field/generic'
require 'zip/extra_field/universal_time'
require 'zip/extra_field/old_unix'
require 'zip/extra_field/unix'
require 'zip/extra_field/zip64'
require 'zip/extra_field/ntfs'
require 'zip/extra_field/aes'

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
