require 'active_merchant'
require 'flowcommerce'
require 'dotenv'
require 'pry'
require 'awesome_print'

Dotenv.load

require './lib/active_merchant/billing/gateways/flow'

# amount = 1000 # $10.00

# credit_card = ActiveMerchant::Billing::CreditCard.new(
#                 :first_name         => 'Bob',
#                 :last_name          => 'Bobsen',
#                 :number             => '4111111111111111',
#                 :month              => '8',
#                 :year               => Time.now.year+1,
#                 :verification_value => '123')

# gateway = ActiveMerchant::Billing::FlowGateway.new( token: ENV.fetch('FLOW_API_KEY'), organization: ENV.fetch('FLOW_ORGANIZATION') )

# result = gateway.authorize(amount, credit_card)

# authorization_key = result.params['response'].key

# ap authorization_key

# response = gateway.void(nil, authorization_key)
# ap response.success?
# response = gateway.void(nil, authorization_key)
# ap response.success?

