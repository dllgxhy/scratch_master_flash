#include "CFunAvoid.h"
CFunAvoid::CFunAvoid(): CFunPort(0)
{

}
CFunAvoid::CFunAvoid(uint8_t port): CFunPort(port)
{

}
int CFunAvoid::Avoid()
{
   int left,right;
    pinMode(12,INPUT);
    pinMode(13,INPUT);
    left= digitalRead(12);
    right= digitalRead(13);
    return(left*10+right);
}
