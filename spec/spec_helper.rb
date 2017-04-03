# https://github.com/activemerchant/active_merchant
# http://www.rubydoc.info/github/Shopify/active_merchant/ActiveMerchant/Billing/Gateway
# http://activemerchant.rubyforge.org/classes/ActiveMerchant/Billing/Response.html
# https://github.com/activemerchant/active_merchant/blob/master/lib/active_merchant/billing/gateways/stripe.rb
# https://docs.flow.io/type/authorization-form

require 'active_merchant'
require 'flowcommerce'
require 'dotenv'
require 'pry'
require 'awesome_print'
require 'digest'

Dotenv.load

require './lib/active_merchant/billing/gateways/flow'

ActiveMerchant::Billing::Base.mode = :test

RSpec.configure do |config|
  config.color = true
  config.tty = true
  config.formatter = :documentation
end
