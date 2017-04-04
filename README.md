<img align="right" src="http://i.imgur.com/tov8bTw.png">

# Flow.io adapter for ActiveMerchant


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

  # init the gateway
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

Plest contact Flow.io for more details.

## Using the ActiveMerchant::Billing::FlowGateway

Require activemerchant_flow gem and initialize the gateway

```
  require 'activemerchant_flow'
 
  gateway = ActiveMerchant::Billing::FlowGateway.new(
    token: ENV.fetch('FLOW_API_KEY'),
    organization: ENV.fetch('FLOW_ORGANIZATION')
   )
```

Now that we have gateway we can authorize and capture funds.



### authorize and capture, or just purchase

Purchase method is shortcut for authorize && capture. Please keep in mind that currency is required option for authorize and purchase.

If you [maintain order in Flow](https://docs.flow.io/module/localization/resource/orders) and have order number, you can send it as order_id option to both authorize and purchase.

```
  auth_response    = gateway.authorize(amount, credit_card, currency: 'USD')
  capture_response = gateway.capture(amount, auth_response.authorization)

```

or

```
  response = gateway.purchase(amount, credit_card, currency: 'USD')
``` 

### void - cancel transaction

For purchase order cancelation, you need authorization key from Flow. You will find it in 

```
   authorization_key  = authorize_response.params['response'].key

   response = gateway.void(nil, authorization_key)
```

### refund funds

```
  auth_id = authorize_response.params['response'].id

  response = gateway.refund(nil, nil, authorization_id: auth_id)
```

## Reading raw Flow API response

For all Active Merchant responses, raw response object is stored in params['response'].

```
  am_response = gateway.authorize(...)
  am_response.params['response'] == Io::Flow::V0::Models::Authorization # true
```

If error accurs, response message will be error message only. Complete error object
will be sent as option parameter named exception. am_response.success? will be false on failed
requests.

Response object will 

## Contributing

* Fork it
* Create your feature branch (git checkout -b my-new-feature)
* Commit your changes (git commit -am 'Add some feature')
* Push to the branch (git push origin my-new-feature)
* Create new Pull Request