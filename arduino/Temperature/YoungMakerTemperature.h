#ifndef YoungMakerTemperature_H
#define YoungMakerTemperature_H 
#include "YoungMakerPort.h"
///@brief Class for temperature sensor
class YoungMakerTemperature:public YoungMakerPort{
	public:
		YoungMakerTemperature();
		YoungMakerTemperature(uint8_t port);
		void reset(uint8_t port);
		///@brief get the celsius of temperature
		float temperature();
	private:
                uint8_t LM35;	
}; 
#endif
