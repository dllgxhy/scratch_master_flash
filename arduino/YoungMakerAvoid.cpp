#include "YoungMakerAvoid.h"
YoungMakerAvoid::YoungMakerAvoid(): YoungMakerPort(0)
{

}
YoungMakerAvoid::YoungMakerAvoid(uint8_t port): YoungMakerPort(port)
{

}
int YoungMakerAvoid::Avoid()
{
   int left,right;
    pinMode(12,INPUT);
    pinMode(13,INPUT);
    left= digitalRead(12);
    right= digitalRead(13);
    return(left*10+right);
}
