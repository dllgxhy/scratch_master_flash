#ifndef __YoungMakerBuzzer_H
#define __YoungMakerBuzzer_H

#include "YoungMakerBuzzer.h"
#include "YoungMakerPort.h"

//extern boolean _buzz_ir;

///@brief Class for CFunBuzzer module
class YoungMakerBuzzer
{
public:
    YoungMakerBuzzer();
    YoungMakerBuzzer(unsigned char pin);
    void tone(uint8_t pin,uint16_t frequency, uint32_t duration = 0);
    void noTone(uint8_t pin);
};

#endif
