#ifndef YoungMakerRGBLed_H
#define YoungMakerRGBLed_H 
#include "YoungMakerPort.h"
///@brief Class for RGB Led Module(http://www.makeblock.cc/me-rgb-led-v1-0/) and Led Strip(http://www.makeblock.cc/led-rgb-strip-addressable-sealed-1m/)
class YoungMakerRGBLed:public YoungMakerPort {
public: 
	YoungMakerRGBLed();
	YoungMakerRGBLed(uint8_t port);
	void reset(uint8_t port);
	///@brief set the rgb value of the led with the index.
	void setColorAt(uint8_t red,uint8_t green,uint8_t blue);
	
private:
	uint8_t redPin;
        uint8_t greenPin;
        uint8_t bluePin;
};
#endif
