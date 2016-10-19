#ifndef YoungMakerAvoid_H_
#define YoungMakerAvoid_H_
#include "YoungMakerPort.h"
///@brief Class for AVOIDING  Module
class YoungMakerAvoid: public YoungMakerPort
{
public:
    YoungMakerAvoid();
    YoungMakerAvoid(uint8_t port);
    int Avoid();
};
#endif
