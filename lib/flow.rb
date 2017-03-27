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

        ap response

        if response.result.status.value == 'authorized'
          Response.new(true, 'Flow authorize - Success')
        else
          Response.new(false, 'Flow authorize - Error')
        end
      end

      def store(*args)
        binding.pry
      end

    #   def capture(_money, authorization, options={})
    #     raise 'capture'
    #     # load order
    #     order = get_spree_order options

    #     # try to capture funds
    #     order.flow_cc_capture

    #     ActiveMerchant::Billing::Response.new(true, 'Flow Gateway - Success')
    #   rescue => ex
    #     ActiveMerchant::Billing::Response.new(false, ex.message)
    #   end

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

    #   private

    #   def get_spree_order(options)
    #     order_number = options[:order_id].split('-').first

    #     Spree::Order.find_by number: order_number
    #   end

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