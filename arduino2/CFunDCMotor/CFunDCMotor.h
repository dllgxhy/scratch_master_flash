#ifndef CFUNDCMOTOR_H_
#define CFNDCMOTOR_H_
#include "CFunPort.h"
///@brief Class for DC Motor Module
class CFunDCMotor: public CFunPort
{
public:
    CFunDCMotor();
    CFunDCMotor(uint8_t port);
    void motorrun(uint8_t d,uint8_t s);
    void motorstop();
    void carstop();
    void forward(uint8_t speed);
    void back(uint8_t speed);
    void turnleft(uint8_t speed);
    void turnright(uint8_t speed);
};
#endif
