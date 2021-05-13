#include "SendAck.h"
#include "Timer.h"

module SendAckC @safe() {

  uses {
  	interface Boot;
  	interface Read<uint16_t>;
    interface Timer<TMilli> as Timer;

    // Radio interfaces
    interface Receive;
    interface AMSend;
    interface SplitControl as AMControl;
    interface Packet;
  }

} implementation {

  uint16_t counter = 0;
  message_t packet;

  void sendReq();
  void sendResp();

  //***************** Send request function ********************//
  void sendReq() {
  	/* This function is called when we want to send a request
  	 *
  	 * STEPS:
  	 * 1. Prepare the msg
  	 * 2. Set the ACK flag for the message using the PacketAcknowledgements interface
  	 *     (read the docs)
  	 * 3. Send an UNICAST message to the correct node
  	 * X. Use debug statements showing what's happening (i.e. message fields)
  	 */
    // build message
    msg_t* msg = (msg_t*) call Packet.getPayload(&packet, sizeof(msg_t));
    if (msg == NULL) {
      return;
    }

    // inflate message payload
    msg->msg_type = REQ;
    msg->msg_counter = counter;

    // send message
    call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(msg_t));
    dbg("req", "Sending request\n");
  }

  //****************** Task send response *****************//
  void sendResp() {
     call Read.read();
  }

  //***************** Boot interface ********************//
  event void Boot.booted() {
  	dbg("boot", "Application booted\n");
    call AMControl.start();
  }

  //***************** SplitControl interface ********************//
  event void AMControl.startDone(error_t err) {
    dbg("boot", "Start done: ");

    if (err != SUCCESS) {
      dbg_clear("boot", "ERROR\n");
      call AMControl.start();
    } else {
      dbg_clear("boot", "SUCCESS\n");

      // if node is number 1, also start the timer
      if (TOS_NODE_ID == 1) {
        call Timer.startPeriodic(1000);
        dbg_clear("boot", "\tStarted timer\n");
      }
    }
  }

  event void AMControl.stopDone(error_t err) {
    // skip
  }

  //***************** MilliTimer interface ********************//
  event void Timer.fired() {
    sendReq();
  }

  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf, error_t err) {
	/* This event is triggered when a message is sent
	 *
	 * STEPS:
	 * 1. Check if the packet is sent
	 * 2. Check if the ACK is received (read the docs)
	 * 2a. If yes, stop the timer. The program is done
	 * 2b. Otherwise, send again the request
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
   counter++;
   dbg("radio", "Send done\n");
  }

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf, void* payload, uint8_t len) {
    dbg("radio", "Received message\n");
    if (len == sizeof(msg_t)) {
      msg_t* msg = (msg_t*) payload;
      dbg_clear("radio", "\ttype: %s\n", msg->msg_type == REQ ? "REQ" : "RESP");
      dbg_clear("radio", "\tcounter: %u\n", msg->msg_counter);
      dbg_clear("radio", "\tvalue: %u\n", msg->value);

      if (msg->msg_type == REQ) {
        counter = msg->msg_counter;
        sendResp();
      } else {
        call Timer.stop();
      }
    }
	/* This event is triggered when a message is received
	 *
	 * STEPS:
	 * 1. Read the content of the message
	 * 2. Check if the type is request (REQ)
	 * 3. If a request is received, send the response
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
    return buf;
  }

  //************************* Read interface **********************//
  event void Read.readDone(error_t result, uint16_t data) {
	/* This event is triggered when the fake sensor finish to read (after a Read.read())
	 *
	 * STEPS:
	 * 1. Prepare the response (RESP)
	 * 2. Send back (with a unicast message) the response
	 * X. Use debug statement showing what's happening (i.e. message fields)
	 */
   msg_t* msg = (msg_t*) call Packet.getPayload(&packet, sizeof(msg_t));
   if (msg == NULL) {
     return;
   }

   // inflate message payload
   msg->msg_type = RESP;
   msg->msg_counter = counter;
   msg->value = data;

   // send message
   call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(msg_t));
   dbg("resp", "Sending response \n\tcounter: %u\n\tvalue: %u\n", counter, data);
  }
}
