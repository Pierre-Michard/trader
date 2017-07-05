require 'rails_helper'

describe RobotService do
  subject{RobotService.new}

  describe 'sell_amount' do
    it 'responds successfully' do
      expect(subject.sell_amount).to be_a Numeric
      expect(subject.sell_amount).to be > 0
    end
  end

  describe 'buy_amount' do
    it 'responds successfully' do
      expect(subject.buy_amount).to be_a Numeric
      expect(subject.buy_amount).to be > 0
    end
  end

  describe 'monitor_sell_price' do
    it 'responds successfully' do
      expect{subject.monitor_sell_price}.not_to raise_exception
    end
  end

  describe 'monitor_buy_price' do
    it 'responds successfully' do
      expect{subject.monitor_buy_price}.not_to raise_exception
    end
  end

  describe 'buy_marge' do
    before do
      allow(subject).to receive(:buy_presure){buy_presure}
    end
    context 'huge presure' do
      let(:buy_presure){1}
      it 'computes correct marge' do
        expect(subject.buy_marge).to be_within(0.0001).of(0.003)
      end
    end
    context 'regular presure' do
      let(:buy_presure){0.5}
      it 'computes correct marge' do
        expect(subject.buy_marge).to be_within(0.0001).of(0.008)
      end
    end
    context 'low presure' do
      let(:buy_presure){0}
      it 'computes correct marge' do
        expect(subject.buy_marge).to be_within(0.0001).of(0.03)
      end
    end

  end

  describe 'sell_marge' do
    before do
      allow(subject).to receive(:sell_presure){sell_presure}
    end
    context 'huge presure' do
      let(:sell_presure){1}
      it 'computes correct marge' do
        expect(subject.sell_marge).to be_within(0.0001).of(0.005)
      end
    end
    context 'regular presure' do
      let(:sell_presure){0.5}
      it 'computes correct marge' do
        expect(subject.sell_marge).to be_within(0.0001).of(0.02)
      end
    end
    context 'low presure' do
      let(:sell_presure){0}
      it 'computes correct marge' do
        expect(subject.sell_marge).to be_within(0.0001).of(0.03)
      end
    end

  end
end