# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Mundipagg do
  describe "initialize" do
    describe "environment" do
      context "RACK_ENV is NOT set" do
        before { ENV['RACK_ENV'] = nil }
        it { Mundipagg.new(environment: 'production').instance_variable_get(:@environment).should == 'production' }
        it { Mundipagg.new.instance_variable_get(:@environment).should == 'test' }
      end
      context "RACK_ENV is set" do
        before { ENV['RACK_ENV'] = 'staging' }
        it { Mundipagg.new(environment: 'production').instance_variable_get(:@environment).should == 'production' }
        it { Mundipagg.new.instance_variable_get(:@environment).should == 'staging' }
      end
    end
    describe "merchant_key" do
      after {
        ENV['MUNDIPAGG_MERCHANT_KEY'] = nil
        Dotenv.load
      }
      context "MUNDIPAGG_MERCHANT_KEY is NOT set" do
        before { ENV['MUNDIPAGG_MERCHANT_KEY'] = nil }
        it { Mundipagg.new(merchant_key: 'mundipagg-key').instance_variable_get(:@merchant_key).should == 'mundipagg-key' }
        it { Mundipagg.new.instance_variable_get(:@merchant_key).should == nil }
      end
      context "MUNDIPAGG_MERCHANT_KEY is set" do
        before { ENV['MUNDIPAGG_MERCHANT_KEY'] = 'chave-do-ambiente' }
        it { Mundipagg.new(merchant_key: 'mundipagg-key').instance_variable_get(:@merchant_key).should == 'mundipagg-key' }
        it { Mundipagg.new.instance_variable_get(:@merchant_key).should == 'chave-do-ambiente' }
      end
    end
  end
  describe "client", vcr: { cassette_name: 'client' } do
    let(:client) { Mundipagg.new.client }
    subject { client }
    its(:service_name) { should == "MundiPaggService" }
  end
  describe :create_order do
    let(:mp) { Mundipagg.new }
    context "merchant key not set" do
      before { ENV['MUNDIPAGG_MERCHANT_KEY'] = nil }
      it {
        expect {
          mp.create_order
        }.to raise_exception(RuntimeError, "MerchantKey not configured. Set the environment variable MUNDIPAGG_MERCHANT_KEY or pass on initialization, ex: MundiPagg.new(merchant_key: 'key').")
      }
    end
    context "merchant key is set" do
      before { Dotenv.load }
      let(:mp) { Mundipagg.new }
      context "without params" do
        let!(:create_order) { mp.create_order }
        it { create_order.should be_false }
        it { mp.errors.should == [{:field=>:AmountInCents, :message=>:blank}] }
      end
      context "with incomplete params", vcr: { cassette_name: 'create-order-incomplete' } do
        let(:create_order) { mp.create_order(AmountInCents: 900) }
        it { create_order.should be_false }
      end
      context "with valid params for AuthOnly", vcr: { cassette_name: 'create-order-authonly-valid' } do
        let(:create_order) {
          mp.create_order(
            'AmountInCents' => '900',
            'CurrencyIsoEnum' => 'BRL',
            'MerchantKey' => ENV['MUNDIPAGG_MERCHANT_KEY'],
            'OrderReference' => 'TESTESERVICO',
            'CreditCardTransactionCollection' => {
              'CreditCardTransaction' => [{
                'AmountInCents' => '900',
                'CreditCardBrandEnum' => 'Visa', # Visa, Mastercard, Hipercard, Amex, Diners, Elo
                'CreditCardNumber' => '1234567890123456',
                'CreditCardOperationEnum' => 'AuthOnly', #AuthOnly, AuthAndCapture, AuthAndCaptureWithDelay
                'ExpMonth' => '10',
                'ExpYear' => '17',
                'HolderName' => 'Rafael Lima',
                'InstallmentCount' => '0', # Número de parcelas da transação.
                'PaymentMethodCode' => '1', # Enviar vazio para transações em produção e “2” para transações em homologação.
                'SecurityCode' => '123',
              }]
            },
          )
        }
        it { create_order.should == {:buyer_key=>"00000000-0000-0000-0000-000000000000", :merchant_key=>ENV['MUNDIPAGG_MERCHANT_KEY'], :mundi_pagg_time_in_milliseconds=>"839", :order_key=>"3937979d-6efa-45ff-8e9d-f640c5d4a763", :order_reference=>"TESTESERVICO", :order_status_enum=>"Opened", :request_key=>"d981f7d0-2772-4f5f-86b7-51c064760a52", :success=>true, :version=>"1.0", :credit_card_transaction_result_collection=>{:credit_card_transaction_result=>{:acquirer_message=>"Transação de simulação autorizada com sucesso", :acquirer_return_code=>"0", :amount_in_cents=>"900", :authorization_code=>"829917", :authorized_amount_in_cents=>"900", :captured_amount_in_cents=>nil, :credit_card_number=>"123456****3456", :credit_card_operation_enum=>"AuthOnly", :credit_card_transaction_status_enum=>"AuthorizedPendingCapture", :custom_status=>nil, :due_date=>nil, :external_time_in_milliseconds=>"81", :instant_buy_key=>"8c9616ad-ab52-43b1-b048-d83973fe4baf", :refunded_amount_in_cents=>nil, :success=>true, :transaction_identifier=>"34037", :transaction_key=>"a5dcfdec-6ed6-4d7e-8b79-30b1dbf44900", :transaction_reference=>"86710d6a", :unique_sequential_number=>"917669", :voided_amount_in_cents=>nil, :original_acquirer_return_collection=>nil}}, :boleto_transaction_result_collection=>nil, :mundi_pagg_suggestion=>nil, :error_report=>nil, :"@xmlns:a"=>"http://schemas.datacontract.org/2004/07/MundiPagg.One.Service.DataContracts", :"@xmlns:i"=>"http://www.w3.org/2001/XMLSchema-instance"} }
        context "after create order" do
          before { create_order }
          it { mp.errors.should == [] }
        end
      end
      context "with valid params for AuthAndCapture", vcr: { cassette_name: 'create-order-authandcapture-valid' } do
        let(:create_order) {
          mp.create_order(
            'AmountInCents' => '900',
            'CurrencyIsoEnum' => 'BRL',
            'MerchantKey' => ENV['MUNDIPAGG_MERCHANT_KEY'],
            'OrderReference' => 'TESTESERVICO',
            'CreditCardTransactionCollection' => {
              'CreditCardTransaction' => [{
                'AmountInCents' => '900',
                'CreditCardBrandEnum' => 'Visa', # Visa, Mastercard, Hipercard, Amex, Diners, Elo
                'CreditCardNumber' => '1234567890123456',
                'CreditCardOperationEnum' => 'AuthAndCapture', #AuthOnly, AuthAndCapture, AuthAndCaptureWithDelay
                'ExpMonth' => '10',
                'ExpYear' => '17',
                'HolderName' => 'Rafael Lima',
                'InstallmentCount' => '0', # Número de parcelas da transação.
                'PaymentMethodCode' => '1', # Enviar vazio para transações em produção e “2” para transações em homologação.
                'SecurityCode' => '123',
              }]
            },
          )
        }
        it { create_order.should == {:buyer_key=>"00000000-0000-0000-0000-000000000000", :merchant_key=>ENV['MUNDIPAGG_MERCHANT_KEY'], :mundi_pagg_time_in_milliseconds=>"5518", :order_key=>"2aaf59c9-7832-4687-a499-9d613b0bedf8", :order_reference=>"TESTESERVICO", :order_status_enum=>"Paid", :request_key=>"9935b619-f7e9-457b-b86a-c1edf5b249e9", :success=>true, :version=>"1.0", :credit_card_transaction_result_collection=>{:credit_card_transaction_result=>{:acquirer_message=>"Transação de simulação autorizada com sucesso", :acquirer_return_code=>"0", :amount_in_cents=>"900", :authorization_code=>"330366", :authorized_amount_in_cents=>"900", :captured_amount_in_cents=>"900", :credit_card_number=>"123456****3456", :credit_card_operation_enum=>"AuthAndCapture", :credit_card_transaction_status_enum=>"Captured", :custom_status=>nil, :due_date=>nil, :external_time_in_milliseconds=>"90", :instant_buy_key=>"8c9616ad-ab52-43b1-b048-d83973fe4baf", :refunded_amount_in_cents=>nil, :success=>true, :transaction_identifier=>"877791", :transaction_key=>"937f36c9-1199-4925-99e0-5d50eba5e484", :transaction_reference=>"ff8a49d1", :unique_sequential_number=>"454484", :voided_amount_in_cents=>nil, :original_acquirer_return_collection=>nil}}, :boleto_transaction_result_collection=>nil, :mundi_pagg_suggestion=>nil, :error_report=>nil, :"@xmlns:a"=>"http://schemas.datacontract.org/2004/07/MundiPagg.One.Service.DataContracts", :"@xmlns:i"=>"http://www.w3.org/2001/XMLSchema-instance"} }
        context "after create order" do
          before { create_order }
          it { mp.errors.should == [] }
        end
      end
    end
  end
end