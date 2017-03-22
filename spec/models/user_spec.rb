describe User do
  let(:config){YAML.load(Rails.root.join('spec', 'fixtures', 'secret', 'kraken.yml'))}
  subject {User.new(kraken_token: ')}
  describe '#kraken_client' do
    it 'retrieves the ticker' do
      subject.kraken_client.ticker('BTCEUR')
    end
  end
end