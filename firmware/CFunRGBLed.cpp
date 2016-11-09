#include "CFunRGBLed.h"
CFunRGBLed::CFunRGBLed():CFunPort(0) {
}
CFunRGBLed::CFunRGBLed(uint8_t port):CFunPort(port) {
//        redPin=s1;
//        greenPin=s2;
//        bluePin=s3;
//        pinMode(redPin,OUTPUT);
//        pinMode(greenPin,OUTPUT);
//        pinMode(bluePin,OUTPUT);
}
void CFunRGBLed::reset(uint8_t port){
//        _port = port;
//	s1 = cfunPort[port].s1;
//        s2 = cfunPort[port].s2;
//        s3 = cfunPort[port].s3;
//        redPin=s1;
//        greenPin=s2;
//        bluePin=s3;
//        pinMode(redPin,OUTPUT);
//        pinMode(greenPin,OUTPUT);
//        pinMode(bluePin,OUTPUT);
}
void CFunRGBLed::setColorAt(uint8_t red,uint8_t green,uint8_t blue) {       
              analogWrite(9, red);
              analogWrite(10, green);
              analogWrite(11, blue);  	
}
