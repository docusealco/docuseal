# frozen_string_literal: true

module Numo
  class NArray
    # Return an unallocated array with the same shape and type as self.
    def new_narray
      self.class.new(*shape)
    end

    # Return an array of zeros with the same shape and type as self.
    def new_zeros
      self.class.zeros(*shape)
    end

    # Return an array of ones with the same shape and type as self.
    def new_ones
      self.class.ones(*shape)
    end

    # Return an array filled with value with the same shape and type as self.
    def new_fill(value)
      self.class.new(*shape).fill(value)
    end

    # Convert angles from radians to degrees.
    def rad2deg
      self * (180 / Math::PI)
    end

    # Convert angles from degrees to radians.
    def deg2rad
      self * (Math::PI / 180)
    end

    # Flip each row in the left/right direction.
    # Same as `a[true, (-1..0).step(-1), ...]`.
    def fliplr
      reverse(1)
    end

    # Flip each column in the up/down direction.
    # Same as `a[(-1..0).step(-1), ...]`.
    def flipud
      reverse(0)
    end

    # Rotate in the plane specified by axes.
    # @example
    #   a = Numo::Int32.new(2,2).seq
    #   # => Numo::Int32#shape=[2,2]
    #   # [[0, 1],
    #   #  [2, 3]]
    #
    #   a.rot90
    #   # => Numo::Int32(view)#shape=[2,2]
    #   # [[1, 3],
    #   #  [0, 2]]
    #
    #   a.rot90(2)
    #   # => Numo::Int32(view)#shape=[2,2]
    #   # [[3, 2],
    #   #  [1, 0]]
    #
    #   a.rot90(3)
    #   # => Numo::Int32(view)#shape=[2,2]
    #   # [[2, 0],
    #   #  [3, 1]]
    def rot90(k = 1, axes = [0, 1])
      case k % 4
      when 0
        view
      when 1
        swapaxes(*axes).reverse(axes[0])
      when 2
        reverse(*axes)
      when 3
        swapaxes(*axes).reverse(axes[1])
      end
    end

    def to_i
      # convert to Int?
      raise TypeError, "can't convert #{self.class} into Integer" unless size == 1

      self[0].to_i
    end

    def to_f
      # convert to DFloat?
      raise TypeError, "can't convert #{self.class} into Float" unless size == 1

      self[0].to_f
    end

    def to_c
      # convert to DComplex?
      raise TypeError, "can't convert #{self.class} into Complex" unless size == 1

      Complex(self[0])
    end

    # Convert the argument to an narray if not an narray.
    def self.cast(a)
      case a
      when NArray
        a
      when Array, Numeric
        NArray.array_type(a).cast(a)
      else
        raise TypeError, 'invalid type for NArray' unless a.respond_to?(:to_a)

        a = a.to_a
        NArray.array_type(a).cast(a)
      end
    end

    # Convert the argument to an narray.
    def self.asarray(a)
      case a
      when NArray
        a.ndim == 0 ? a[:new] : a
      when Numeric, Range
        self[a]
      else
        cast(a)
      end
    end

    # parse matrix like matlab, octave
    # @example
    #   a = Numo::DFloat.parse %[
    #    2 -3 5
    #    4 9 7
    #    2 -1 6
    #   ]
    #   # => Numo::DFloat#shape=[3,3]
    #   # [[2, -3, 5],
    #   #  [4, 9, 7],
    #   #  [2, -1, 6]]

    def self.parse(str, split1d: /\s+/, split2d: /;?$|;/,
                   split3d: /\s*\n(\s*\n)+/m)
      a = []
      str.split(split3d).each do |block|
        b = []
        # print "b"; p block
        block.split(split2d).each do |line|
          # p line
          line.strip!
          next if line.empty?

          c = []
          line.split(split1d).each do |item|
            c << eval(item.strip) unless item.empty? # rubocop:disable Security/Eval
          end
          b << c unless c.empty?
        end
        a << b unless b.empty?
      end
      if a.size == 1
        cast(a[0])
      else
        cast(a)
      end
    end

    # Iterate over an axis
    # @example
    #   > a = Numo::DFloat.new(2,2,2).seq
    #   > p a
    #   Numo::DFloat#shape=[2,2,2]
    #   [[[0, 1],
    #     [2, 3]],
    #    [[4, 5],
    #     [6, 7]]]
    #
    #   > a.each_over_axis{|i| p i}
    #   Numo::DFloat(view)#shape=[2,2]
    #   [[0, 1],
    #    [2, 3]]
    #   Numo::DFloat(view)#shape=[2,2]
    #   [[4, 5],
    #    [6, 7]]
    #
    #   > a.each_over_axis(1){|i| p i}
    #   Numo::DFloat(view)#shape=[2,2]
    #   [[0, 1],
    #    [4, 5]]
    #   Numo::DFloat(view)#shape=[2,2]
    #   [[2, 3],
    #    [6, 7]]

    def each_over_axis(axis = 0)
      return to_enum(:each_over_axis, axis) unless block_given?

      if ndim == 0
        raise ArgumentError, "axis=#{axis} is invalid" if axis != 0

        niter = 1
      else
        axis = check_axis(axis)
        niter = shape[axis]
      end
      idx = [true] * ndim
      niter.times do |i|
        idx[axis] = i
        yield(self[*idx])
      end
      self
    end

    # Append values to the end of an narray.
    # @example
    #   a = Numo::DFloat[1, 2, 3]
    #   a.append([[4, 5, 6], [7, 8, 9]])
    #   # => Numo::DFloat#shape=[9]
    #   # [1, 2, 3, 4, 5, 6, 7, 8, 9]
    #
    #   a = Numo::DFloat[[1, 2, 3]]
    #   a.append([[4, 5, 6], [7, 8, 9]],axis:0)
    #   # => Numo::DFloat#shape=[3,3]
    #   # [[1, 2, 3],
    #   #  [4, 5, 6],
    #   #  [7, 8, 9]]
    #
    #   a = Numo::DFloat[[1, 2, 3], [4, 5, 6]]
    #   a.append([7, 8, 9], axis:0)
    #   # in `append': dimension mismatch (Numo::NArray::DimensionError)

    def append(other, axis: nil)
      other = self.class.cast(other)
      if axis
        raise DimensionError, 'dimension mismatch' if ndim != other.ndim

        concatenate(other, axis: axis)
      else
        a = self.class.zeros(size + other.size)
        a[0...size] = self[true]
        a[size..-1] = other[true]
        a
      end
    end

    # Return a new array with sub-arrays along an axis deleted.
    # If axis is not given, obj is applied to the flattened array.

    # @example
    #   a = Numo::DFloat[[1,2,3,4], [5,6,7,8], [9,10,11,12]]
    #   a.delete(1,0)
    #   # => Numo::DFloat(view)#shape=[2,4]
    #   # [[1, 2, 3, 4],
    #   #  [9, 10, 11, 12]]
    #
    #   a.delete((0..-1).step(2),1)
    #   # => Numo::DFloat(view)#shape=[3,2]
    #   # [[2, 4],
    #   #  [6, 8],
    #   #  [10, 12]]
    #
    #   a.delete([1,3,5])
    #   # => Numo::DFloat(view)#shape=[9]
    #   # [1, 3, 5, 7, 8, 9, 10, 11, 12]

    def delete(indice, axis = nil)
      if axis
        bit = Bit.ones(shape[axis])
        bit[indice] = 0
        idx = [true] * ndim
        idx[axis] = bit.where
        self[*idx].copy
      else
        bit = Bit.ones(size)
        bit[indice] = 0
        self[bit.where].copy
      end
    end

    # Insert values along the axis before the indices.
    # @example
    #   a = Numo::DFloat[[1, 2], [3, 4]]
    #   a = Numo::Int32[[1, 1], [2, 2], [3, 3]]
    #
    #   a.insert(1,5)
    #   # => Numo::Int32#shape=[7]
    #   # [1, 5, 1, 2, 2, 3, 3]
    #
    #   a.insert(1, 5, axis:1)
    #   # => Numo::Int32#shape=[3,3]
    #   # [[1, 5, 1],
    #   #  [2, 5, 2],
    #   #  [3, 5, 3]]
    #
    #   a.insert([1], [[11],[12],[13]], axis:1)
    #   # => Numo::Int32#shape=[3,3]
    #   # [[1, 11, 1],
    #   #  [2, 12, 2],
    #   #  [3, 13, 3]]
    #
    #   a.insert(1, [11, 12, 13], axis:1)
    #   # => Numo::Int32#shape=[3,3]
    #   # [[1, 11, 1],
    #   #  [2, 12, 2],
    #   #  [3, 13, 3]]
    #
    #   a.insert([1], [11, 12, 13], axis:1)
    #   # => Numo::Int32#shape=[3,5]
    #   # [[1, 11, 12, 13, 1],
    #   #  [2, 11, 12, 13, 2],
    #   #  [3, 11, 12, 13, 3]]
    #
    #   b = a.flatten
    #   # => Numo::Int32(view)#shape=[6]
    #   # [1, 1, 2, 2, 3, 3]
    #
    #   b.insert(2,[15,16])
    #   # => Numo::Int32#shape=[8]
    #   # [1, 1, 15, 16, 2, 2, 3, 3]
    #
    #   b.insert([2,2],[15,16])
    #   # => Numo::Int32#shape=[8]
    #   # [1, 1, 15, 16, 2, 2, 3, 3]
    #
    #   b.insert([2,1],[15,16])
    #   # => Numo::Int32#shape=[8]
    #   # [1, 16, 1, 15, 2, 2, 3, 3]
    #
    #   b.insert([2,0,1],[15,16,17])
    #   # => Numo::Int32#shape=[9]
    #   # [16, 1, 17, 1, 15, 2, 2, 3, 3]
    #
    #   b.insert(2..3, [15, 16])
    #   # => Numo::Int32#shape=[8]
    #   # [1, 1, 15, 2, 16, 2, 3, 3]
    #
    #   b.insert(2, [7.13, 0.5])
    #   # => Numo::Int32#shape=[8]
    #   # [1, 1, 7, 0, 2, 2, 3, 3]
    #
    #   x = Numo::DFloat.new(2,4).seq
    #   # => Numo::DFloat#shape=[2,4]
    #   # [[0, 1, 2, 3],
    #   #  [4, 5, 6, 7]]
    #
    #   x.insert([1,3],999,axis:1)
    #   # => Numo::DFloat#shape=[2,6]
    #   # [[0, 999, 1, 2, 999, 3],
    #   #  [4, 999, 5, 6, 999, 7]]

    def insert(indice, values, axis: nil)
      if axis
        values = self.class.asarray(values)
        nd = values.ndim
        midx = ([:new] * (ndim - nd)) + ([true] * nd)
        case indice
        when Numeric
          midx[-nd - 1] = true
          midx[axis] = :new
        end
        values = values[*midx]
      else
        values = self.class.asarray(values).flatten
      end
      idx = Int64.asarray(indice)
      nidx = idx.size
      if nidx == 1
        nidx = values.shape[axis || 0]
        idx += Int64.new(nidx).seq
      else
        sidx = idx.sort_index
        idx[sidx] += Int64.new(nidx).seq
      end
      if axis
        bit = Bit.ones(shape[axis] + nidx)
        bit[idx] = 0
        new_shape = shape
        new_shape[axis] += nidx
        a = self.class.zeros(new_shape)
        mdidx = [true] * ndim
        mdidx[axis] = bit.where
        a[*mdidx] = self
        mdidx[axis] = idx
        a[*mdidx] = values
      else
        bit = Bit.ones(size + nidx)
        bit[idx] = 0
        a = self.class.zeros(size + nidx)
        a[bit.where] = flatten
        a[idx] = values
      end
      a
    end

    class << self
      # @example
      #   a = Numo::DFloat[[1, 2], [3, 4]]
      #   # => Numo::DFloat#shape=[2,2]
      #   # [[1, 2],
      #   #  [3, 4]]
      #
      #   b = Numo::DFloat[[5, 6]]
      #   # => Numo::DFloat#shape=[1,2]
      #   # [[5, 6]]
      #
      #   Numo::NArray.concatenate([a,b],axis:0)
      #   # => Numo::DFloat#shape=[3,2]
      #   # [[1, 2],
      #   #  [3, 4],
      #   #  [5, 6]]
      #
      #   Numo::NArray.concatenate([a,b.transpose], axis:1)
      #   # => Numo::DFloat#shape=[2,3]
      #   # [[1, 2, 5],
      #   #  [3, 4, 6]]

      def concatenate(arrays, axis: 0)
        klass = self == NArray ? NArray.array_type(arrays) : self
        nd = 0
        arrays = arrays.map do |a|
          case a
          when NArray
            # ok
          when Numeric
            a = klass[a]
          when Array
            a = klass.cast(a)
          else
            raise TypeError, "not Numo::NArray: #{a.inspect[0..48]}"
          end
          nd = a.ndim if a.ndim > nd
          a
        end
        axis += nd if axis < 0
        raise ArgumentError, 'axis is out of range' if axis < 0 || axis >= nd

        new_shape = nil
        sum_size = 0
        arrays.each do |a|
          a_shape = a.shape
          a_shape = ([1] * (nd - a_shape.size)) + a_shape if nd != a_shape.size # rubocop:disable Performance/CollectionLiteralInLoop
          sum_size += a_shape.delete_at(axis)
          if new_shape
            raise ShapeError, 'shape mismatch' if new_shape != a_shape
          else
            new_shape = a_shape
          end
        end
        new_shape.insert(axis, sum_size)
        result = klass.zeros(*new_shape)
        lst = 0
        refs = [true] * nd
        arrays.each do |a|
          fst = lst
          lst = fst + (a.shape[axis - nd] || 1)
          if lst > fst
            refs[axis] = fst...lst
            result[*refs] = a
          end
        end
        result
      end

      # Stack arrays vertically (row wise).
      # @example
      #   a = Numo::Int32[1,2,3]
      #   b = Numo::Int32[2,3,4]
      #   Numo::NArray.vstack([a,b])
      #   # => Numo::Int32#shape=[2,3]
      #   # [[1, 2, 3],
      #   #  [2, 3, 4]]
      #
      #   a = Numo::Int32[[1],[2],[3]]
      #   b = Numo::Int32[[2],[3],[4]]
      #   Numo::NArray.vstack([a,b])
      #   # => Numo::Int32#shape=[6,1]
      #   # [[1],
      #   #  [2],
      #   #  [3],
      #   #  [2],
      #   #  [3],
      #   #  [4]]

      def vstack(arrays)
        arys = arrays.map do |a|
          _atleast_2d(cast(a))
        end
        concatenate(arys, axis: 0)
      end

      # Stack arrays horizontally (column wise).
      # @example
      #   a = Numo::Int32[1,2,3]
      #   b = Numo::Int32[2,3,4]
      #   Numo::NArray.hstack([a,b])
      #   # => Numo::Int32#shape=[6]
      #   # [1, 2, 3, 2, 3, 4]
      #
      #   a = Numo::Int32[[1],[2],[3]]
      #   b = Numo::Int32[[2],[3],[4]]
      #   Numo::NArray.hstack([a,b])
      #   # => Numo::Int32#shape=[3,2]
      #   # [[1, 2],
      #   #  [2, 3],
      #   #  [3, 4]]

      def hstack(arrays)
        klass = self == NArray ? NArray.array_type(arrays) : self
        nd = 0
        arys = arrays.map do |a|
          a = klass.cast(a)
          nd = a.ndim if a.ndim > nd
          a
        end
        dim = nd >= 2 ? 1 : 0
        concatenate(arys, axis: dim)
      end

      # Stack arrays in depth wise (along third axis).
      # @example
      #   a = Numo::Int32[1,2,3]
      #   b = Numo::Int32[2,3,4]
      #   Numo::NArray.dstack([a,b])
      #   # => Numo::Int32#shape=[1,3,2]
      #   # [[[1, 2],
      #   #   [2, 3],
      #   #   [3, 4]]]
      #
      #   a = Numo::Int32[[1],[2],[3]]
      #   b = Numo::Int32[[2],[3],[4]]
      #   Numo::NArray.dstack([a,b])
      #   # => Numo::Int32#shape=[3,1,2]
      #   # [[[1, 2]],
      #   #  [[2, 3]],
      #   #  [[3, 4]]]

      def dstack(arrays)
        arys = arrays.map do |a|
          _atleast_3d(cast(a))
        end
        concatenate(arys, axis: 2)
      end

      # Stack 1-d arrays into columns of a 2-d array.
      # @example
      #   x = Numo::Int32[1,2,3]
      #   y = Numo::Int32[2,3,4]
      #   Numo::NArray.column_stack([x,y])
      #   # => Numo::Int32#shape=[3,2]
      #   # [[1, 2],
      #   #  [2, 3],
      #   #  [3, 4]]

      def column_stack(arrays)
        arys = arrays.map do |a|
          a = cast(a)
          case a.ndim
          when 0 then a[:new, :new]
          when 1 then a[true, :new]
          else; a
          end
        end
        concatenate(arys, axis: 1)
      end

      private

      # Return an narray with at least two dimension.
      def _atleast_2d(a)
        case a.ndim
        when 0 then a[:new, :new]
        when 1 then a[:new, true]
        else; a
        end
      end

      # Return an narray with at least three dimension.
      def _atleast_3d(a)
        case a.ndim
        when 0 then a[:new, :new, :new]
        when 1 then a[:new, true, :new]
        when 2 then a[true, true, :new]
        else; a
        end
      end
    end

    # @example
    #   a = Numo::DFloat[[1, 2], [3, 4]]
    #   # => Numo::DFloat#shape=[2,2]
    #   # [[1, 2],
    #   #  [3, 4]]
    #
    #   b = Numo::DFloat[[5, 6]]
    #   # => Numo::DFloat#shape=[1,2]
    #   # [[5, 6]]
    #
    #   a.concatenate(b,axis:0)
    #   # => Numo::DFloat#shape=[3,2]
    #   # [[1, 2],
    #   #  [3, 4],
    #   #  [5, 6]]
    #
    #   a.concatenate(b.transpose, axis:1)
    #   # => Numo::DFloat#shape=[2,3]
    #   # [[1, 2, 5],
    #   #  [3, 4, 6]]

    def concatenate(*arrays, axis: 0)
      axis = check_axis(axis)
      self_shape = shape
      self_shape.delete_at(axis)
      sum_size = shape[axis]
      arrays.map! do |a|
        case a
        when NArray
          # ok
        when Numeric
          a = self.class.new(1).store(a)
        when Array
          a = self.class.cast(a)
        else
          raise TypeError, "not Numo::NArray: #{a.inspect[0..48]}"
        end
        raise ShapeError, 'dimension mismatch' if a.ndim > ndim

        a_shape = a.shape
        sum_size += a_shape.delete_at(axis - ndim) || 1
        raise ShapeError, 'shape mismatch' if self_shape != a_shape

        a
      end
      self_shape.insert(axis, sum_size)
      result = self.class.zeros(*self_shape)
      lst = shape[axis]
      refs = [true] * ndim
      if lst > 0
        refs[axis] = 0...lst
        result[*refs] = self
      end
      arrays.each do |a|
        fst = lst
        lst = fst + (a.shape[axis - ndim] || 1)
        if lst > fst
          refs[axis] = fst...lst
          result[*refs] = a
        end
      end
      result
    end

    # @example
    #   x = Numo::DFloat.new(9).seq
    #   # => Numo::DFloat#shape=[9]
    #   # [0, 1, 2, 3, 4, 5, 6, 7, 8]
    #
    #   x.split(3)
    #   # => [Numo::DFloat(view)#shape=[3]
    #   # [0, 1, 2],
    #   #  Numo::DFloat(view)#shape=[3]
    #   # [3, 4, 5],
    #   #  Numo::DFloat(view)#shape=[3]
    #   # [6, 7, 8]]
    #
    #   x = Numo::DFloat.new(8).seq
    #   # => Numo::DFloat#shape=[8]
    #   # [0, 1, 2, 3, 4, 5, 6, 7]
    #
    #   x.split([3, 5, 6, 10])
    #   # => [Numo::DFloat(view)#shape=[3]
    #   # [0, 1, 2],
    #   #  Numo::DFloat(view)#shape=[2]
    #   # [3, 4],
    #   #  Numo::DFloat(view)#shape=[1]
    #   # [5],
    #   #  Numo::DFloat(view)#shape=[2]
    #   # [6, 7],
    #   #  Numo::DFloat(view)#shape=[0][]]

    def split(indices_or_sections, axis: 0)
      axis = check_axis(axis)
      size_axis = shape[axis]
      case indices_or_sections
      when Integer
        div_axis, mod_axis = size_axis.divmod(indices_or_sections)
        refs = [true] * ndim
        beg_idx = 0
        Array.new(mod_axis) do |_i|
          end_idx = beg_idx + div_axis + 1
          refs[axis] = beg_idx...end_idx
          beg_idx = end_idx
          self[*refs]
        end +
          Array.new(indices_or_sections - mod_axis) do |_i|
            end_idx = beg_idx + div_axis
            refs[axis] = beg_idx...end_idx
            beg_idx = end_idx
            self[*refs]
          end
      when NArray
        split(indices_or_sections.to_a, axis: axis)
      when Array
        refs = [true] * ndim
        fst = 0
        (indices_or_sections + [size_axis]).map do |lst|
          lst = size_axis if lst > size_axis
          refs[axis] = fst < size_axis ? fst...lst : -1...-1
          fst = lst
          self[*refs]
        end
      else
        raise TypeError, 'argument must be Integer or Array'
      end
    end

    # Split an array into multiple sub-arrays vertically
    def vsplit(indices_or_sections)
      split(indices_or_sections, axis: 0)
    end

    # Split an array into multiple sub-arrays horizontally
    # @example
    #   x = Numo::DFloat.new(4,4).seq
    #   # => Numo::DFloat#shape=[4,4]
    #   # [[0, 1, 2, 3],
    #   #  [4, 5, 6, 7],
    #   #  [8, 9, 10, 11],
    #   #  [12, 13, 14, 15]]
    #
    #   x.hsplit(2)
    #   # => [Numo::DFloat(view)#shape=[4,2]
    #   # [[0, 1],
    #   #  [4, 5],
    #   #  [8, 9],
    #   #  [12, 13]],
    #   #  Numo::DFloat(view)#shape=[4,2]
    #   # [[2, 3],
    #   #  [6, 7],
    #   #  [10, 11],
    #   #  [14, 15]]]
    #
    #   x.hsplit([3, 6])
    #   # => [Numo::DFloat(view)#shape=[4,3]
    #   # [[0, 1, 2],
    #   #  [4, 5, 6],
    #   #  [8, 9, 10],
    #   #  [12, 13, 14]],
    #   #  Numo::DFloat(view)#shape=[4,1]
    #   # [[3],
    #   #  [7],
    #   #  [11],
    #   #  [15]],
    #   #  Numo::DFloat(view)#shape=[4,0][]]
    def hsplit(indices_or_sections)
      split(indices_or_sections, axis: 1)
    end

    # Split an array into multiple sub-arrays along the depth
    def dsplit(indices_or_sections)
      split(indices_or_sections, axis: 2)
    end

    # @example
    #   a = Numo::NArray[0,1,2]
    #   # => Numo::Int32#shape=[3]
    #   # [0, 1, 2]
    #
    #   a.tile(2)
    #   # => Numo::Int32#shape=[6]
    #   # [0, 1, 2, 0, 1, 2]
    #
    #   a.tile(2,2)
    #   # => Numo::Int32#shape=[2,6]
    #   # [[0, 1, 2, 0, 1, 2],
    #   #  [0, 1, 2, 0, 1, 2]]
    #
    #   a.tile(2,1,2)
    #   # => Numo::Int32#shape=[2,1,6]
    #   # [[[0, 1, 2, 0, 1, 2]],
    #   #  [[0, 1, 2, 0, 1, 2]]]
    #
    #   b = Numo::NArray[[1, 2], [3, 4]]
    #   # => Numo::Int32#shape=[2,2]
    #   # [[1, 2],
    #   #  [3, 4]]
    #
    #   b.tile(2)
    #   # => Numo::Int32#shape=[2,4]
    #   # [[1, 2, 1, 2],
    #   #  [3, 4, 3, 4]]
    #
    #   b.tile(2,1)
    #   # => Numo::Int32#shape=[4,2]
    #   # [[1, 2],
    #   #  [3, 4],
    #   #  [1, 2],
    #   #  [3, 4]]
    #
    #   c = Numo::NArray[1,2,3,4]
    #   # => Numo::Int32#shape=[4]
    #   # [1, 2, 3, 4]
    #
    #   c.tile(4,1)
    #   # => Numo::Int32#shape=[4,4]
    #   # [[1, 2, 3, 4],
    #   #  [1, 2, 3, 4],
    #   #  [1, 2, 3, 4],
    #   #  [1, 2, 3, 4]]

    def tile(*arg)
      arg.each do |i|
        raise ArgumentError, 'argument should be positive integer' if !i.is_a?(Integer) || i < 1
      end
      ns = arg.size
      nd = ndim
      shp = shape
      new_shp = []
      src_shp = []
      res_shp = []
      (nd - ns).times do
        new_shp << 1
        new_shp << (n = shp.shift)
        src_shp << :new
        src_shp << true
        res_shp << n
      end
      (ns - nd).times do
        new_shp << (m = arg.shift)
        new_shp << 1
        src_shp << :new
        src_shp << :new
        res_shp << m
      end
      [nd, ns].min.times do
        new_shp << (m = arg.shift)
        new_shp << (n = shp.shift)
        src_shp << :new
        src_shp << true
        res_shp << (n * m)
      end
      self.class.new(*new_shp).store(self[*src_shp]).reshape(*res_shp)
    end

    # @example
    #   Numo::NArray[3].repeat(4)
    #   # => Numo::Int32#shape=[4]
    #   # [3, 3, 3, 3]
    #
    #   x = Numo::NArray[[1,2],[3,4]]
    #   # => Numo::Int32#shape=[2,2]
    #   # [[1, 2],
    #   #  [3, 4]]
    #
    #   x.repeat(2)
    #   # => Numo::Int32#shape=[8]
    #   # [1, 1, 2, 2, 3, 3, 4, 4]
    #
    #   x.repeat(3,axis:1)
    #   # => Numo::Int32#shape=[2,6]
    #   # [[1, 1, 1, 2, 2, 2],
    #   #  [3, 3, 3, 4, 4, 4]]
    #
    #   x.repeat([1,2],axis:0)
    #   # => Numo::Int32#shape=[3,2]
    #   # [[1, 2],
    #   #  [3, 4],
    #   #  [3, 4]]

    def repeat(arg, axis: nil)
      case axis
      when Integer
        axis = check_axis(axis)
        c = self
      when NilClass
        c = flatten
        axis = 0
      else
        raise ArgumentError, 'invalid axis'
      end
      case arg
      when Integer
        raise ArgumentError, 'argument should be positive integer' if !arg.is_a?(Integer) || arg < 1

        idx = Array.new(c.shape[axis]) { |i| [i] * arg }.flatten
      else
        arg = arg.to_a
        raise ArgumentError, 'repeat size shoud be equal to size along axis' if arg.size != c.shape[axis]

        arg.each do |i|
          raise ArgumentError, 'argument should be non-negative integer' if !i.is_a?(Integer) || i < 0
        end
        idx = arg.each_with_index.map { |a, i| [i] * a }.flatten
      end
      ref = [true] * c.ndim
      ref[axis] = idx
      c[*ref].copy
    end

    # Calculate the n-th discrete difference along given axis.
    # @example
    #   x = Numo::DFloat[1, 2, 4, 7, 0]
    #   # => Numo::DFloat#shape=[5]
    #   # [1, 2, 4, 7, 0]
    #
    #   x.diff
    #   # => Numo::DFloat#shape=[4]
    #   # [1, 2, 3, -7]
    #
    #   x.diff(2)
    #   # => Numo::DFloat#shape=[3]
    #   # [1, 1, -10]
    #
    #   x = Numo::DFloat[[1, 3, 6, 10], [0, 5, 6, 8]]
    #   # => Numo::DFloat#shape=[2,4]
    #   # [[1, 3, 6, 10],
    #   #  [0, 5, 6, 8]]
    #
    #   x.diff
    #   # => Numo::DFloat#shape=[2,3]
    #   # [[2, 3, 4],
    #   #  [5, 1, 2]]
    #
    #   x.diff(axis:0)
    #   # => Numo::DFloat#shape=[1,4]
    #   # [[-1, 2, 0, -2]]

    def diff(n = 1, axis: -1)
      axis = check_axis(axis)
      raise ShapeError, "n=#{n} is invalid for shape[#{axis}]=#{shape[axis]}" if n < 0 || n >= shape[axis]

      # calculate polynomial coefficient
      c = self.class[-1, 1]
      2.upto(n) do |i|
        x = self.class.zeros(i + 1)
        x[0..-2] = c
        y = self.class.zeros(i + 1)
        y[1..-1] = c
        c = y - x
      end
      s = [true] * ndim
      s[axis] = n..-1
      result = self[*s].dup
      sum = result.inplace
      (n - 1).downto(0) do |i|
        s = [true] * ndim
        s[axis] = i..(-n - 1 + i)
        sum + (self[*s] * c[i]) # inplace addition
      end
      result
    end

    # Upper triangular matrix.
    # Return a copy with the elements below the k-th diagonal filled with zero.
    def triu(k = 0)
      dup.triu!(k)
    end

    # Upper triangular matrix.
    # Fill the self elements below the k-th diagonal with zero.
    def triu!(k = 0)
      raise NArray::ShapeError, 'must be >= 2-dimensional array' if ndim < 2

      if contiguous?
        *shp, m, n = shape
        idx = tril_indices(k - 1)
        reshape!(*shp, m * n)
        self[false, idx] = 0
        reshape!(*shp, m, n)
      else
        store(triu(k))
      end
    end

    # Return the indices for the upper-triangle on and above the k-th diagonal.
    def triu_indices(k = 0)
      raise NArray::ShapeError, 'must be >= 2-dimensional array' if ndim < 2

      m, n = shape[-2..]
      NArray.triu_indices(m, n, k)
    end

    # Return the indices for the upper-triangle on and above the k-th diagonal.
    def self.triu_indices(m, n, k = 0)
      x = Numo::Int64.new(m, 1).seq + k
      y = Numo::Int64.new(1, n).seq
      (x <= y).where
    end

    # Lower triangular matrix.
    # Return a copy with the elements above the k-th diagonal filled with zero.
    def tril(k = 0)
      dup.tril!(k)
    end

    # Lower triangular matrix.
    # Fill the self elements above the k-th diagonal with zero.
    def tril!(k = 0)
      raise NArray::ShapeError, 'must be >= 2-dimensional array' if ndim < 2

      if contiguous?
        idx = triu_indices(k + 1)
        *shp, m, n = shape
        reshape!(*shp, m * n)
        self[false, idx] = 0
        reshape!(*shp, m, n)
      else
        store(tril(k))
      end
    end

    # Return the indices for the lower-triangle on and below the k-th diagonal.
    def tril_indices(k = 0)
      raise NArray::ShapeError, 'must be >= 2-dimensional array' if ndim < 2

      m, n = shape[-2..]
      NArray.tril_indices(m, n, k)
    end

    # Return the indices for the lower-triangle on and below the k-th diagonal.
    def self.tril_indices(m, n, k = 0)
      x = Numo::Int64.new(m, 1).seq + k
      y = Numo::Int64.new(1, n).seq
      (x >= y).where
    end

    # Return the k-th diagonal indices.
    def diag_indices(k = 0)
      raise NArray::ShapeError, 'must be >= 2-dimensional array' if ndim < 2

      m, n = shape[-2..]
      NArray.diag_indices(m, n, k)
    end

    # Return the k-th diagonal indices.
    def self.diag_indices(m, n, k = 0)
      x = Numo::Int64.new(m, 1).seq + k
      y = Numo::Int64.new(1, n).seq
      (x.eq y).where
    end

    # Return a matrix whose diagonal is constructed by self along the last axis.
    def diag(k = 0)
      *shp, n = shape
      n += k.abs
      a = self.class.zeros(*shp, n, n)
      a.diagonal(k).store(self)
      a
    end

    # Returns an index array of sort result.
    #
    # @example
    #   require 'numo/narray'
    #
    #   a = Numo::DFloat[[0.1, 0.7],
    #                    [0.4, 0.2],
    #                    [0.2, 0.5]]
    #   pp a.argsort
    #   # =>
    #   # Numo::Int32#shape=[3,2]
    #   # [[0, 1],
    #   #  [1, 0],
    #   #  [0, 1]]
    #   pp a.argsort(axis: 0)
    #   # =>
    #   # Numo::Int32#shape=[3,2]
    #   # [[0, 1],
    #   #  [2, 2],
    #   #  [1, 0]]
    #   pp a.argsort(axis: 1)
    #   # =>
    #   # Numo::Int32#shape=[3,2]
    #   # [[0, 1],
    #   #  [1, 0],
    #   #  [0, 1]]
    #   pp a.argsort(axis: nil)
    #   # =>
    #   # Numo::Int32#shape=[6]
    #   # [0, 3, 4, 2, 5, 1]
    #
    # @overload argsort(axis: -1)
    #   @param axis [Integer, nil] Axis along which to sort. Default is -1 (the last axis).
    #     If `nil` is given, the array is flattened before sorting.
    #   @return [Numo::Int32] An array of indices that would sort the array.
    def argsort(axis_ = 'none', axis: -1)
      raise NotImplementedError, "argsort is not implemented for #{self.class}" unless respond_to?(:sort_index)

      axis = axis_ unless axis_ == 'none'

      return flatten.sort_index if axis.nil?

      axis = ndim + axis if axis.negative?
      raise Numo::NArray::DimensionError, 'dimension is out of range' if axis.negative? || axis >= ndim

      case ndim
      when 1
        sort_index
      when 2
        case axis
        when 0
          indices = transpose.sort_index(1)
          indices.transpose - indices.min(1)
        when 1
          indices = sort_index(1)
          indices - indices.min(1).expand_dims(1)
        end
      else
        res = Numo::Int32.zeros(*shape)
        slicer = Array.new(ndim)
        slicer[axis] = true
        other_axes = Array.new(ndim) { |i| i } - [axis]
        axis_ids = other_axes.map do |d|
          Array.new(shape[d]) { |i| i }
        end
        axis_ids.inject(:product).each do |indices|
          indices = indices.flatten
          other_axes.each_with_index do |d, i|
            slicer[d] = indices[i]
          end
          sorted_indices = self[*slicer].sort_index
          res[*slicer] = sorted_indices - sorted_indices.min
        end
        res
      end
    end

    # Return the sum along diagonals of the array.
    #
    # If 2-D array, computes the summation along its diagonal with the
    # given offset, i.e., sum of `a[i,i+offset]`.
    # If more than 2-D array, the diagonal is determined from the axes
    # specified by axis argument. The default is axis=[-2,-1].
    # @param offset [Integer] (optional, default=0) diagonal offset
    # @param axis [Array] (optional, default=[-2,-1]) diagonal axis
    # @param nan [Bool] (optional, default=false) nan-aware algorithm, i.e., if true then it ignores nan.

    def trace(offset = nil, axis = nil, nan: false)
      diagonal(offset, axis).sum(nan: nan, axis: -1)
    end

    @@warn_slow_dot = false

    # Dot product of two arrays.
    # @param b [Numo::NArray]
    # @return [Numo::NArray]  return dot product

    def dot(b)
      t = self.class::UPCAST[b.class]
      if defined?(Linalg) && [SFloat, DFloat, SComplex, DComplex].include?(t)
        Linalg.dot(self, b)
      else
        b = self.class.asarray(b)
        case b.ndim
        when 1
          mulsum(b, axis: -1)
        else
          case ndim
          when 0
            b.mulsum(self, axis: -2)
          when 1
            self[true, :new].mulsum(b, axis: -2)
          else
            unless @@warn_slow_dot
              nx = 200
              ns = 200_000
              am, an = shape[-2..]
              bm, bn = b.shape[-2..]
              if am > nx && an > nx && bm > nx && bn > nx &&
                 size > ns && b.size > ns
                @@warn_slow_dot = true
                warn "\nwarning: Built-in matrix dot is slow. Consider installing numo-linalg-alt gem.\n\n"
              end
            end
            self[false, :new].mulsum(b[false, :new, true, true], axis: -2)
          end
        end
      end
    end

    # Inner product of two arrays.
    # Same as `(a*b).sum(axis:-1)`.
    # @param b [Numo::NArray]
    # @param axis [Integer] applied axis
    # @return [Numo::NArray]  return (a*b).sum(axis:axis)

    def inner(b, axis: -1)
      mulsum(b, axis: axis)
    end

    # Outer product of two arrays.
    # Same as `self[false,:new] * b[false,:new,true]`.
    #
    # @param b [Numo::NArray]
    # @param axis [Integer] applied axis (default=-1)
    # @return [Numo::NArray]  return outer product
    # @example
    #   a = Numo::DFloat.ones(5)
    #   # => Numo::DFloat#shape=[5]
    #   # [1, 1, 1, 1, 1]
    #
    #   b = Numo::DFloat.linspace(-2,2,5)
    #   # => Numo::DFloat#shape=[5]
    #   # [-2, -1, 0, 1, 2]
    #
    #   a.outer(b)
    #   # => Numo::DFloat#shape=[5,5]
    #   # [[-2, -1, 0, 1, 2],
    #   #  [-2, -1, 0, 1, 2],
    #   #  [-2, -1, 0, 1, 2],
    #   #  [-2, -1, 0, 1, 2],
    #   #  [-2, -1, 0, 1, 2]]

    def outer(b, axis: nil)
      b = NArray.cast(b)
      if axis.nil?
        self[false, :new] * (b.ndim == 0 ? b : b[false, :new, true])
      else
        md, nd = [ndim, b.ndim].minmax
        axis = check_axis(axis) - nd
        raise ArgumentError, "axis=#{axis} is out of range" if axis < -md

        adim = [true] * ndim
        adim[axis + ndim + 1, 0] = :new
        bdim = [true] * b.ndim
        bdim[axis + b.ndim, 0] = :new
        self[*adim] * b[*bdim]
      end
    end

    # Percentile
    #
    # @param q [Numo::NArray]
    # @param axis [Integer] applied axis
    # @return [Numo::NArray]  return percentile
    def percentile(q, axis: nil)
      raise ArgumentError, 'q is out of range' if q < 0 || q > 100

      x = self
      unless axis
        axis = 0
        x = x.flatten
      end

      sorted = x.sort(axis: axis)
      x = q / 100.0 * (sorted.shape[axis] - 1)
      r = x % 1
      i = x.floor
      refs = [true] * sorted.ndim
      refs[axis] = i
      if i == sorted.shape[axis] - 1
        sorted[*refs]
      else
        refs_upper = refs.dup
        refs_upper[axis] = i + 1
        sorted[*refs] + (r * (sorted[*refs_upper] - sorted[*refs]))
      end
    end

    # Kronecker product of two arrays.
    #
    #     kron(a,b)[k_0, k_1, ...] = a[i_0, i_1, ...] * b[j_0, j_1, ...]
    #        where:  k_n = i_n * b.shape[n] + j_n
    #
    # @param b [Numo::NArray]
    # @return [Numo::NArray]  return Kronecker product
    # @example
    #   Numo::DFloat[1,10,100].kron([5,6,7])
    #   # => Numo::DFloat#shape=[9]
    #   # [5, 6, 7, 50, 60, 70, 500, 600, 700]
    #
    #   Numo::DFloat[5,6,7].kron([1,10,100])
    #   # => Numo::DFloat#shape=[9]
    #   # [5, 50, 500, 6, 60, 600, 7, 70, 700]
    #
    #   Numo::DFloat.eye(2).kron(Numo::DFloat.ones(2,2))
    #   # => Numo::DFloat#shape=[4,4]
    #   # [[1, 1, 0, 0],
    #   #  [1, 1, 0, 0],
    #   #  [0, 0, 1, 1],
    #   #  [0, 0, 1, 1]]

    def kron(b)
      b = NArray.cast(b)
      nda = ndim
      ndb = b.ndim
      shpa = shape
      shpb = b.shape
      adim = ([:new] * (2 * [ndb - nda, 0].max)) + ([true, :new] * nda)
      bdim = ([:new] * (2 * [nda - ndb, 0].max)) + ([:new, true] * ndb)
      shpr = (-[nda, ndb].max..-1).map { |i| (shpa[i] || 1) * (shpb[i] || 1) }
      (self[*adim] * b[*bdim]).reshape(*shpr)
    end

    # Compute a covariance matrix.
    #
    # @param y [Numo::NArray] (optional) If not nil, the covariance matrix of `self` and `y` is computed.
    # @param ddof [Integer] (optional) Delta degrees of freedom. The divisor used in calculations is `N - ddof`,
    #   where `N` represents the number of observations.
    # @param fweights [Numo::NArray] (optional) 1-D array of integer frequency weights.
    # @param aweights [Numo::NArray] (optional) 1-D array of observation vector weights.
    # @return [Numo::NArray]  return covariance matrix
    #
    # @example
    #   x = Numo::DFloat[4, 5, 6]
    #   x.cov
    #   # => 1.0
    #
    #   x = Numo::DFloat[[4, 5, 6], [3, 2, 1]]
    #   x.cov
    #   # => Numo::DFloat#shape=[2,2]
    #   # [[1, -1],
    #   #  [-1, 1]]
    #
    #   y = Numo::DFloat[7, 9, 8]
    #   x.cov(y)
    #   # => Numo::DFloat#shape=[3,3]
    #   # [[1, -1, 0.5],
    #   #  [-1, 1, -0.5],
    #   #  [0.5, -0.5, 1]]
    def cov(y = nil, ddof: 1, fweights: nil, aweights: nil) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      raise Numo::NArray::ShapeError, 'ndim must be <= 2' if ndim > 2
      raise Numo::NArray::ShapeError, 'y.ndim must be <= 2' if !y.nil? && (y.ndim > 2)
      raise ArgumentError, 'ddof must be 0 or 1' unless [0, 1].include?(ddof)

      m = if y
            NArray.vstack([self, y])
          else
            self
          end
      w = nil
      if fweights
        fweights = Numo::NArray.cast(fweights) unless fweights.is_a?(Numo::NArray)
        raise ArgumentError, 'fweights must be 1-D array' unless fweights.ndim == 1
        raise ArgumentError, 'fweights size is wrong' unless fweights.size == m.shape[1]
        raise ArgumentError, 'fweights must be non-negative' if (fweights < 0).any?
        raise ArgumentError, 'fweights must be integer' unless fweights == fweights.floor

        w = fweights
      end
      if aweights
        aweights = Numo::NArray.cast(aweights) unless aweights.is_a?(Numo::NArray)
        raise ArgumentError, 'aweights must be 1-D array' unless aweights.ndim == 1
        raise ArgumentError, 'aweights size is wrong' unless aweights.size == m.shape[1]
        raise ArgumentError, 'aweights must be non-negative' if (aweights < 0).any?

        if w.nil?
          w = aweights
        else
          w *= aweights
        end
      end
      fact = if w.nil?
               m.shape[-1] - ddof
             elsif ddof == 0
               w.sum
             elsif aweights.nil?
               w.sum - ddof
             else
               w_sum = w.sum
               w_sum - (ddof * (w * aweights).sum / w_sum)
             end
      if fact <= 0
        warn('Degrees of freedom <= 0 for slice')
        fact = 0.0
      end
      if w.nil?
        m -= m.mean(axis: -1, keepdims: true)
        mw = m
      else
        m -= (m * w).sum(axis: -1, keepdims: true) / w.sum
        mw = m * w
      end
      m.dot(mw.transpose.conj) / fact
    end

    private

    # @!visibility private
    def check_axis(axis)
      raise ArgumentError, "axis=#{axis} must be Integer" unless axis.is_a?(Integer)

      a = axis
      a += ndim if a < 0
      raise ArgumentError, "axis=#{axis} is invalid" if a < 0 || a >= ndim

      a
    end
  end
end
