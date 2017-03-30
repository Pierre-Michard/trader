require 'rails_helper'

describe User do

  subject {User.new(kraken_token: config['token'], kraken_secret: config['secret'])}
  describe '#kraken_client' do
    it 'retrieves the ticker' do
      p subject.kraken_client.public.asset_pairs
      res = subject.kraken_client.public.ticker('XXBTZEUR')
      expect(res).to be_a Hash
      p res
    end
  end
end