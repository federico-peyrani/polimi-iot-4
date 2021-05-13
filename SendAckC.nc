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

    interface PacketAcknowledgements;
  }

} implementation {

  /** Global counter incremented after each outgoing message. */
  uint16_t counter = 0;

  /**
   * Counter used to store the received counter value in an incoming message,
   * so that it can be relayed back in a RESP message. Kept separate from
   * [counter] so that nodes could theoretically both send and receive REQ and
   * RESP messagge with the same underlying policy.
   */
  uint16_t received_counter = 0;

  message_t packet;

  /**
   * Sends a standard message of type msg_t (defined in SendAck.h), inflating
   * its content with the provided parameters, always requiring an ACK to be
   * sent back, and automatically routing the packet to the other node in the
   * network (i.e. 1 --> 2 and 2 --> 1).
   */
  void send(uint8_t msg_type, uint16_t counter_value, nx_uint16_t value) {
    msg_t* msg;
    am_addr_t addr;

    // build message
    msg = (msg_t*) call Packet.getPayload(&packet, sizeof(msg_t));
    if (msg == NULL) {
      return;
    }

    // inflate message payload
    msg->msg_type = msg_type;
    msg->msg_counter = counter_value;
    msg->value = value;

    call PacketAcknowledgements.requestAck(&packet);

    // Send message in unicast, using TOS_NODE_ID to retrieve the destination
    // address. Using a switch statement makes it more suited to do more complex
    // routing if motes where to be added to the network.
    switch (TOS_NODE_ID) {
      case 1:
        addr = 2;
        break;
      case 2:
        addr = 1;
        break;
    }

    call AMSend.send(addr, &packet, sizeof(msg_t));
  }

  void sendReq() {
    send(REQ, counter, 0);
    dbg("req", "Sending request\n");
  }

  void sendResp() {
    call Read.read();
    dbg("resp", "Reading sensor value\n");
  }

  event void Boot.booted() {
  	dbg("boot", "Application booted\n");
    call AMControl.start();
  }

  event void Read.readDone(error_t result, uint16_t data) {
    send(RESP, received_counter, data);
    dbg("resp", "Sending response \n\tcounter: %u\n\tvalue: %u\n", counter, data);
  }

  event void AMControl.startDone(error_t err) {
    dbg("boot", "Start done: ");

    if (err != SUCCESS) {
      dbg_clear("boot", "ERROR\n");
      call AMControl.start();
      return;
    }

    dbg_clear("boot", "SUCCESS\n");

    // if node is number 1, also start the timer
    if (TOS_NODE_ID == 1) {
      call Timer.startPeriodic(1000);
      dbg_clear("boot", "\tStarted timer\n");
    }
  }

  event void AMControl.stopDone(error_t err) {
    // skip
  }

  event void Timer.fired() {
    sendReq();
  }

  event void AMSend.sendDone(message_t* buf, error_t err) {
    bool acked;

    acked = call PacketAcknowledgements.wasAcked(buf);

    dbg("radio", "Send done\n");
    dbg_clear("radio", "\t%s\n", acked ? "Acked" : "Not acked");

    if (acked && call Timer.isRunning()) {
      dbg_clear("radio", "\tStopping timer\n");
      call Timer.stop();
    }

    // increment the counter at each sent message
    counter++;
  }

  event message_t* Receive.receive(message_t* buf, void* payload, uint8_t len) {
    dbg("radio", "Received message\n");

    if (len == sizeof(msg_t)) {
      msg_t* msg = (msg_t*) payload;

      // print debug info about the message
      dbg_clear("radio", "\ttype: %s\n", msg->msg_type == REQ ? "REQ" : "RESP");
      dbg_clear("radio", "\tcounter: %u\n", msg->msg_counter);
      dbg_clear("radio", "\tvalue: %u\n", msg->value);

      if (msg->msg_type == REQ) {
        received_counter = msg->msg_counter;
        sendResp();
      }
    }

    return buf;
  }
}
