# Flow, 2017
# authorize, capture and void tests for Flow api

require 'spec_helper'

RSpec.describe ActiveMerchant::Billing::FlowGateway do

  # ActiveMerchant accepts all amounts as Integer values in cents
  let(:amount) { 1000 } # $10.00

  # init Flow with default ENV flow key names
  let(:gateway) { ActiveMerchant::Billing::FlowGateway.new(token: ENV.fetch('FLOW_API_KEY'), organization: ENV.fetch('FLOW_ORGANIZATION')) }

  let(:credit_card) {
    # The card verification value is also known as CVV2, CVC2, or CID
    ActiveMerchant::Billing::CreditCard.new(
      :first_name         => 'Bob',
      :last_name          => 'Bobsen',
      :number             => '4111111111111111',
      :month              => '8',
      :year               => Time.now.year+1,
      :verification_value => '123'
    )
  }

  it 'checks for purchase ability' do
    # Validating the card automatically detects the card type
    expect(credit_card.validate.empty?).to eq(true)

    # Capture $10 from the credit card
    response = gateway.purchase(amount, credit_card)
    expect(response.success?).to eq(true)
  end

  it 'deletes (voids) authorized transaction' do
    result = gateway.authorize(amount, credit_card)

    authorization_key = result.params['response'].key

    expect(authorization_key.length > 30).to eq(true)

    # we should be able to delete authorized transaction
    response = gateway.void(nil, authorization_key)
    expect(response.success?).to be_truthy

    # we allready deleted transaction, this should fail
    response = gateway.void(nil, authorization_key)
    expect(response.success?).to be_falsey
  end

end
