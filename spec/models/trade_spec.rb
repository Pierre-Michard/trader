require 'rails_helper'

RSpec.describe Trade, type: :model do
  describe '#create' do
    it 'creates successfully' do
      expect(Kraken.instance).to receive(:place_market_order).
          with(direction: :buy, btc_amount: 3){
        Hashie::Mash.new(tx_id: 'txid')
      }
      trade = Trade.find_or_create_by(paymium_uuid: 'my_uuid') do |t|
        t.btc_amount= 3
      end

    end
  end
end
