# frozen_string_literal: true

module RQRCodeCore
  class QRPolynomial
    def initialize(num, shift)
      raise QRCodeRunTimeError, "#{num.size}/#{shift}" if num.empty?
      offset = 0

      while offset < num.size && num[offset] == 0
        offset += 1
      end

      @num = Array.new(num.size - offset + shift)

      (0...num.size - offset).each do |i|
        @num[i] = num[i + offset]
      end
    end

    def get(index)
      @num[index]
    end

    def get_length
      @num.size
    end

    def multiply(e)
      num = Array.new(get_length + e.get_length - 1)

      (0...get_length).each do |i|
        (0...e.get_length).each do |j|
          tmp = num[i + j].nil? ? 0 : num[i + j]
          num[i + j] = tmp ^ QRMath.gexp(QRMath.glog(get(i)) + QRMath.glog(e.get(j)))
        end
      end

      QRPolynomial.new(num, 0)
    end

    def mod(e)
      if get_length - e.get_length < 0
        return self
      end

      ratio = QRMath.glog(get(0)) - QRMath.glog(e.get(0))
      num = Array.new(get_length)

      (0...get_length).each do |i|
        num[i] = get(i)
      end

      (0...e.get_length).each do |i|
        tmp = num[i].nil? ? 0 : num[i]
        num[i] = tmp ^ QRMath.gexp(QRMath.glog(e.get(i)) + ratio)
      end

      QRPolynomial.new(num, 0).mod(e)
    end
  end
end
