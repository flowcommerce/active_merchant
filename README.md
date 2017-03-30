# Flow Active Merchant

## Payment flow for Solidus

We need to complete this simple steps

1. add in config ```Rails.application.config.spree.payment_methods << Spree::Gateway::Flow```
1. authorize the credit card
1. capture payments with authorization tokens

### Creating Flow authorization tokens

We can store authorization tokens in two ways. Active Merchent adapter and before_filter on CreditCard model

#### Active Merchant adapter

1. We need ```Spree::Gateway::Flow``` class that
   * return true for payment_profiles_supported?
   * implement storage of credit_cards via ```create_profile``` method
2. Use before_save ActiveRecord filter on Spree::CreditCard model to capture
   number and write it to cache field

## Intgration with Solidus/Spree

Integration is automatic, just add a gem.

## Use cases

Authorize and capture payments with flow, in any currency.

### Using local currency

If you want to send in local currency, you have to define it in options.

```
  # http://activemerchant.rubyforge.org/classes/ActiveMerchant/Billing/Gateway.html

  gateway = ActiveMerchant::Billing::FlowGateway.new( ... )
  gateway.authorize(amount, <ActiveMerchant::Billing::CreditCard>, {
    :order_id => ...,
    :currency => 'CAD',
  })
```

### Reading Flow raw api response

For all Active Merchant responses, raw response object is stored in params['response'].

```
  result = gateway.authorize(...)
  result.params['response'] == Io::Flow::V0::Models::Authorization # true
```

response = gateway.authorize(amount, credit_card)

If error accurs, response message will be error message only. Complete error object
will be sent as option parameter named exception.