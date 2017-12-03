require 'rails_helper'

RSpec.describe GdaxService do
  subject{GdaxService.instance}

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

  describe 'place an order' do
    it 'places limit orders' do
      res = subject.place_order(type: :limit, direction: :buy, btc_amount: 0.01, price: 200)
      expect(res).to be_a String
    end

    it 'places market orders' do
      res = subject.place_order(direction: :buy, btc_amount: 0.0005)
      expect(res).to be_a String
    end


    it 'places an order' do
      res = subject.place_order(type: :limit, direction: :sell, btc_amount: 0.01, price: 100_000)
      expect(res).to be_a String
    end

    it 'updates balance when buying' do
      Rails.cache.clear
      expect{
        subject.place_order(type: :limit, direction: :buy, btc_amount: 0.01, price: 200)
      }.to change{subject.balance_eur}.by(-2.005)
    end

  end

  describe 'retrieve an order' do
    it 'retrieves a filled order' do
      res = subject.order('7283831f-9acb-4ed0-8e3b-7ddcaaf43393')
      expect(res).to be_a Hash
      p res
    end
  end

  describe 'open_orders' do
    it 'responds true when no open orders' do
      p subject.open_orders
      expect(subject.open_orders).to be_a Hash
    end
  end

  describe 'open_orders?' do
    it 'responds true when no open orders' do
      expect(subject.open_orders?).to be_falsey
    end
  end


end
