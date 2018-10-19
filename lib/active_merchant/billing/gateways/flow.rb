# @Flow.io (2017)
# Active Merchant adapter for Flow api

require 'flowcommerce-reference'

module ActiveMerchant
  module Billing
    class FlowGateway < Gateway
      unless defined?(::ActiveMerchant::Billing::FlowGateway::VERSION)
        VERSION = File.read(File.expand_path("../../../../.version", File.dirname(__FILE__))).chomp

        FORM_TYPES = [
          :authorization_copy_form, :direct_authorization_form, :merchant_of_record_authorization_form,
          :paypal_authorization_form, :redirect_authorization_form, :inline_authorization_form,
          :card_authorization_form, :ach_authorization_form
        ]
      end

      self.display_name        = 'Flow.io Pay'
      self.homepage_url        = 'https://www.flow.io/'
      self.default_currency    = 'USD'
      self.supported_countries = FlowCommerce::Reference::Countries::ISO_3166_2
      self.supported_cardtypes = FlowCommerce::Reference::PaymentMethods::SUPPORTED_CREDIT_CARDS


      def initialize options = {}
        @flow_api_key      = options[:api_key]      || ENV['FLOW_API_KEY']
        @flow_organization = options[:organization] || ENV['FLOW_ORGANIZATION']

        raise ArgumentError, "Flow token is not defined (:api_key or ENV['FLOW_API_KEY'])" unless @flow_api_key
        raise ArgumentError, "Flow organization is not defined (:organization or ENV['FLOW_ORGANIZATION'])" unless @flow_organization

        super
      end

      # Create a new authorization.
      # https://docs.flow.io/module/payment/resource/authorizations#post-organization-authorizations
      def authorize cc_or_token, order_number, opts={}
        unless opts[:currency]
          return error_response('Currency is a required option')
        end

        unless opts[:discriminator]
          return error_response 'Discriminator is not defined, please choose one [%s]' % FORM_TYPES.join(', ')
        end

        unless FORM_TYPES.include?(opts[:discriminator].to_sym)
          return error_response 'Discriminator [%s] not found, please choose one [%s]' % [opts[:discriminator], FORM_TYPES.join(', ')]
        end

        body = {
          amount:        opts[:amount] || 0.0,
          currency:      opts[:currency],
          discriminator: opts[:discriminator],
          token:         store(cc_or_token),
          order_number:  order_number
        }

        response = flow_instance.authorizations.post @flow_organization, body

        Response.new true, 'Flow authorize - Success', { response: response }
      rescue => exception
        error_response exception
      end

      # https://docs.flow.io/module/payment/resource/authorizations#get-organization-authorizations
      def flow_get_authorization order_number:
        response = flow_instance.authorizations.get @flow_organization, order_number: order_number
        response.last
      rescue => exception
        error_response exception
      end

      # https://docs.flow.io/module/payment/resource/captures#post-organization-captures
      def capture amount, authorization_key, options={}
        return error_response('Currency is a required option') unless options[:currency]

        body = {
          authorization_id: authorization_key,
          amount:           amount,
          currency:         options[:currency]
        }

        begin
          capture_form = ::Io::Flow::V0::Models::CaptureForm.new body
          response     = flow_instance.captures.post @flow_organization, capture_form
        rescue => exception
          error_response exception
        end

        if response.try(:id)
          Response.new true, 'Flow capture - Success', { response: response }
        else
          Response.new false, 'Flow capture - Error', { response: response }
        end
      rescue Io::Flow::V0::HttpClient::ServerError => exception
        error_response exception
      end

      # def purchase money, credit_card, options={}
      #   response = authorize money, credit_card, options
      #   capture money, response.authorization
      # end

      # https://docs.flow.io/module/payment/resource/reversals#post-organization-reversals
      # if amount is not provided, reverse the full or remaining amount
      def void amount, authorization_id, options={}
        options[:authorization_id] = authorization_id

        if amount
          options[:amount] = assert_currency options[:currency], amount
        end

        response = flow_instance.reversals.post @flow_organization, options

        Response.new true, 'void success', { response: response }
      rescue Io::Flow::V0::HttpClient::ServerError => exception
        error_response exception
      end

      # https://docs.flow.io/module/payment/resource/refunds
      # authorization_id - The Id of the authorization against which to issue the refund. If specified, we will look at all captures for this authorization, selecting 1 or more captures against which to issue the refund of the requested amount.
      # capture_id       - The Id of the capture against which to issue the refund. If specified, we will only consider this capture.
      # order_number     - The order number if specified during authorization. If specified, we will lookup all authorizations made against this order number, and then selecting 1 or more authorizations against which to issue the refund of the requested amount.
      # amount           - The amount to refund, in the currency of the associated capture. Defaults to the value of the capture minus any prior refunds.
      # currency         - The ISO 4217-3 code for the currency. Required if amount is specified. Case insensitive. Note you will get an error if the currency does not match the related authrization's currency. See https://api.flow.io/reference/currencies
      # rma_key          - The RMA key, if available. If specified, this will udpate the RMA status as refunded.
      def refund amount, capture_id, options={}
        options[:capture_id] = capture_id if capture_id

        if amount
          options[:amount] = assert_currency options[:currency], amount
        end

        response = flow_instance.refunds.post @flow_organization, options

        if response.try(:id)
          Response.new true, 'Flow refund - Success', { response: response }
        else
          Response.new false, 'Flow refund - Error', { response: response }
        end
      rescue Io::Flow::V0::HttpClient::ServerError => exception
        error_response exception
      end

      # store credit card with flow and get reference token
      def store credit_card, options={}
        response = cc_with_token credit_card
        Response.new true, 'Credit card stored', { response: response, token: response.token }
      rescue Io::Flow::V0::HttpClient::ServerError => exception
        error_response exception
      end

      # stores credit card and returns credit card Flow token String id
      def store input
        credit_card =
        case input
          when Hash
            ActiveMerchant::Billing::CreditCard.new input
          when ActiveMerchant::Billing::CreditCard
            input
          when String
            return input
          else
            raise 'Unsuported store method input type [%s]' % input.class
        end

        data = {    number: credit_card.number,
                      name: '%s %s' % [credit_card.first_name, credit_card.last_name],
                       cvv: credit_card.verification_value,
           expiration_year: credit_card.year.to_i,
          expiration_month: credit_card.month.to_i
        }

        response  = flow_instance.cards.post @flow_organization, data
        response.token
      end

      # Creates and order
      # https://docs.flow.io/module/localization/resource/orders#post-organization-orders
      def flow_create_order body, query_string={}
        flow_instance.orders.post @flow_organization, body, query_string
      rescue => exception
        error_response exception
      end

      # Submits an order and
      # pushes all subsequent authorization from status "review" to "authorized"
      def flow_submission_by_number order_number
        flow_instance.orders.put_submissions_by_number @flow_organization, order_number
      rescue => exception
        error_response exception
      end

      private

      def flow_instance
        FlowCommerce.instance token: @flow_api_key
      end

      def error_response exception_object
        message =
        if exception_object.is_a?(String)
          exception_object
        elsif exception_object.respond_to?(:body) && exception_object.body.length > 0
          description  = JSON.load(exception_object.body)['messages'].to_sentence
          '%s: %s (%s)' % [exception_object.details, description, exception_object.code]
        elsif exception_object.respond_to?(:message)
          exception_object.message
        else
          raise ArgumentError.new('Unsuported exception_object [%s]' % exception_object.class)
        end

        msg = 'ERROR: %s' % message
        msg = msg.yellow if msg.respond_to?(:yellow)

        puts msg

        Response.new false, message, exception: exception_object
      end

      def assert_currency currency, amount
        FlowCommerce::Reference::Currencies.find! currency
        amount.to_f
      end
    end
  end
end
