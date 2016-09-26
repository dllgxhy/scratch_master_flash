/*
  Blink
  Turns on an LED on for one second, then off for one second, repeatedly.
 
  This example code is in the public domain.
 */
 
// Pin 13 has an LED connected on most Arduino boards.
// give it a name:

#include "YoungMaker7SegmentDisplay.h"

YoungMaker7SegmentDisplay seg;
float _disvalue;
unsigned long _distime;
// the setup routine runs once when you press reset:
void setup() {                
  // initialize the digital pin as an output.
seg.reset(13);
}

// the loop routine runs over and over again forever:
void loop() {
        
        seg.display(0x12);
}
