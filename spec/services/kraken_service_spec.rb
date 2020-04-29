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
      expect(subject.balance_eur).to eq(BigDecimal('100.1'))
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

  describe 'orderbook' do
    it 'retrieves the orderbook' do
      expect(subject.orderbook).to be_a Hash
      expect(subject.orderbook).to have_key :bids
      expect(subject.orderbook).to have_key :asks
    end

    it 'retrieves bids' do
      bids = subject.orderbook[:bids]
      expect(bids).to be_an Array
      expect(bids[0]).to have_key :price
      expect(bids[0]).to have_key :amount
    end

    it 'orders bids by price' do
      bids = subject.orderbook[:bids]
      bids.each_slice(2) do |bid1, bid2|
        expect(bid1[:price]).to be > bid2[:price]
      end
    end

    it 'retrieves asks' do
      asks = subject.orderbook[:asks]
      expect(asks).to be_an Array
      expect(asks[0]).to have_key :price
      expect(asks[0]).to have_key :amount
    end

    it 'orders asks by price' do
      asks= subject.orderbook[:asks]
      asks.each_slice(2) do |ask1, ask2|
        expect(ask1[:price]).to be < ask2[:price]
      end
    end
  end

  describe 'sdepth' do
    let(:cache) { Rails.cache }

    before do
      cache.clear
    end

    it 'retrieves sdepth' do
      expect(subject).to receive(:orderbook).once.and_call_original
      subject.sdepth
      sdepth = subject.sdepth
      expect(cache.exist?(subject.sdepth_key)).to be(true)
      expect(sdepth).to have_key :asks
    end
  end

  describe 'last_trade' do
    let(:cache) { Rails.cache }

    before do
      cache.clear
    end

    it 'retrieve last trade' do
      expect(subject).to receive(:get_last_trade).once.and_call_original
      subject.last_trade
      last_trade = subject.last_trade
      expect(cache.exist?(subject.public_trades_key)).to be(true)
      expect(last_trade).to have_key :price
    end
  end
end
