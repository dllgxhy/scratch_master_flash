#include "CFunIR.h"
// Provides ISR
#include <avr/interrupt.h>
uint8_t _ir_flag_a;
uint8_t _ir_flag_b;
uint8_t _ir_pin;
uint8_t _irRead;
volatile irparams_t irparams;
bool MATCH(uint8_t measured_ticks, uint8_t desired_us)
{
  // Serial.print(measured_ticks);Serial.print(",");Serial.println(desired_us);
  return (measured_ticks >= desired_us - (desired_us >> 2) - 1 && measured_ticks <= desired_us + (desired_us >> 2) + 1); //判断前后25%的误差
}

ISR(TIMER_INTR_NAME)
{
  uint8_t irdata = (uint8_t)digitalRead(_ir_pin);
  // uint32_t new_time = micros();
  // uint8_t timer = (new_time - irparams.lastTime)>>6;
  irparams.timer++; // One more 50us tick
  if (irparams.rawlen >= RAWBUF) {
    // Buffer overflow
    irparams.rcvstate = STATE_STOP;
  }
  switch (irparams.rcvstate) {
    case STATE_IDLE: // In the middle of a gap
      if (irdata == MARK) {
        irparams.rawlen = 0;
        irparams.timer = 0;
        irparams.rcvstate = STATE_MARK;
      }
      break;
    case STATE_MARK: // timing MARK
      if (irdata == SPACE) {   // MARK ended, record time
        irparams.rawbuf[irparams.rawlen++] = irparams.timer;
        irparams.timer = 0;
        irparams.rcvstate = STATE_SPACE;
      }
      break;
    case STATE_SPACE: // timing SPACE
      if (irdata == MARK) { // SPACE just ended, record it
        irparams.rawbuf[irparams.rawlen++] = irparams.timer;
        irparams.timer = 0;
        irparams.rcvstate = STATE_MARK;
      }
      else { // SPACE
        if (irparams.timer > GAP_TICKS) {
          // big SPACE, indicates gap between codes
          // Mark current code as ready for processing
          // Switch to STOP
          // Don't reset timer; keep counting space width
          irparams.rcvstate = STATE_STOP;
        }
      }
      break;
    case STATE_STOP: // waiting, measuring gap
      if (irdata == MARK) { // reset gap timer
        irparams.timer = 0;
      }
      break;
  }
  // irparams.lastTime = new_time;
}

CFunIR::CFunIR()
{
  
}

CFunIR::CFunIR(uint8_t pin)
{
  _ir_pin=pin;
}

void CFunIR::begin(uint8_t pin)
{
  _ir_pin=pin;
  pinMode(_ir_pin, INPUT);
 // _buzz_ir = 1;
  cli();
  // setup pulse clock timer interrupt
  //Prescale /8 (16M/8 = 0.5 microseconds per tick)
  // Therefore, the timer interval can range from 0.5 to 128 microseconds
  // depending on the reset value (255 to 0)
  TIMER_CONFIG_NORMAL();

  //Timer2 Overflow Interrupt Enable
  TIMER_ENABLE_INTR;

  // TIMER_RESET;

  sei();  // enable interrupts

  // initialize state machine variables
  irparams.rcvstate = STATE_IDLE;
  irparams.rawlen = 0;

  lastIRTime = 0.0;
  irDelay = 0;
  irIndex = 0;
  irRead = 0;
  irReady = false;
  irBuffer = "";
  irPressed = false;

}

void CFunIR::end() {
  EIMSK &= ~(1 << INT0);
}




// Decodes the received IR message
// Returns 0 if no data ready, 1 if data ready.
// Results of decoding are stored in results
boolean  CFunIR::decode() {
  rawbuf = irparams.rawbuf;
  rawlen = irparams.rawlen;

  if (irparams.rcvstate != STATE_STOP) {
    return 0;
  }

  if (decodeNEC()) {
    begin(_ir_pin);
    return 1;
  }
  begin(_ir_pin);
  return 0;
}

// NECs have a repeat only 4 items long
boolean  CFunIR::decodeNEC() {
  uint32_t data = 0;
  int offset = 0; // Skip first space
  // Initial mark
  if (!MATCH(rawbuf[offset], NEC_HDR_MARK / 50)) {
    return 0;
  }
  offset++;
  // Check for repeat
  if (rawlen == 3 &&
      MATCH(rawbuf[offset], NEC_RPT_SPACE / 50) &&
      MATCH(rawbuf[offset + 1], NEC_BIT_MARK / 50)) {
    bits = 0;
    // results->value = REPEAT;
    // Serial.println("REPEAT");
    decode_type = NEC;
    return 1;
  }
  if (rawlen < 2 * NEC_BITS + 3) {
    return 0;
  }
  // Initial space
  if (!MATCH(rawbuf[offset], NEC_HDR_SPACE / 50)) {
    return 0;
  }
  offset++;
  for (int i = 0; i < NEC_BITS; i++) {
    if (!MATCH(rawbuf[offset], NEC_BIT_MARK / 50)) {
      return 0;
    }
    offset++;
    if (MATCH(rawbuf[offset], NEC_ONE_SPACE / 50)) {
      //data = (data << 1) | 1;
      data = (data >> 1) | 0x80000000;
    }
    else if (MATCH(rawbuf[offset], NEC_ZERO_SPACE / 50)) {
      //data <<= 1;
      data >>= 1;
    }
    else {
      return 0;

    }
    offset++;
  }
  // Success
  bits = NEC_BITS;
  value = data;
  decode_type = NEC;
  return 1;
}


unsigned char CFunIR::getCode() {
  if (!_ir_flag_b)
  {
    begin(_ir_pin);
    _ir_flag_b = 1;
  }

    if (decode())
    {
      irRead = ((value >> 8) >> 8) & 0xff;
     _ir_flag_a=0;     
    }
    if(_ir_flag_a)
    {
      irRead=0;
    }  
    _ir_flag_a++;
    return irRead;

}

boolean CFunIR::keyPressed(unsigned char r) {
//  if (!_buzz_ir)
//    begin(_ir_pin);
  if (decode())
  {
    irRead = ((value >> 8) >> 8) & 0xff;
    lastIRTime = millis() / 1000.0;
    irPressed = true;
    if (irRead == 0xa || irRead == 0xd) {
      irIndex = 0;
      irReady = true;
    } else {
      irBuffer += irRead;
      irIndex++;
      if (irIndex > 64) {
        irIndex = 0;
        irBuffer = "";
      }
    }
    irDelay = 0;
  } else {
    irDelay++;
    if (irRead > 0) {
      if (irDelay > 5000) {
        irRead = 0;
        irDelay = 0;
      }
    }
  }
  ///////////
  irIndex = 0;
  if (millis() / 1000.0 - lastIRTime > 0.2) {
    return false;
  }
  return irRead == r;
}
boolean CFunIR::keyPressed() {
//  if (!_buzz_ir)
//    begin(_ir_pin);

  if (decode())
    return 1;
  else
    return 0;
}
