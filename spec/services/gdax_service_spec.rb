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
