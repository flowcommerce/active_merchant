# Flow.io for ActiveMerchant

## Use cases

Authorize and capture payments with Flow.io, in any currency, anywhere in the world.

More on http://www.flow.io

## Example

```
  # unless ENV['FLOW_API_KEY']
  #  require 'dotenv'
  #  Dotenv.load
  # end

  require 'activemerchant_flow'

  amount = 1000 # $10.00

  # init Flow with default ENV flow key names
  gateway = ActiveMerchant::Billing::FlowGateway.new(token: ENV.fetch('FLOW_API_KEY'), organization: ENV.fetch('FLOW_ORGANIZATION'))

  # The card verification value is also known as CVV2, CVC2, or CID
  credit_card = ActiveMerchant::Billing::CreditCard.new(
    :first_name         => 'Bob',
    :last_name          => 'Bobsen',
    :number             => '4111111111111111',
    :month              => '8',
    :year               => Time.now.year+1,
    :verification_value => '123'
  )

  auth_response = gateway.authorize(amount, credit_card, currency: 'USD')

  # # Capture $10 from the credit card
  capture_response = gateway.capture(amount, auth_response.authorization)

  puts capture_response.success? # true

```

## To enable payments in Solidus / Spree

Aditional to installing activemerchant_flow gem we need to install Solidus/Spree gateway adapter

In config/application.rb add

```
  config.after_initialize do |app|
    app.config.spree.payment_methods << Spree::Gateway::Flow
  end
```

## Using the ActiveMerchant::Billing::FlowGateway

Require activemerchant_flow gem and initialize the gateway

```
require 'activemerchant_flow'

gateway = ActiveMerchant::Billing::FlowGateway.new(token: ENV.fetch('FLOW_API_KEY'), organization: ENV.fetch('FLOW_ORGANIZATION'))
```


## Reading Flow raw api response

For all Active Merchant responses, raw response object is stored in params['response'].

```
  result = gateway.authorize(...)
  result.params['response'] == Io::Flow::V0::Models::Authorization # true
```

response = gateway.authorize(amount, credit_card)

If error accurs, response message will be error message only. Complete error object
will be sent as option parameter named exception.