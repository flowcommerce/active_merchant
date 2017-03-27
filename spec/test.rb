# https://github.com/activemerchant/active_merchant
# http://www.rubydoc.info/github/Shopify/active_merchant/ActiveMerchant/Billing/Gateway
# https://github.com/activemerchant/active_merchant/blob/master/lib/active_merchant/billing/gateways/stripe.rb
# https://docs.flow.io/type/authorization-form

require 'active_merchant'
require 'flowcommerce'
require 'dotenv'
require 'pry'
require 'awesome_print'

Dotenv.load

require './lib/flow'

# Use the TrustCommerce test servers
ActiveMerchant::Billing::Base.mode = :test

gateway = ActiveMerchant::Billing::FlowGateway.new( token: ENV.fetch('FLOW_TOKEN'), organization: ENV.fetch('FLOW_ORG') )

# ActiveMerchant accepts all amounts as Integer values in cents
amount = 1000  # $10.00

# The card verification value is also known as CVV2, CVC2, or CID
credit_card = ActiveMerchant::Billing::CreditCard.new(
                :first_name         => 'Bob',
                :last_name          => 'Bobsen',
                :number             => '4111111111111111',
                :month              => '8',
                :year               => Time.now.year+1,
                :verification_value => '123')

# Validating the card automatically detects the card type
if credit_card.validate.empty?
  # Capture $10 from the credit card
  response = gateway.purchase(amount, credit_card)

  if response.success?
    puts "Successfully charged $#{sprintf("%.2f", amount / 100)} to the credit card #{credit_card.display_number}"
  else
    raise StandardError, response.message
  end
end