require 'rails_helper'

describe Kraken do
  subject{Kraken.instance}

  describe 'current_price' do
    it 'responds correctly' do
      res = subject.current_price
      expect(res).to be_a Float
    end
  end

  describe 'balance' do
    it 'responds correctly' do
      res = subject.balance
      expect(res).to be_a Hash
    end
  end

  describe 'balance_eur' do
    it 'responds correctly' do
      res = subject.balance_eur
      expect(res).to be_a Numeric
    end
  end

  describe 'balance_btc' do
    it 'responds correctly' do
      res = subject.balance_btc
      expect(res).to be_a Numeric
    end
  end

  describe 'place a market order' do
    it 'places an order' do
      res = subject.place_market_order(direction: :buy, btc_amount: 0.0005)
      expect(res).to be_a Hash
      p res[0]
    end

    it 'places an order' do
      res = subject.place_market_order(direction: :sell, btc_amount: 0.0005)
      expect(res).to be_a Hash
      p res
    end

  end

end
