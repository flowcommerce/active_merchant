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
  let(:test_order_number) { 'ord-e1e9d7aa0a0b41f6a01d8af14c1fd05b' }

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

  ###

  # test with cc as Hash or CreditCard instance
  it 'to create valid credit card token' do
    [credit_card, raw_credit_card].each do |cc|
      cc_token = gateway.store credit_card
      expect(cc_token.length).to eq 64
    end
  end

  it 'authorizes allready created order' do
    token = gateway.store credit_card

    expect(token.length).to eq(64)

    response = gateway.authorize token, test_order_number, currency: currency, amount: amount
    expect(response.success?).to be(true)

    authorize = response.params['response']
    expect(authorize.key.include?('aut-')).to be(true)
  end

  it 'get flow authorization from order_number' do
    response = gateway.flow_get_authorization order_number: test_order_number

    expect(response.key.include?('aut-')).to be_truthy
    expect(['review', 'authorized'].include?(response.result.status.value)).to be_truthy
  end

  it 'captures funds' do
    authorization = gateway.flow_get_authorization order_number: test_order_number
    response      = gateway.capture 0.1, authorization.key
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
    response      = gateway.capture 0.1, authorization.key
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

  # it 'checks create order, authorize and capture (if not in review) ability' do
  #   # Authorize $10 from the credit card
  #   # auth_response = gateway.authorize(amount, credit_card, currency: 'USD')#, order_number: 'ord-28bc0cc14db6433d8bdfa51ff6878511')

  #   expect(auth_response.message).to eq "Flow authorize - Success"

  #   # Capture $10 from the credit card
  #   capture_response = gateway.capture(amount, auth_response.authorization)

  #   expect(capture_response.success?).to be_truthy
  # end

  # it 'checks for purchase ability' do
  #   # Validating the card automatically detects the card type
  #   # expect(credit_card.validate.empty?).to be_truthy

  #   # Capture $10 from the credit card
  #   response = gateway.purchase(amount, credit_card, currency: 'USD')
  #   expect(response.success?).to be_truthy
  # end

  # it 'deletes (voids) authorized transaction' do
  #   result = gateway.authorize(amount, credit_card, currency: 'USD')

  #   authorization_key = result.params['response'].key

  #   expect(authorization_key.length > 30).to be_truthy

  #   # we should be able to delete authorized transaction
  #   response = gateway.void(nil, authorization_key)
  #   expect(response.success?).to be_truthy

  #   # we allready deleted transaction, this should fail
  #   response = gateway.void(nil, authorization_key)
  #   expect(response.success?).to be_falsey
  # end

  # it 'refunds the transaction by capture id' do
  #   response   = gateway.purchase(amount, credit_card, currency: 'USD')
  #   capture_id = response.params['response'].id

  #   expect(capture_id.include?('cap-')).to be_truthy

  #   response = gateway.refund(nil, capture_id)
  #   expect(response.id.include?('ref-')).to be_truthy

  #   expect{ gateway.refund(nil, capture_id) }.to raise_error(Io::Flow::V0::HttpClient::ServerError)
  # end

  # it 'refunds the transaction by authorization key' do
  #   auth_response = gateway.authorize amount, credit_card, currency: 'USD'
  #   gateway.capture amount, auth_response.authorization

  #   auth_id = auth_response.params['response'].id
  #   expect(auth_id.include?('aut-')).to be_truthy

  #   response = gateway.refund(nil, nil, authorization_id: auth_id)
  #   expect(response.id.include?('ref-')).to be_truthy
  # end

  # it 'checks storage of credit card' do
  #   response = gateway.store(credit_card)
  #   expect(response.success?).to be_truthy
  #   expect(response.params['token'].length).to eq(64)
  #   expect(response.params['response'].id.include?('crd-')).to be_truthy
  # end

  # it 'checks creation of MerchantOfRecordAuthorizationForm if order_id is present' do
  #   auth_response    = gateway.authorize(amount, credit_card, currency: 'USD', order_id: order_id)
  #   capture_response = gateway.capture(amount, auth_response.authorization)
  #   expect(capture_response.success?).to be_truthy
  # end

end
