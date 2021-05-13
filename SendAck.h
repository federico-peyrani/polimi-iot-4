#ifndef SENDACK_H
#define SENDACK_H

enum MsgType {
  REQ = 0,
  RESP = 1
};

typedef nx_struct msg {
  nx_uint8_t msg_type;
  nx_uint16_t msg_counter;
  nx_uint16_t value;
} msg_t;

enum {
  AM_MY_MSG = 6,
};

#endif
