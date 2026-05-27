# -*- encoding: utf-8; frozen_string_literal: true -*-
#
#--
# This file is part of HexaPDF.
#
# HexaPDF - A Versatile PDF Creation and Manipulation Library For Ruby
# Copyright (C) 2014-2025 Thomas Leitner
#
# HexaPDF is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License version 3 as
# published by the Free Software Foundation with the addition of the
# following permission added to Section 15 as permitted in Section 7(a):
# FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
# THOMAS LEITNER, THOMAS LEITNER DISCLAIMS THE WARRANTY OF NON
# INFRINGEMENT OF THIRD PARTY RIGHTS.
#
# HexaPDF is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public
# License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with HexaPDF. If not, see <http://www.gnu.org/licenses/>.
#
# The interactive user interfaces in modified source and object code
# versions of HexaPDF must display Appropriate Legal Notices, as required
# under Section 5 of the GNU Affero General Public License version 3.
#
# In accordance with Section 7(b) of the GNU Affero General Public
# License, a covered work must retain the producer line in every PDF that
# is created or manipulated using HexaPDF.
#
# If the GNU Affero General Public License doesn't fit your need,
# commercial licenses are available at <https://gettalong.at/hexapdf/>.
#++

module HexaPDF

  # == Overview
  #
  # The Task module contains task implementations which are used to perform operations that affect
  # a whole PDF document instead of just a single object.
  #
  # Normally, such operations would be implemented by using methods on the HexaPDF::Document class.
  # However, this would clutter up the document interface with various methods and also isn't very
  # extensible.
  #
  # A task name that can be used for HexaPDF::Document#task is mapped to a task object via the
  # 'task.map' configuration option.
  #
  #
  # == Implementing a Task
  #
  # A task is simply a callable object that takes the document as first mandatory argument and can
  # optionally take keyword arguments and/or a block. This means that a block suffices.
  #
  # Here is a simple example:
  #
  #   doc = HexaPDF::Document.new
  #   doc.config['task.map'][:validate] = lambda do |doc|
  #     doc.each {|obj| obj.validate || raise "Invalid object #{obj}"}
  #   end
  module Task

    autoload(:Optimize, 'hexapdf/task/optimize')
    autoload(:Dereference, 'hexapdf/task/dereference')
    autoload(:PDFA, 'hexapdf/task/pdfa')
    autoload(:MergeAcroForm, 'hexapdf/task/merge_acro_form')

  end

end
