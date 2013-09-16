# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Mundipagg do
  let(:mp) { Mundipagg.new }
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
  describe :approve do
    context "merchant key is set" do
      context "without params" do
        let(:approve) { mp.approve({}) }
        it { approve.should be_false }
        context "none" do
          before { approve }
          it { mp.validation_errors.should == [{:field=>:AmountInCents, :message=>:blank}] }
        end
      end
      context "with valid params for AuthOnly", vcr: { cassette_name: 'create-order-authonly-valid' } do
        let(:approve) {
          mp.approve(
            'AmountInCents' => '900',
            'CurrencyIsoEnum' => 'BRL',
            'MerchantKey' => ENV['MUNDIPAGG_MERCHANT_KEY'],
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
        it { approve.should be_true }
        context "none" do
          before { approve }
          it { mp.validation_errors.should be_empty }
          it { mp.transaction.should == 'b1551bae-2ede-4baa-82fc-552489b5be2a' }
          it { mp.instant_buy_key.should == '8c9616ad-ab52-43b1-b048-d83973fe4baf' }
          it { mp.masked_number.should == '123456****3456' }
          it { mp.last_response.should == {:buyer_key=>"00000000-0000-0000-0000-000000000000", :merchant_key=>ENV['MUNDIPAGG_MERCHANT_KEY'], :mundi_pagg_time_in_milliseconds=>"794", :order_key=>"b1551bae-2ede-4baa-82fc-552489b5be2a", :order_reference=>"76c00f54", :order_status_enum=>"Opened", :request_key=>"15e6a28e-2ec3-4337-ad98-5a3b8bee2407", :success=>true, :version=>"1.0", :credit_card_transaction_result_collection=>{:credit_card_transaction_result=>{:acquirer_message=>"Transação de simulação autorizada com sucesso", :acquirer_return_code=>"0", :amount_in_cents=>"900", :authorization_code=>"35353", :authorized_amount_in_cents=>"900", :captured_amount_in_cents=>nil, :credit_card_number=>"123456****3456", :credit_card_operation_enum=>"AuthOnly", :credit_card_transaction_status_enum=>"AuthorizedPendingCapture", :custom_status=>nil, :due_date=>nil, :external_time_in_milliseconds=>"165", :instant_buy_key=>"8c9616ad-ab52-43b1-b048-d83973fe4baf", :refunded_amount_in_cents=>nil, :success=>true, :transaction_identifier=>"388700", :transaction_key=>"79fb5bb4-5cfe-48b5-9c8a-8f1ea1025d3e", :transaction_reference=>"eb2f703c", :unique_sequential_number=>"257", :voided_amount_in_cents=>nil, :original_acquirer_return_collection=>nil}}, :boleto_transaction_result_collection=>nil, :mundi_pagg_suggestion=>nil, :error_report=>nil, :"@xmlns:a"=>"http://schemas.datacontract.org/2004/07/MundiPagg.One.Service.DataContracts", :"@xmlns:i"=>"http://www.w3.org/2001/XMLSchema-instance"} }
          it { mp.error_message.should be_nil }
        end
      end
      context "with valid params for AuthOnly using InstantBuyKey", vcr: { cassette_name: 'create-order-authonly-instantbuy-valid' } do
        let(:approve) {
          mp.approve(
            'AmountInCents' => '900',
            'CurrencyIsoEnum' => 'BRL',
            'MerchantKey' => ENV['MUNDIPAGG_MERCHANT_KEY'],
            'CreditCardTransactionCollection' => {
              'CreditCardTransaction' => [{
                'AmountInCents' => '900',
                'CreditCardBrandEnum' => 'Visa', # Visa, Mastercard, Hipercard, Amex, Diners, Elo
                'CreditCardOperationEnum' => 'AuthOnly', #AuthOnly, AuthAndCapture, AuthAndCaptureWithDelay
                'InstantBuyKey' => '8c9616ad-ab52-43b1-b048-d83973fe4baf',
                'InstallmentCount' => '0', # Número de parcelas da transação.
                'PaymentMethodCode' => '1', # Enviar vazio para transações em produção e “2” para transações em homologação.
              }]
            },
          )
        }
        it { approve.should be_true }
        context "none" do
          before { approve }
          it { mp.validation_errors.should be_empty }
          it { mp.transaction.should == '2ddfe87e-c418-4bdf-8e9a-1a7cce76dcee' }
          it { mp.instant_buy_key.should == '8c9616ad-ab52-43b1-b048-d83973fe4baf' }
          it { mp.masked_number.should == '123456****3456' }
          it { mp.last_response.should == {:buyer_key=>"00000000-0000-0000-0000-000000000000", :merchant_key=>ENV['MUNDIPAGG_MERCHANT_KEY'], :mundi_pagg_time_in_milliseconds=>"773", :order_key=>"2ddfe87e-c418-4bdf-8e9a-1a7cce76dcee", :order_reference=>"109c0a18", :order_status_enum=>"Opened", :request_key=>"23fee4d6-e7b9-4f2f-81e4-15b964efca3c", :success=>true, :version=>"1.0", :credit_card_transaction_result_collection=>{:credit_card_transaction_result=>{:acquirer_message=>"Transação de simulação autorizada com sucesso", :acquirer_return_code=>"0", :amount_in_cents=>"900", :authorization_code=>"615290", :authorized_amount_in_cents=>"900", :captured_amount_in_cents=>nil, :credit_card_number=>"123456****3456", :credit_card_operation_enum=>"AuthOnly", :credit_card_transaction_status_enum=>"AuthorizedPendingCapture", :custom_status=>nil, :due_date=>nil, :external_time_in_milliseconds=>"99", :instant_buy_key=>"8c9616ad-ab52-43b1-b048-d83973fe4baf", :refunded_amount_in_cents=>nil, :success=>true, :transaction_identifier=>"525553", :transaction_key=>"d6c84925-11fe-459d-ba39-550b9cfeb9dc", :transaction_reference=>"f5754e03", :unique_sequential_number=>"861943", :voided_amount_in_cents=>nil, :original_acquirer_return_collection=>nil}}, :boleto_transaction_result_collection=>nil, :mundi_pagg_suggestion=>nil, :error_report=>nil, :"@xmlns:a"=>"http://schemas.datacontract.org/2004/07/MundiPagg.One.Service.DataContracts", :"@xmlns:i"=>"http://www.w3.org/2001/XMLSchema-instance"} }
          it { mp.error_message.should be_nil }
        end
      end
      context "with invalid params for AuthOnly", vcr: { cassette_name: 'create-order-authonly-invalid' } do
        let(:approve) {
          mp.approve(
            'AmountInCents' => '900',
            'CurrencyIsoEnum' => 'BRL',
            'MerchantKey' => ENV['MUNDIPAGG_MERCHANT_KEY'],
            'CreditCardTransactionCollection' => {
              'CreditCardTransaction' => [{
                'AmountInCents' => '900',
                'CreditCardBrandEnum' => 'Visa', # Visa, Mastercard, Hipercard, Amex, Diners, Elo
                'CreditCardNumber' => '999999999',
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
        it { approve.should be_false }
        context "none" do
          before { approve }
          it { mp.validation_errors.should be_empty }
          it { mp.transaction.should be_nil }
          it { mp.instant_buy_key.should be_nil }
          it { mp.masked_number.should be_nil }
          it { mp.last_response.should == {:buyer_key=>"00000000-0000-0000-0000-000000000000", :merchant_key=>ENV['MUNDIPAGG_MERCHANT_KEY'], :mundi_pagg_time_in_milliseconds=>"137", :order_key=>"00000000-0000-0000-0000-000000000000", :order_reference=>nil, :order_status_enum=>"WithError", :request_key=>"057d4ec3-f0b1-4695-b384-d68bf42849ad", :success=>false, :version=>"1.0", :credit_card_transaction_result_collection=>nil, :boleto_transaction_result_collection=>nil, :mundi_pagg_suggestion=>nil, :error_report=>{:category=>"RequestError", :error_item_collection=>{:error_item=>{:description=>"O número do cartão deve ter no mínimo 10 dígitos e no máximo 24 digitos.", :error_code=>"400", :error_field=>"CreditCardTransactionRequest.CreditCardNumber", :severity_code_enum=>"Error"}}}, :"@xmlns:a"=>"http://schemas.datacontract.org/2004/07/MundiPagg.One.Service.DataContracts", :"@xmlns:i"=>"http://www.w3.org/2001/XMLSchema-instance"} }
          it { mp.error_message.should == "{:category=>\"RequestError\", :error_item_collection=>{:error_item=>{:description=>\"O número do cartão deve ter no mínimo 10 dígitos e no máximo 24 digitos.\", :error_code=>\"400\", :error_field=>\"CreditCardTransactionRequest.CreditCardNumber\", :severity_code_enum=>\"Error\"}}}" }
        end
      end
      context "with invalid params for AuthOnly using InstanBuyKey", vcr: { cassette_name: 'create-order-authonly-instantbuy-invalid' } do
        let(:approve) {
          mp.approve(
            'AmountInCents' => '900',
            'CurrencyIsoEnum' => 'BRL',
            'MerchantKey' => ENV['MUNDIPAGG_MERCHANT_KEY'],
            'CreditCardTransactionCollection' => {
              'CreditCardTransaction' => [{
                'AmountInCents' => '900',
                'CreditCardBrandEnum' => 'Visa', # Visa, Mastercard, Hipercard, Amex, Diners, Elo
                'InstantBuyKey' => '99999999-9999-9999-9999-999999999999',
                'InstallmentCount' => '0', # Número de parcelas da transação.
                'PaymentMethodCode' => '1', # Enviar vazio para transações em produção e “2” para transações em homologação.
              }]
            },
          )
        }
        it { approve.should be_false }
        context "none" do
          before { approve }
          it { mp.validation_errors.should be_empty }
          it { mp.transaction.should be_nil }
          it { mp.instant_buy_key.should be_nil }
          it { mp.masked_number.should be_nil }
          it { mp.last_response.should == {:buyer_key=>"00000000-0000-0000-0000-000000000000", :merchant_key=>ENV['MUNDIPAGG_MERCHANT_KEY'], :mundi_pagg_time_in_milliseconds=>"136", :order_key=>"00000000-0000-0000-0000-000000000000", :order_reference=>nil, :order_status_enum=>"WithError", :request_key=>"2ddfeff7-13be-4360-87b0-c62b6fefc614", :success=>false, :version=>"1.0", :credit_card_transaction_result_collection=>nil, :boleto_transaction_result_collection=>nil, :mundi_pagg_suggestion=>nil, :error_report=>{:category=>"RequestError", :error_item_collection=>{:error_item=>{:description=>"A chave de compra não é válida.", :error_code=>"400", :error_field=>"CreditCardTransactionRequest.InstantBuyKey", :severity_code_enum=>"Error"}}}, :"@xmlns:a"=>"http://schemas.datacontract.org/2004/07/MundiPagg.One.Service.DataContracts", :"@xmlns:i"=>"http://www.w3.org/2001/XMLSchema-instance"} }
          it { mp.error_message.should == "{:category=>\"RequestError\", :error_item_collection=>{:error_item=>{:description=>\"A chave de compra não é válida.\", :error_code=>\"400\", :error_field=>\"CreditCardTransactionRequest.InstantBuyKey\", :severity_code_enum=>\"Error\"}}}" }
        end
      end
    end
  end
  describe :confirm do
    context "without params" do
      let(:confirm) { mp.confirm({}) }
      it { confirm.should be_false }
      context "none" do
        before { confirm }
        it { mp.validation_errors.should == [{:field=>:OrderKey, :message=>:blank}, {:field=>:ManageOrderOperationEnum, :message=>:blank}] }
      end
    end
    context "with valid params for Capture", vcr: { cassette_name: 'manage-order-capture-valid' } do
      let(:confirm) {
        mp.confirm(
          'ManageOrderOperationEnum' => 'Capture',
          'MerchantKey' => ENV['MUNDIPAGG_MERCHANT_KEY'],
          'OrderKey' => 'b1551bae-2ede-4baa-82fc-552489b5be2a',
        )
      }
      it { confirm.should be_true }
      context "none" do
        before { confirm }
        it { mp.validation_errors.should be_empty }
        it { mp.last_response.should == {:manage_order_operation_enum=>"Capture", :mundi_pagg_time_in_milliseconds=>"137", :order_key=>"b1551bae-2ede-4baa-82fc-552489b5be2a", :order_reference=>nil, :order_status_enum=>"Paid", :request_key=>"fc42fd3c-601c-4c0f-9a4e-c0e45ae5d928", :success=>true, :version=>"1.0", :credit_card_transaction_result_collection=>{:credit_card_transaction_result=>{:acquirer_message=>"Transação de simulação capturada com sucesso", :acquirer_return_code=>"0", :amount_in_cents=>"900", :authorization_code=>"35353", :authorized_amount_in_cents=>"900", :captured_amount_in_cents=>"900", :credit_card_number=>"123456****3456", :credit_card_operation_enum=>"AuthOnly", :credit_card_transaction_status_enum=>"Captured", :custom_status=>nil, :due_date=>nil, :external_time_in_milliseconds=>"192", :instant_buy_key=>"8c9616ad-ab52-43b1-b048-d83973fe4baf", :refunded_amount_in_cents=>nil, :success=>true, :transaction_identifier=>"865865", :transaction_key=>"79fb5bb4-5cfe-48b5-9c8a-8f1ea1025d3e", :transaction_reference=>"eb2f703c", :unique_sequential_number=>"551865", :voided_amount_in_cents=>nil, :original_acquirer_return_collection=>nil}}, :boleto_transaction_result_collection=>nil, :mundi_pagg_suggestion=>nil, :error_report=>nil, :"@xmlns:a"=>"http://schemas.datacontract.org/2004/07/MundiPagg.One.Service.DataContracts", :"@xmlns:i"=>"http://www.w3.org/2001/XMLSchema-instance"} }
        it { mp.error_message.should be_nil }
      end
    end
  end
  describe :create_order do
    context "without params" do
      let(:create_order) { mp.create_order({}) }
      it { create_order.should be_false }
      context "none" do
        before { create_order }
        it { mp.validation_errors.should == [{:field=>:AmountInCents, :message=>:blank}] }
      end
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
      it { create_order.should == {:buyer_key=>"00000000-0000-0000-0000-000000000000", :merchant_key=>ENV['MUNDIPAGG_MERCHANT_KEY'], :mundi_pagg_time_in_milliseconds=>"794", :order_key=>"b1551bae-2ede-4baa-82fc-552489b5be2a", :order_reference=>"76c00f54", :order_status_enum=>"Opened", :request_key=>"15e6a28e-2ec3-4337-ad98-5a3b8bee2407", :success=>true, :version=>"1.0", :credit_card_transaction_result_collection=>{:credit_card_transaction_result=>{:acquirer_message=>"Transação de simulação autorizada com sucesso", :acquirer_return_code=>"0", :amount_in_cents=>"900", :authorization_code=>"35353", :authorized_amount_in_cents=>"900", :captured_amount_in_cents=>nil, :credit_card_number=>"123456****3456", :credit_card_operation_enum=>"AuthOnly", :credit_card_transaction_status_enum=>"AuthorizedPendingCapture", :custom_status=>nil, :due_date=>nil, :external_time_in_milliseconds=>"165", :instant_buy_key=>"8c9616ad-ab52-43b1-b048-d83973fe4baf", :refunded_amount_in_cents=>nil, :success=>true, :transaction_identifier=>"388700", :transaction_key=>"79fb5bb4-5cfe-48b5-9c8a-8f1ea1025d3e", :transaction_reference=>"eb2f703c", :unique_sequential_number=>"257", :voided_amount_in_cents=>nil, :original_acquirer_return_collection=>nil}}, :boleto_transaction_result_collection=>nil, :mundi_pagg_suggestion=>nil, :error_report=>nil, :"@xmlns:a"=>"http://schemas.datacontract.org/2004/07/MundiPagg.One.Service.DataContracts", :"@xmlns:i"=>"http://www.w3.org/2001/XMLSchema-instance"} }
    end
    context "with valid params for AuthAndCapture", vcr: { cassette_name: 'create-order-authandcapture-valid' } do
      let(:create_order) {
        mp.create_order(
          'AmountInCents' => '900',
          'CurrencyIsoEnum' => 'BRL',
          'MerchantKey' => ENV['MUNDIPAGG_MERCHANT_KEY'],
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
      it { create_order.should == {:buyer_key=>"00000000-0000-0000-0000-000000000000", :merchant_key=>ENV['MUNDIPAGG_MERCHANT_KEY'], :mundi_pagg_time_in_milliseconds=>"854", :order_key=>"ee0ce803-9e41-4535-977d-2d8f0e8045fa", :order_reference=>"188c6ae1", :order_status_enum=>"Paid", :request_key=>"ba04919c-f819-41aa-be9e-f43baf7137d6", :success=>true, :version=>"1.0", :credit_card_transaction_result_collection=>{:credit_card_transaction_result=>{:acquirer_message=>"Transação de simulação autorizada com sucesso", :acquirer_return_code=>"0", :amount_in_cents=>"900", :authorization_code=>"907227", :authorized_amount_in_cents=>"900", :captured_amount_in_cents=>"900", :credit_card_number=>"123456****3456", :credit_card_operation_enum=>"AuthAndCapture", :credit_card_transaction_status_enum=>"Captured", :custom_status=>nil, :due_date=>nil, :external_time_in_milliseconds=>"149", :instant_buy_key=>"8c9616ad-ab52-43b1-b048-d83973fe4baf", :refunded_amount_in_cents=>nil, :success=>true, :transaction_identifier=>"870430", :transaction_key=>"9b8ecfa8-1208-4878-b890-a97bb269be84", :transaction_reference=>"0dfb6300", :unique_sequential_number=>"698921", :voided_amount_in_cents=>nil, :original_acquirer_return_collection=>nil}}, :boleto_transaction_result_collection=>nil, :mundi_pagg_suggestion=>nil, :error_report=>nil, :"@xmlns:a"=>"http://schemas.datacontract.org/2004/07/MundiPagg.One.Service.DataContracts", :"@xmlns:i"=>"http://www.w3.org/2001/XMLSchema-instance"} }
    end
  end
  describe :manage_order do
    context "without params" do
      let(:manage_order) { mp.manage_order({}) }
      it { manage_order.should be_false }
      context "none" do
        before { manage_order }
        it { mp.validation_errors.should == [{:field=>:OrderKey, :message=>:blank}, {:field=>:ManageOrderOperationEnum, :message=>:blank}] }
      end
    end
    context "with invalid params", vcr: { cassette_name: 'manage-order-invalid' } do
      let(:manage_order) {
        mp.manage_order(
          'ManageOrderOperationEnum' => 'Void',
          'OrderKey' => '99999999-9999-9999-9999-999999999999',
          'MerchantKey' => ENV['MUNDIPAGG_MERCHANT_KEY'],
        )
      }
      it { manage_order.should == {:manage_order_operation_enum=>"Void", :mundi_pagg_time_in_milliseconds=>nil, :order_key=>"99999999-9999-9999-9999-999999999999", :order_reference=>nil, :order_status_enum=>"WithError", :request_key=>"485495b0-d9fa-4ff7-bbd3-1fc2d2befd46", :success=>false, :version=>"1.0", :credit_card_transaction_result_collection=>nil, :boleto_transaction_result_collection=>nil, :mundi_pagg_suggestion=>nil, :error_report=>{:category=>"RequestError", :error_item_collection=>{:error_item=>{:description=>"Chave de loja inválida: '00000000-0000-0000-0000-000000000000'", :error_code=>"400", :error_field=>"ManageOrderRequest.MerchantKey", :severity_code_enum=>"Error"}}}, :"@xmlns:a"=>"http://schemas.datacontract.org/2004/07/MundiPagg.One.Service.DataContracts", :"@xmlns:i"=>"http://www.w3.org/2001/XMLSchema-instance"} }
    end
    context "with valid params for Capture", vcr: { cassette_name: 'manage-order-capture-valid' } do
      let(:manage_order) {
        mp.manage_order(
          'ManageOrderOperationEnum' => 'Capture',
          'MerchantKey' => ENV['MUNDIPAGG_MERCHANT_KEY'],
          'OrderKey' => 'b1551bae-2ede-4baa-82fc-552489b5be2a',
        )
      }
      it { manage_order.should == {:manage_order_operation_enum=>"Capture", :mundi_pagg_time_in_milliseconds=>"137", :order_key=>"b1551bae-2ede-4baa-82fc-552489b5be2a", :order_reference=>nil, :order_status_enum=>"Paid", :request_key=>"fc42fd3c-601c-4c0f-9a4e-c0e45ae5d928", :success=>true, :version=>"1.0", :credit_card_transaction_result_collection=>{:credit_card_transaction_result=>{:acquirer_message=>"Transação de simulação capturada com sucesso", :acquirer_return_code=>"0", :amount_in_cents=>"900", :authorization_code=>"35353", :authorized_amount_in_cents=>"900", :captured_amount_in_cents=>"900", :credit_card_number=>"123456****3456", :credit_card_operation_enum=>"AuthOnly", :credit_card_transaction_status_enum=>"Captured", :custom_status=>nil, :due_date=>nil, :external_time_in_milliseconds=>"192", :instant_buy_key=>"8c9616ad-ab52-43b1-b048-d83973fe4baf", :refunded_amount_in_cents=>nil, :success=>true, :transaction_identifier=>"865865", :transaction_key=>"79fb5bb4-5cfe-48b5-9c8a-8f1ea1025d3e", :transaction_reference=>"eb2f703c", :unique_sequential_number=>"551865", :voided_amount_in_cents=>nil, :original_acquirer_return_collection=>nil}}, :boleto_transaction_result_collection=>nil, :mundi_pagg_suggestion=>nil, :error_report=>nil, :"@xmlns:a"=>"http://schemas.datacontract.org/2004/07/MundiPagg.One.Service.DataContracts", :"@xmlns:i"=>"http://www.w3.org/2001/XMLSchema-instance"} }
    end
  end
end