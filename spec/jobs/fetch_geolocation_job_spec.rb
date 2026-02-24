require "rails_helper"

RSpec.describe FetchGeolocationJob do
  describe "#perform" do
    let(:visit) { create(:visit) }

    before do
      allow(Visit).to receive(:find).with(visit.id).and_return(visit)
    end

    context "when geolocation lookup succeeds" do
      let(:location) do
        instance_double(
          "Geocoder Result",
          country: "USA",
          city: "New York",
          country_code: "US",
          latitude: 40.7128,
          longitude: -74.0060
        )
      end

      before do
        allow(Geocoder).to receive(:search).with(visit.ip_address).and_return([ location ])
        allow(visit).to receive(:update)
      end

      it "updates the visit with fetched location data" do
        described_class.new.perform(visit.id)

        expect(visit).to have_received(:update).with(
          country: location.country,
          city: location.city,
          country_code: location.country_code,
          latitude: location.latitude,
          longitude: location.longitude
        )
      end
    end

    context "when geocoder returns no results" do
      before do
        allow(Geocoder).to receive(:search).with(visit.ip_address).and_return([])
        allow(visit).to receive(:update)
      end

      it "sets location fields to nil" do
        described_class.new.perform(visit.id)

        expect(visit).to have_received(:update).with(
          country: nil,
          city: nil,
          country_code: nil,
          latitude: nil,
          longitude: nil
        )
      end
    end

    context "when an error occurs during lookup" do
      before do
        allow(Geocoder).to receive(:search).with(visit.ip_address).and_raise(StandardError, "error")
        allow(Rails.logger).to receive(:warn)
      end

      it "logs a warning instead of raising" do
        expect { described_class.new.perform(visit.id) }.not_to raise_error

        expect(Rails.logger).to have_received(:warn).with(
          "Failed to fetch geolocation for IP #{visit.ip_address}: error"
        )
      end
    end
  end
end
