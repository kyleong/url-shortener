require 'rails_helper'

RSpec.describe LogVisitService do
  let(:url) { double('url') }
  let(:request) { double('request', remote_ip: '127.0.0.1', user_agent: 'Mozilla', referer: 'http://example.com') }
  subject { described_class.new(url, request) }

  describe '#call!' do
    context 'when geocoding succeeds' do
      let(:location) { double('location', country: 'USA', city: 'New York', country_code: 'US', latitude: 40.7128, longitude: -74.0060) }

      before do
        allow(Geocoder).to receive(:search).and_return([ location ])
      end

      it 'creates a visit with location data' do
        expect(Visit).to receive(:create!).with(
          url: url,
          ip_address: '127.0.0.1',
          country: 'USA',
          city: 'New York',
          country_code: 'US',
          latitude: 40.7128,
          longitude: -74.0060,
          user_agent: 'Mozilla',
          referer: 'http://example.com',
          visited_at: an_instance_of(ActiveSupport::TimeWithZone)
        )
        subject.call!
      end
    end

    context 'when geocoding fails' do
      before do
        allow(Geocoder).to receive(:search).and_return([])
      end

      it 'creates a visit without location data' do
        expect(Visit).to receive(:create!).with(
          url: url,
          ip_address: '127.0.0.1',
          country: nil,
          city: nil,
          country_code: nil,
          latitude: nil,
          longitude: nil,
          user_agent: 'Mozilla',
          referer: 'http://example.com',
          visited_at: an_instance_of(ActiveSupport::TimeWithZone)
        )
        subject.call!
      end
    end

    context 'when Visit.create! raises an error' do
      before do
        allow(Geocoder).to receive(:search).and_return([])
        allow(Visit).to receive(:create!).and_raise(StandardError.new('DB error'))
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:warn).with('Failed to log visit: DB error')
        subject.call!
      end
    end
  end
end
