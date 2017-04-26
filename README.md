<img align="right" src="http://i.imgur.com/tov8bTw.png">

# Flow.io adapter for ActiveMerchant

[Website](https://www.flow.io/) | [Conslole](https://console.flow.io/) | [Docs](https://docs.flow.io/)

Authorize and capture payments with Flow.io, in any currency, anywhere in the world.

More on [https://www.flow.io](https://www.flow.io)

## Getting Started

Gem requires Ruby version ```>= 2.2.2.```

1. Install adapter at the command prompt :

	```
	 $ gem install flowcommerce-activemerchant
	```

1. Add to your application following ENV variables

	```FLOW_API_KEY```, ```FLOW_ORGANIZATION``` and ```FLOW_BASE_COUNTRY```
	
	For testing you can use Flow sandbox values

	```
	FLOW_ORGANIZATION='playground'
	FLOW_API_KEY='HlGgfflLamiTQJ'
	FLOW_BASE_COUNTRY='usa'
	```

1. Clone the repository

	```git clone https://github.com/flowcommerce/active_merchant.git```
	
	run tests with `rspec`
	
	Find examples of all available adapter actions in `./spec/flow` folder.


## Example

Run example with Flow sandbox values

```
  require 'flowcommerce-activemerchant'

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

## Using the ActiveMerchant::Billing::FlowGateway

Require gem and initialize the gateway

```
  require 'flowcommerce-activemerchant'

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

### tokenize credit card

```
  response = gateway.store(credit_card)
  expect(response.success?).to eq(true)
  expect(response.params['token'].length).to eq(64)
```



## Reading raw Flow API response

For all Active Merchant responses, raw response object is stored in params['response'].

```
  am_response = gateway.authorize(...)
  am_response.params['response'] == Io::Flow::V0::Models::Authorization # true
```

In case of an error, response message will be error message only. Complete error object
will be sent as option parameter named ```exception```. am_response.success? will be false on failed
requests.

## Contributing

Feel free to email us at tech@flow.io

or

* Fork it
* Create your feature branch (git checkout -b my-new-feature)
* Commit your changes (git commit -am 'Add some feature')
* Push to the branch (git push origin my-new-feature)
* Create new Pull Request

## License

ActiveMerchant Flow adapter is released under the MIT License.