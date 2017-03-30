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

  describe '#trades' do
    it 'retrieves a list of trades' do
      res = subject.trades
      p res
      expect(res).to be_an Array
    end
  end

end
