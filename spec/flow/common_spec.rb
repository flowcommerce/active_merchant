# Flow, 2017
# authorize, capture and void tests for Flow api

require 'spec_helper'

RSpec.describe ActiveMerchant::Billing::FlowGateway do

  # ActiveMerchant accepts all amounts as Integer values in cents
  let(:amount)   { 1 } # $1.00
  let(:currency) { 'USD' }

  # pre-created order with some $ for testing purposes
  # POST /orders                          - to create test order
  # PUT /orders/:order_number/submissions - to authorize, can take 30 - 120 seconds
  # after that all authorizations against an order should have result.status: "authorized"
  let(:test_order_number) { ENV.fetch('FLOW_ORDER_NUMBER') }

  # init Flow with default ENV flow key names
  let(:gateway) { ActiveMerchant::Billing::FlowGateway.new(token: ENV.fetch('FLOW_API_KEY'), organization: ENV.fetch('FLOW_ORGANIZATION')) }

  let(:raw_credit_card) {
    # The card verification value is also known as CVV2, CVC2, or CID
    {
      first_name:          'Dino',
      last_name:           'Reic',
      number:              '4111111111111111',
      month:               '8',
      year:                2020,
      verification_value:  '737'
    }
  }

  let(:credit_card) {
    ActiveMerchant::Billing::CreditCard.new(raw_credit_card)
  }

  let(:order_create_body) {
    {
      "items": [
        {
          "number": "sku-1",
          "quantity": 15,
          "center": "center-2dffd30d-2459-4937-aa4e-2647bf171867"
        }
      ],
      "customer": {
        "number": "client-user-123",
        "name": {
          "first": "Dino",
          "last": "Reic"
        },
        "phone": "+1-646-813-9414",
        "email": "dino.reic@test.flow.io"
      },
      "destination": {
        "streets": ["129 City Rd"],
        "city": "London",
        "postal": "EC1V 1JB",
        "country": "GBR"
      }
    }
  }

  ###

  it 'creates and subscribes an order (60 wait time)' do
    puts 'Please choose'.yellow
    puts ' 1. Create new order, submit it and enter received order number .env'
    puts ' 2. Proceed with tests'
    print 'Enter 1 or 2: '

    if $stdin.gets.chomp.to_i == 1
      order      = gateway.flow_create_order order_create_body, experience: "australia"
      expect(order.number.include?('ord-')).to be(true)

      puts ' Order number: %s' % order.number.yellow
      puts ' Please wait ~ 60 seconds for order to be approved.'

      submission = gateway.flow_submission_by_number order.number
      expect(order.number).to eq(submission.number)

      exit
    end
  end

  # test with cc as Hash or CreditCard instance
  it 'to create valid credit card token' do
    [credit_card, raw_credit_card].each do |cc|
      cc_token = gateway.store credit_card
      expect(cc_token.length).to eq 64
    end
  end

  it 'authorizes already created order' do
    token = gateway.store credit_card

    expect(token.length).to eq(64)

    response = gateway.authorize token, test_order_number,
      currency: currency,
      amount: amount,
      discriminator: :merchant_of_record_authorization_form

    expect(response.success?).to be(true)

    authorize = response.params['response']
    expect(authorize.key.include?('aut-')).to be(true)
  end

  it 'fails on bad authorize requests' do
    token = gateway.store credit_card

    response1 = gateway.authorize token, test_order_number,
      currency: currency,
      amount: amount

    expect(response1.success?).to be(false)

    response2 = gateway.authorize token, test_order_number,
      currency: currency,
      amount: amount,
      discriminator: :foo

    expect(response2.success?).to be(false)
  end

  it 'get flow authorization from order_number' do
    response = gateway.flow_get_authorization order_number: test_order_number

    expect(response.key.include?('aut-')).to be_truthy
    expect(['review', 'authorized'].include?(response.result.status.value)).to be_truthy
  end

  it 'captures funds' do
    authorization = gateway.flow_get_authorization order_number: test_order_number
    response      = gateway.capture 0.1, authorization.key, currency: currency

    expect(response.success?).to be(true)

    capture       = response.params['response']

    expect(capture.nil?).to be(false)
    expect(capture.key.include?('cap-')).to be_truthy
    expect(capture.authorization.key).to eq(authorization.key)
    expect(capture.status.value).to eq('succeeded')
  end

  it 'voids (cancels) the authorization' do
    authorization = gateway.flow_get_authorization order_number: test_order_number

    expect(authorization.key.include?('aut-')).to be(true)

    response = gateway.void 0.1, authorization.key, currency: 'USD'
    expect(response.success?).to be_truthy
    expect(response.params['response'].key.include?('rev-')).to be(true)
  end

  it 'refunds the transaction by authorization_id' do
    authorization = gateway.flow_get_authorization order_number: test_order_number
    response      = gateway.capture 0.1, authorization.key, currency: currency

    expect(response.success?).to be(true)

    capture       = response.params['response']

    expect(capture.nil?).to be(false)
    expect(capture.key.include?('cap-')).to be_truthy
    expect(capture.authorization.key).to eq(authorization.key)
    expect(capture.status.value).to eq('succeeded')

    response = gateway.refund 0.1, capture.id, currency: 'USD'
    expect(response.success?).to be_truthy
    expect(response.params['response'].key.include?('ref-')).to be(true)

    bad_response = gateway.refund(nil, capture.id)
    expect(bad_response.success?).to be(false)
  end

end
