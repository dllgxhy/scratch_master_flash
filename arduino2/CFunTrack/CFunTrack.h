#ifndef CFUNTRACK_H_
#define CFNDTRACK_H_
#include "CFunPort.h"
///@brief Class for DC Motor Module
class CFunTrack: public CFunPort
{
public:
    CFunTrack();
    CFunTrack(uint8_t port);
    int Track(int value);
 private:
    int Tgray_val;
};
#endif
