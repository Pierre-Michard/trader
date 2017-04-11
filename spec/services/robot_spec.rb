require 'rails_helper'

describe Robot do
  subject{Robot.new}

  describe 'sell_amount' do
    it 'responds successfully' do
      expect(subject.sell_amount).to be_a Numeric
      expect(subject.sell_amount).to be > 0
    end
  end

  describe 'buy_amount' do
    it 'responds successfully' do
      expect(subject.buy_amount).to be_a Numeric
      expect(subject.buy_amount).to be > 0
    end
  end

  describe 'monitor_sell_price' do
    it 'responds successfully' do
      expect{subject.monitor_sell_price}.not_to raise_exception
    end
  end

  describe 'monitor_buy_price' do
    it 'responds successfully' do
      expect{subject.monitor_buy_price}.not_to raise_exception
    end
  end
end