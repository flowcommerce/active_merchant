# Flow, 2017
# authorize, capture and void tests for Flow api

require 'spec_helper'

RSpec.describe ActiveMerchant::Billing::FlowGateway do

  # ActiveMerchant accepts all amounts as Integer values in cents
  let(:test_currency) { 'USD' }
  let(:test_amount)   { 0.1 }

  # token and organization_id are set in env variables
  # FLOW_API_KEY
  # FLOW_ORGANIZATION
  gateway = ActiveMerchant::Billing::FlowGateway.new

  let(:raw_credit_card) {
    # The card verification value is also known as CVV2, CVC2, or CID
    {
      first_name:          'Ruby',
      last_name:           'Active',
      number:              '4111111111111111',
      month:               '8',
      year:                2023,
      verification_value:  '737'
    }
  }

  let(:credit_card) {
    ActiveMerchant::Billing::CreditCard.new(raw_credit_card)
  }

  let(:get_cc_token) {
    token = gateway.store credit_card
    expect(token.class).to be(String)
    expect(token.length).to be(64)
    token
  }

  test_order_number = nil

  test_capture = nil

  before(:all) do
    order_form = ::Io::Flow::V0::Models::OrderForm.new(
      items: [
        ::Io::Flow::V0::Models::LineItemForm.new(number: "34528974504093", quantity: 1, center: "default")
      ],
      customer: ::Io::Flow::V0::Models::OrderCustomerForm.new(
        number: "client-user-123",
        phone: "+1-646-813-9414",
        email: "activemerchant@test.flow.io",
        name: ::Io::Flow::V0::Models::Name.new(first: "Ruby", last: "Active")
      ),
      destination: ::Io::Flow::V0::Models::OrderAddress.new(
        streets: ["600 George St"],
        city: "Sydney",
        postal: "2000",
        province: "NSW",
        country: "AUS"
      )
    )

    order = gateway.flow_create_order order_form, experience: "australia"
    submission = gateway.flow_submission_by_number order.number
    puts "Order Number: #{order.number}".yellow
    test_order_number = order.number
  end

  ###

  # test with cc as Hash or CreditCard instance
  it 'to create valid credit card token' do
    [credit_card, raw_credit_card].each do |cc|
      cc_token = get_cc_token
      expect(cc_token.length).to eq 64
    end
  end

  it 'authorizes already created order' do
    token = get_cc_token

    response = gateway.authorize token, test_order_number,
      currency: test_currency,
      amount: test_amount,
      discriminator: :merchant_of_record_authorization_form

    expect(response.success?).to be(true)

    authorize = response.params['response']
    expect(authorize.key.include?('aut-')).to be(true)

    fraud_status = ""
    while fraud_status != "approved"
      print "Waiting 5 seconds for fraud review... ".yellow
      sleep(5)
      fraud_status = gateway.flow_get_fraud_status(test_order_number)
      puts fraud_status.yellow
    end
    puts "Sleeping again for event to sync".yellow
    sleep(5)
  end

  it 'fails on bad authorize requests' do
    token = get_cc_token

    response1 = gateway.authorize token, test_order_number,
      currency: test_currency,
      amount: test_amount

    expect(response1.success?).to be(false)

    response2 = gateway.authorize token, test_order_number,
      currency: test_currency,
      amount: test_amount,
      discriminator: :foo

    expect(response2.success?).to be(false)
  end

  it 'get flow authorization from order_number' do
    response = gateway.flow_get_latest_authorization order_number: test_order_number
    expect(response.key.include?('aut-')).to be_truthy
    expect(['review', 'authorized'].include?(response.result.status.value)).to be_truthy
    response
  end

  it 'captures funds' do
    authorization = gateway.flow_get_latest_authorization order_number: test_order_number
    response = gateway.capture test_amount, authorization.key, currency: test_currency
    expect(response.success?).to be(true)

    capture = response.params['response']

    expect(capture.nil?).to be(false)
    expect(capture.key.include?('cap-')).to be_truthy
    expect(capture.authorization.key).to eq(authorization.key)
    expect(capture.status.value).to eq('succeeded')

    test_capture = capture
  end

  it 'refunds the transaction by authorization_id' do
    response = gateway.refund test_amount, test_capture.id, currency: test_currency
    expect(response.success?).to be_truthy
    expect(response.params['response'].key.include?('ref-')).to be(true)

    bad_response = gateway.refund(nil, test_capture.id)
    expect(bad_response.success?).to be(false)
  end


  it 'voids (cancels) the authorization' do
    puts "Sleeping again for events to sync".yellow
    sleep(5)

    token = get_cc_token

    response = gateway.authorize token, test_order_number,
      currency: test_currency,
      amount: test_amount,
      discriminator: :merchant_of_record_authorization_form

    authorization = response.params['response']
    expect(authorization.key.include?('aut-')).to be(true)

    response = gateway.void test_amount, authorization.key, currency: test_currency
    expect(response.success?).to be_truthy
    expect(response.params['response'].key.include?('rev-')).to be(true)
  end

end
