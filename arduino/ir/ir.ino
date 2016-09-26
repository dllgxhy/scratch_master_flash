/*
  Blink
  Turns on an LED on for one second, then off for one second, repeatedly.
 
  This example code is in the public domain.
 */
 
// Pin 13 has an LED connected on most Arduino boards.
// give it a name:

#include "YoungMakerIR.h"
YoungMakerIR ir;


// the setup routine runs once when you press reset:
void setup() {                
  // initialize the digital pin as an output.
ir.begin(13);
ir.getCode();
}

// the loop routine runs over and over again forever:
void loop() {

}
