<?php
header('Content-Type: text/html; charset=UTF-8');
set_time_limit(0);
$url = "https://transaction.mundipaggone.com/MundiPaggService.svc?wsdl";

//$url = "https://mundipaggoneversiontest.cloudapp.net/v2/MundiPaggService.svc?wsdl";

//$url = "https://staging.mundipaggone.com/MundiPaggService.svc?wsdl";

//Colocar a chave da sua loja aqui
$key = "";

$soap_opt['encoding']    = 'UTF-8';
$soap_opt['trace']       = true;
$soap_opt['exceptions']  = true;

$soap_client = new SoapClient( $url, $soap_opt );

//Informations about the order
$_request["createOrderRequest"]["OrderReference"] ="TESTESERVICOPHP"; // Identificação do pedido na loja
$_request["createOrderRequest"]["AmountInCents"] = "9"; // Order amount in cents
$_request["createOrderRequest"]["AmountInCentsToConsiderPaid"] = "0"; // Order amount in cents to consider paid
$_request["createOrderRequest"]["EmailUpdateToBuyerEnum"] = "No"; // Send notification email to the buyer: Yes | No | YesIfAuthorized | YesIfNotAuthorized
$_request["createOrderRequest"]["CurrencyIsoEnum"] = "BRL"; //Order currency

//Credit card transaction data
$_request["createOrderRequest"]["CreditCardTransactionCollection"]["CreditCardTransaction"][0]["AmountInCents"] = "100"; // Transaction amount
$_request["createOrderRequest"]["CreditCardTransactionCollection"]["CreditCardTransaction"][0]["CreditCardNumber"] = "5212701315496781";
$_request["createOrderRequest"]["CreditCardTransactionCollection"]["CreditCardTransaction"][0]["InstallmentCount"] = "0";
$_request["createOrderRequest"]["CreditCardTransactionCollection"]["CreditCardTransaction"][0]["HolderName"] = "Carlos Teste";
$_request["createOrderRequest"]["CreditCardTransactionCollection"]["CreditCardTransaction"][0]["SecurityCode"] = "081"; // Credit card security code
$_request["createOrderRequest"]["CreditCardTransactionCollection"]["CreditCardTransaction"][0]["ExpMonth"] = "09";
$_request["createOrderRequest"]["CreditCardTransactionCollection"]["CreditCardTransaction"][0]["ExpYear"] = "14";
$_request["createOrderRequest"]["CreditCardTransactionCollection"]["CreditCardTransaction"][0]["CreditCardBrandEnum"] = "Mastercard";
$_request["createOrderRequest"]["CreditCardTransactionCollection"]["CreditCardTransaction"][0]["CreditCardOperationEnum"] = "AuthOnly"; /** Transaction type: AuthOnly | AuthAndCapture | AuthAndCaptureWithDelay  */
// PaymentMethodCode padrão para executar no simulador da MundiPagg
$_request["createOrderRequest"]["CreditCardTransactionCollection"]["CreditCardTransaction"][0]["PaymentMethodCode"] = "2"; // Payment method code 

$_request["createOrderRequest"]["MerchantKey"] = $key; 

	//Realiza a comunicação com o WebService
	try{
			//Envia os dados para o serviço da MundiPagg
			$_response = $soap_client->CreateOrder($_request); 
			
			//Verifica se ocorreu algum erro na solicitação
			if($_response->CreateOrderResult->ErrorReport != null){
				//Caso tenha ocorrido algum erro exibo na tela o erro que ocorreu
				$_errorItemCollection = $_response->CreateOrderResult->ErrorReport->ErrorItemCollection;
				foreach($_errorItemCollection as $errorItem){
				 echo $errorItem->Description;
				}
				exit;
			}
			
			if($_response->CreateOrderResult->Success == true){
				$resultado = "Pedido realizado com sucesso";
			}else{
				$resultado = "Pedido não realizado" ;
			}
			//Exibe o  resultado do pedido que foi solicitado
			echo UTF8_Encode($resultado);
			
			//Obtenho a coleção de transações realizadas
			$creditCardTransactionResultCollection = $_response->CreateOrderResult->CreditCardTransactionResultCollection;
			// Exibe o resultado das transações
			foreach($creditCardTransactionResultCollection as $creditCardTransactionResult){
				$resultado = "</br>Transaction Key : ".$creditCardTransactionResult->TransactionKey ;
				$resultado = $resultado . "</br>Status da transação : ".$creditCardTransactionResult->CreditCardTransactionStatusEnum;
				$resultado = $resultado . "</br>Valor autorizado : ".$creditCardTransactionResult->AuthorizedAmountInCents;
				$resultado = $resultado . "</br>Numero Cartão : ".$creditCardTransactionResult->CreditCardNumber;
				echo UTF8_Encode("</br>".$resultado);
			}
	}

	catch( Exception $e )
	{
		echo $e->getMessage();exit;
	}
?>