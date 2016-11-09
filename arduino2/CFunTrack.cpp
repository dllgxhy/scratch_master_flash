#include "CFunTrack.h"
CFunTrack::CFunTrack(): CFunPort(0)
{

}
CFunTrack::CFunTrack(uint8_t port): CFunPort(port)
{

}
int CFunTrack::Track(int value)
{  
 int Tgray_val=value;
// int det1= ((analogRead(A0)>=Tgray_val) ? 1:0);
 int det2= ((analogRead(A1)>=Tgray_val) ? 0:1);
 int det3= ((analogRead(A2)>=Tgray_val) ? 0:1);
// int det4= ((analogRead(A3)>=Tgray_val) ? 1:0);
 //int det5= ((analogRead(A4)>=Tgray_val) ? 0:1);
 return (det2*10+det3);
}

