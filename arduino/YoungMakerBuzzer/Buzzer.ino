/* 少年创客 */
/* YoungMaker */
/* www.youngmaker.com */
#include "YoungMakerPort.h"
#include <Wire.h>
#include "YoungMakerBuzzer.h" 
YoungMakerBuzzer YoungMakerBuzzer3(3);

void setup(){
pinMode(3,OUTPUT);
YoungMakerBuzzer3.tone(3,65,500);
delay(500);
}

void loop(){
}
