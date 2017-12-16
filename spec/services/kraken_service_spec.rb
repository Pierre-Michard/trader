require 'rails_helper'

RSpec.describe KrakenService do
  subject{KrakenService.instance}

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

  describe 'update_cached_balance' do
    before do
      balance = {:ZEUR => "100.10", :XXBT => "0.01"}.with_indifferent_access
      Rails.cache.write(:kraken_balance, balance)
    end
    it 'updates cached balance' do
      expect(subject.balance_eur).to eq(BigDecimal.new('100.1'))
    end
  end

  describe 'balance_btc' do
    it 'responds correctly' do
      res = subject.balance_btc
      expect(res).to be_a Numeric
    end
  end

  describe 'place an order' do
    it 'places limit orders' do
      res = subject.place_order(type: :limit, direction: :buy, btc_amount: 0.002, price: 200)
      p res
      expect(res).to be_a String
    end

    it 'places market orders' do
      res = subject.place_order(direction: :buy, btc_amount: 0.0005)
      expect(res).to be_a String
    end

    it 'updates balance when buying' do
      Rails.cache.clear
      expect{
        subject.place_order(type: :limit, direction: :buy, btc_amount: 0.002, price: 200)
      }.to change{subject.balance_eur}.by(-0.4)
    end

    it 'updates balance when selling' do
      Rails.cache.clear
      expect{
        subject.place_order(type: :limit, direction: :sell, btc_amount: 0.002, price: 20000)
      }.to change{subject.balance_btc}.by(-0.002)
    end

    it 'updates cached open_orders' do
      Rails.cache.clear
      expect{
        subject.place_order(type: :limit, direction: :buy, btc_amount: 0.005, price: 200)
      }.to change{subject.open_orders.count}.by(1)
      subject.open_orders.each{|key, value| p key, value}
    end


    it 'places an order' do
      res = subject.place_order(type: :limit, direction: :sell, btc_amount: 0.0005, price: 100_000)
      expect(res).to be_a String
    end

  end

  describe 'retrieve an order' do
    it 'retrieves an order' do
      res = subject.order('O4X5EA-UZ7VM-5DBKUG')
      expect(res).to be_a Hash
      p res
    end
  end

  describe 'retrieve orders' do
    it 'retrievs orders' do
      res = subject.orders(['O4X5EA-UZ7VM-5DBKUG'])
      expect(res).to be_a Hash
      expect(res).to have_key 'O4X5EA-UZ7VM-5DBKUG'
      p res
    end
  end

  describe 'open_orders' do
    it 'updates balance' do
      expect(subject.open_orders).to be_a Hash
      p subject.open_orders
    end
  end

  describe 'recent_orders' do
    it 'retrieves recent order' do
      p subject.recent_orders
    end

  end
end
