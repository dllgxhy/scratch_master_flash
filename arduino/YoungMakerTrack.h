#ifndef YoungMakerTrack_H_
#define CFNDTRACK_H_
#include "YoungMakerPort.h"
///@brief Class for DC Motor Module
class YoungMakerTrack: public YoungMakerPort
{
public:
    YoungMakerTrack();
    YoungMakerTrack(uint8_t port);
    int Track(int value);
 private:
    int Tgray_val;
};
#endif
