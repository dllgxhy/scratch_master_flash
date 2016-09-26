/*
  Blink
  Turns on an LED on for one second, then off for one second, repeatedly.
 
  This example code is in the public domain.
 */
 
// Pin 13 has an LED connected on most Arduino boards.
// give it a name:

#include "YoungMakerDCMotor.h"
YoungMakerDCMotor dc;


// the setup routine runs once when you press reset:
void setup() {                
  // initialize the digital pin as an output.
dc.forward(36);
}

// the loop routine runs over and over again forever:
void loop() {

}
