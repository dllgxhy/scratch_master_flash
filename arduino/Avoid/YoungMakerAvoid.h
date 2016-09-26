#ifndef CFUNAVOID_H_
#define CFNAVOID_H_
#include "CFunPort.h"
///@brief Class for AVOIDING  Module
class CFunAvoid: public CFunPort
{
public:
    CFunAvoid();
    CFunAvoid(uint8_t port);
    int Avoid();
};
#endif
