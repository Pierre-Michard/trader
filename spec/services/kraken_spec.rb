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

end
