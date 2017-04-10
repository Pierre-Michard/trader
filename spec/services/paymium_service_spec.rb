require 'rails_helper'

describe PaymiumService do
  subject{PaymiumService.instance}

  describe '#current_price' do
    it 'responds correctly' do
      res = subject.user
      expect(res).to be_a Hash
    end
  end

  describe '#broadcast_channel_id' do
    it 'does not throw exceptions' do
      res = subject.broadcast_channel_id
      expect(res).to be_truthy
    end
  end

  describe '#current_orders' do
    it 'retrieves a list of orders' do
      res = subject.current_orders
      expect(res).to be_an Array
    end
  end

  describe '#current_sell_orders' do
    it 'retrieves a list of orders' do
      res = subject.current_sell_orders
      p res
      expect(res).to be_an Array
    end
  end

  describe '#trades' do
    it 'retrieves a list of trades' do
      res = subject.trades
      p res
      expect(res).to be_an Array
    end
  end

  describe '#place_order && #cancel_order' do
    it 'place and cancels an order' do
      order = subject.place_order(direction: :sell, amount: 0.001, price: 1200)
      expect(order).to be_a Hash
      expect(order).to have_key ('uuid')
      subject.cancel_order(order)
    end
  end

  describe '#balance_btc' do
    it 'retrieves balance' do
      res = subject.balance_btc
      expect(res).to be_a Numeric
    end
  end

  describe '#balance_eur' do
    it 'retrieves balance' do
      res = subject.balance_eur
      expect(res).to be_a Numeric
    end
  end

  describe '#latest_sell_trades' do
    it 'retrieves a list of trades' do
      res = subject.latest_sell_trades
      expect(res).to be_an Array
      p res
    end
  end
end
