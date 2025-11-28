<?php

namespace App\Notify;

use App\Notify\NotifyProcess;
use App\Notify\WhatsappGateway;
use App\Notify\Notifiable;

class Whatsapp extends NotifyProcess implements Notifiable{

    /**
    * Mobile number of receiver
    *
    * @var string
    */
	public $mobile;

    /**
    * Assign value to properties
    *
    * @return void
    */
	public function __construct(){
		$this->statusField = 'whatsapp_status';
		$this->body = 'whatsapp_body';
		$this->globalTemplate = 'whatsapp_template'; // We might not need a global template if we just use the body
		$this->notifyConfig = 'whatsapp_config';
	}

    /**
    * Send notification
    *
    * @return void|bool
    */
	public function send(){

        // Check global WhatsApp notification status
        if (!gs('wn')) {
			return false;
		}

        //get message from parent
		$message = $this->getMessage();
		if ($message) {
			try {
                // Currently only supporting Twilio, but structure allows for more
				$gateway = 'twilio'; 
                if($this->mobile){
                    $sendWhatsapp = new WhatsappGateway();
                    $sendWhatsapp->to = $this->mobile;
                    $sendWhatsapp->message = strip_tags($message);
                    $sendWhatsapp->config = gs('whatsapp_config');
                    $sendWhatsapp->$gateway();
                    $this->createLog('whatsapp');
                }
			} catch (\Exception $e) {
				$this->createErrorLog('WhatsApp Error: '.$e->getMessage());
				session()->flash('whatsapp_error','API Error: '.$e->getMessage());
			}
		}

	}

    /**
    * Configure some properties
    *
    * @return void
    */
	public function prevConfiguration(){
		//Check If User
		if ($this->user) {
			$this->mobile = $this->user->mobileNumber;
			$this->receiverName = $this->user->fullname;
		}
		$this->toAddress = $this->mobile;
	}
}
