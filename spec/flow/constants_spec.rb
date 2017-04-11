# Flow, 2017
# authorize, capture and void tests for Flow api

require 'spec_helper'

RSpec.describe ActiveMerchant::Billing::FlowGateway do

  it 'checks for validity of constants from flow-reference' do
    ref = ActiveMerchant::Billing::FlowGateway

    expect(ref.supported_countries.class).to eq(Array)
    expect(ref.supported_countries.length > 50).to eq(true)
    expect(ref.supported_cardtypes.length > 10).to eq(true)
  end

end
