<?php

namespace App\Notify;

use Twilio\Rest\Client;

class WhatsappGateway{

    /**
     * the number where the whatsapp message will send
     *
     * @var string
     */
    public $to;

    /**
     * the message which will be send
     *
     * @var string
     */
    public $message;

    /**
     * the configuration of whatsapp gateway
     *
     * @var object
     */
    public $config;

	public function twilio(){
		$account_sid = $this->config->account_sid;
		$auth_token = $this->config->auth_token;
		$from_number = $this->config->from_number;

		$client = new Client($account_sid, $auth_token);
		$client->messages->create(
		    'whatsapp:+'.$this->to,
		    array(
		        'from' => 'whatsapp:'.$from_number,
		        'body' => $this->message
		    )
		);
	}
}
