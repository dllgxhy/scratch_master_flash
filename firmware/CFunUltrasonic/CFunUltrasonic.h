
#ifndef CFUNULTRASONIC_H_
#define CFUNULTRASONIC_H_
#include "CFunPort.h"
///@brief Class for Ultrasonic Sensor Module
extern void ius();
extern unsigned long _itime;
extern unsigned long _iustime;
class CFunUltrasonic
{
  public:
    CFunUltrasonic();
   // CFunUltrasonic(uint8_t pin);
    double distanceCm();
    long measure1ms();
    long measure();
    
  private:
    uint8_t _Trig;
    uint8_t _Echo;
    uint8_t _time;
};
#endif
