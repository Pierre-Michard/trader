require 'rails_helper'

RSpec.describe Trade, type: :model do
  describe '#create' do
    it 'creates successfully' do
      expect(KrakenService.instance).to receive(:place_order).
          with(type: :market, direction: :buy, btc_amount: 0.00689081){ 'OAYVHH-RMM7M-RIA5QH' }
      trade = Trade.find_or_create_by!(paymium_uuid: 'my_uuid') do |t|
        t.btc_amount= -0.00689081
        t.paymium_cost = 15.81
        t.paymium_price = 2294.71
        t.paymium_order_uuid = 'paymium order uuid'
      end

      expect(trade.reload.kraken_uuid).to eq 'OAYVHH-RMM7M-RIA5QH'
    end
  end

  describe '#close!' do
    subject{Trade.create(paymium_uuid: 'my_uuid', kraken_uuid: 'OAYVHH-RMM7M-RIA5QH', btc_amount: -0.00689081, paymium_cost:15.81, paymium_price:2294.71, aasm_state: 'created')}
    it 'closes successfully' do
      expect{subject.close!}.to change{subject.reload.aasm.current_state}.from(:kraken_order_placed).to(:closed)
      expect(subject.kraken_price).to eq 2268.029
      expect(subject.kraken_fee).to eq 0.034
      expect(subject.kraken_cost).to eq -15.628
    end
  end

  describe '#eur_margin' do
    subject{Trade.create(paymium_uuid: 'my_uuid',
                         kraken_uuid: 'OAYVHH-RMM7M-RIA5QH',
                         btc_amount: -0.00689081,
                         paymium_cost:15.81,
                         paymium_price:2294.71,
                         kraken_price:2268.029,
                         kraken_fee: 0.034,
                         kraken_cost: -15.628,
                         aasm_state: 'closed')}
    it 'creates successfully' do
      expect(subject.eur_margin).to be_within(0.0001).of(0.182)
    end
  end
end
