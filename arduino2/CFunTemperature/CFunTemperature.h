#ifndef CFunTemperature_h
#define CFunTemperature_h 
#include "CFunPort.h"
///@brief Class for temperature sensor
class CFunTemperature:public CFunPort{
	public:
		CFunTemperature();
		CFunTemperature(uint8_t port);
		void reset(uint8_t port);
		///@brief get the celsius of temperature
		float temperature();
	private:
                uint8_t LM35;	
}; 
#endif
