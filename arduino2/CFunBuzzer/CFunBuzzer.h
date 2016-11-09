#ifndef CFunBuzzer_H
#define CFunBuzzer_H

#include "CFunPort.h"

//extern boolean _buzz_ir;

///@brief Class for CFunBuzzer module
class CFunBuzzer
{
public:
    CFunBuzzer();
    CFunBuzzer(uint8_t pin);
    void tone(uint8_t pin,uint16_t frequency, uint32_t duration = 0);
    void noTone(uint8_t pin);
};

#endif
