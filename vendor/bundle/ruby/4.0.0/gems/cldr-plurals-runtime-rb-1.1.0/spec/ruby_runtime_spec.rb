# encoding: UTF-8

require 'yaml'
require 'spec_helper'

describe CldrPlurals::RubyRuntime do
  let(:rt) { CldrPlurals::RubyRuntime }

  context 'with an integer' do
    let(:num) { '1' }

    it '#n returns n without trailing zeroes' do
      expect(rt.n(num)).to eq(1)
    end

    it '#i returns the int value' do
      expect(rt.i(num)).to eq(1)
    end

    it '#v returns num of visible fraction digits (with zeroes)' do
      expect(rt.v(num)).to eq(0)
    end

    it '#w returns num of visible fraction digits (without zeroes)' do
      expect(rt.w(num)).to eq(0)
    end

    it '#f returns visible fractional digits (with zeroes)' do
      expect(rt.f(num)).to eq(0)
    end

    it '#t returns visible fractional digits (without zeroes)' do
      expect(rt.t(num)).to eq(0)
    end
  end

  context 'with an exponent' do
    let(:num) { '1.203e1' }

    it '#n returns n without trailing zeroes' do
      expect(rt.n(num)).to eq(12.03)
    end

    it '#i returns the int value multiplied by the power' do
      expect(rt.i(num)).to eq(12)
    end

    it '#v returns num of visible fraction digits (with zeroes)' do
      expect(rt.v(num)).to eq(2)
    end

    it '#w returns num of visible fraction digits (without zeroes)' do
      expect(rt.w(num)).to eq(1)
    end

    it '#f returns visible fractional digits (with zeroes)' do
      expect(rt.f(num)).to eq(3)
    end

    it '#t returns visible fractional digits (without zeroes)' do
      expect(rt.t(num)).to eq(3)
    end
  end

  context 'with a zero decimal' do
    let(:num) { '1.0' }

    it '#n returns n without trailing zeroes' do
      expect(rt.n(num)).to eq(1)
    end

    it '#i returns the int value' do
      expect(rt.i(num)).to eq(1)
    end

    it '#v returns num of visible fraction digits (with zeroes)' do
      expect(rt.v(num)).to eq(1)
    end

    it '#w returns num of visible fraction digits (without zeroes)' do
      expect(rt.w(num)).to eq(0)
    end

    it '#f returns visible fractional digits (with zeroes)' do
      expect(rt.f(num)).to eq(0)
    end

    it '#t returns visible fractional digits (without zeroes)' do
      expect(rt.t(num)).to eq(0)
    end
  end

  context 'with a double-precision zero decimal' do
    let(:num) { '1.00' }

    it '#n returns n without trailing zeroes' do
      expect(rt.n(num)).to eq(1)
    end

    it '#i returns the int value' do
      expect(rt.i(num)).to eq(1)
    end

    it '#v returns num of visible fraction digits (with zeroes)' do
      expect(rt.v(num)).to eq(2)
    end

    it '#w returns num of visible fraction digits (without zeroes)' do
      expect(rt.w(num)).to eq(0)
    end

    it '#f returns visible fractional digits (with zeroes)' do
      expect(rt.f(num)).to eq(0)
    end

    it '#t returns visible fractional digits (without zeroes)' do
      expect(rt.t(num)).to eq(0)
    end
  end

  context 'with a non-zero decimal' do
    let(:num) { '1.3' }

    it '#n returns n without trailing zeroes' do
      expect(rt.n(num)).to eq(1.3)
    end

    it '#i returns the int value' do
      expect(rt.i(num)).to eq(1)
    end

    it '#v returns num of visible fraction digits (with zeroes)' do
      expect(rt.v(num)).to eq(1)
    end

    it '#w returns num of visible fraction digits (without zeroes)' do
      expect(rt.w(num)).to eq(1)
    end

    it '#f returns visible fractional digits (with zeroes)' do
      expect(rt.f(num)).to eq(3)
    end

    it '#t returns visible fractional digits (without zeroes)' do
      expect(rt.t(num)).to eq(3)
    end
  end

  context 'with a double-precision trailing zero decimal' do
    let(:num) { '1.30' }

    it '#n returns n without trailing zeroes' do
      expect(rt.n(num)).to eq(1.3)
    end

    it '#i returns the int value' do
      expect(rt.i(num)).to eq(1)
    end

    it '#v returns num of visible fraction digits (with zeroes)' do
      expect(rt.v(num)).to eq(2)
    end

    it '#w returns num of visible fraction digits (without zeroes)' do
      expect(rt.w(num)).to eq(1)
    end

    it '#f returns visible fractional digits (with zeroes)' do
      expect(rt.f(num)).to eq(30)
    end

    it '#t returns visible fractional digits (without zeroes)' do
      expect(rt.t(num)).to eq(3)
    end
  end

  context 'with a double-precision leading zero decimal' do
    let(:num) { '1.03' }

    it '#n returns n without trailing zeroes' do
      expect(rt.n(num)).to eq(1.03)
    end

    it '#i returns the int value' do
      expect(rt.i(num)).to eq(1)
    end

    it '#v returns num of visible fraction digits (with zeroes)' do
      expect(rt.v(num)).to eq(2)
    end

    it '#w returns num of visible fraction digits (without zeroes)' do
      expect(rt.w(num)).to eq(1)
    end

    it '#f returns visible fractional digits (with zeroes)' do
      expect(rt.f(num)).to eq(3)
    end

    it '#t returns visible fractional digits (without zeroes)' do
      expect(rt.t(num)).to eq(3)
    end
  end

  context 'with a triple-precision decimal' do
    let(:num) { '1.230' }

    it '#n returns n without trailing zeroes' do
      expect(rt.n(num)).to eq(1.23)
    end

    it '#i returns the int value' do
      expect(rt.i(num)).to eq(1)
    end

    it '#v returns num of visible fraction digits (with zeroes)' do
      expect(rt.v(num)).to eq(3)
    end

    it '#w returns num of visible fraction digits (without zeroes)' do
      expect(rt.w(num)).to eq(2)
    end

    it '#f returns visible fractional digits (with zeroes)' do
      expect(rt.f(num)).to eq(230)
    end

    it '#t returns visible fractional digits (without zeroes)' do
      expect(rt.t(num)).to eq(23)
    end
  end
end
