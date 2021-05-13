/**
 *  Configuration file for wiring of sendAckC module to other common
 *  components needed for proper functioning
 *
 *  @author Luca Pietro Borsani
 */

#include "SendAck.h"

configuration SendAckAppC {}

implementation {

  components MainC, SendAckC as App;
  components new FakeSensorC();
  components new TimerMilliC() as Timer;

  // Radio components
  components new AMSenderC(AM_MY_MSG);
  components new AMReceiverC(AM_MY_MSG);
  components ActiveMessageC;

  App.Boot -> MainC.Boot;
  App.Read -> FakeSensorC;
  App.Timer -> Timer;

  // Radio wiring
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.Packet -> AMSenderC;

  App.PacketAcknowledgements -> ActiveMessageC;
}
