# @Flow.io (2017)

module ActiveMerchant
  module Billing
    class FlowGateway < Gateway

      self.display_name     = 'Flow.io Pay'
      self.homepage_url     = 'https://www.flow.io/'
      self.default_currency = 'USD'

      def initialize(options = {})
        @flow_token = options[:token]        || ENV['FLOW_TOKEN']
        @flow_org   = options[:organization] || ENV['FLOW_ORG']

        raise ArgumentError, "Flow token is not defined (:token or ENV['FLOW_TOKEN'])" unless @flow_token
        raise ArgumentError, "Flow organization is not defined (:organization or ENV['FLOW_ORG'])" unless @flow_org

        super
      end

      def authorize(amount, payment_method, options={})
        get_flow_cc_token payment_method

        data = {
          token:    @flow_cc_token,
          amount:   amount / 10.0,
          currency: self.default_currency,
          cvv:      payment_method.verification_value,
          customer: {
            name: {
              first: payment_method.first_name,
              last: payment_method.last_name
            }
          }
        }

        direct_authorization_form = ::Io::Flow::V0::Models::DirectAuthorizationForm.new data
        response = FlowCommerce.instance.authorizations.post(@flow_org, direct_authorization_form)

        if response.result.status.value == 'authorized'
          # what store this in spree order object, for capure
          store = {}
          store[:authorization_id] = response.id
          store[:currency]         = response.currency
          store[:amount]           = response.amount
          store[:key]              = response.key

          @flow_authorization = store

          # http://activemerchant.rubyforge.org/classes/ActiveMerchant/Billing/Response.html
          Response.new(true, 'Flow authorize - Success', {}, { authorization: store })
        else
          Response.new(false, 'Flow authorize - Error')
        end
      end

      def store(*args)
        binding.pry
      end

      def capture(_money, authorization, options={})
        raise ArgumentError, 'No Authorization authorization, please authorize first' unless authorization

        capture_form = ::Io::Flow::V0::Models::CaptureForm.new(authorization)
        response     = FlowCommerce.instance.captures.post(@flow_org, capture_form)

        if response.id
          Response.new(true, 'Flow capture - Success')
        else
          Response.new(false, 'Flow capture - Error')
        end
      end

    #   def refund(money, authorization, options={})
    #     raise 'refund'
    #     # to do
    #     ActiveMerchant::Billing::Response.new(true, 'Flow Gateway - Success')
    #   end

    #   def void(money, authorization, options={})
    #     raise 'void'
    #     # to do
    #     ActiveMerchant::Billing::Response.new(true, 'Flow Gateway - Success')
    #   end

      def purchase(money, credit_card, options={})
        response = authorize money, credit_card
        capture money, response.authorization
      end

      private

      def get_flow_cc_token(credit_card)
        return if @flow_cc_token

        data = {}
        data[:number]           = credit_card.number
        data[:name]             = '%s %s' % [credit_card.first_name, credit_card.last_name]
        data[:cvv]              = credit_card.verification_value
        data[:expiration_year]  = credit_card.year.to_i
        data[:expiration_month] = credit_card.month.to_i

        card_form = ::Io::Flow::V0::Models::CardForm.new(data)
        result    = FlowCommerce.instance.cards.post(ENV.fetch('FLOW_ORG'), card_form)

        @flow_cc_token = result.token
      end
    end
  end
end