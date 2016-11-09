#include "CFunDCMotor.h"
CFunDCMotor::CFunDCMotor(): CFunPort(0)
{

}
CFunDCMotor::CFunDCMotor(uint8_t port): CFunPort(port)
{

}
void CFunDCMotor::motorrun(uint8_t d,uint8_t s)
{
    if(d == 1) {
        CFunPort::aWrite1(s);
        CFunPort::dWrite3(HIGH);
    } else {
        CFunPort::aWrite1(s);
        CFunPort::dWrite3(LOW);
    }
}
void CFunDCMotor::motorstop()
{
    CFunDCMotor::motorrun(1,0);
}

void CFunDCMotor::carstop()
{
    pinMode(5,OUTPUT);
    pinMode(6,OUTPUT);
    pinMode(7,OUTPUT);
    pinMode(8,OUTPUT);
    digitalWrite(7,HIGH);
    digitalWrite(8,HIGH);
    analogWrite(5,0);
    analogWrite(6,0);
}
void CFunDCMotor::forward(uint8_t speed)
{
    pinMode(5,OUTPUT);
    pinMode(6,OUTPUT);
    pinMode(7,OUTPUT);
    pinMode(8,OUTPUT);
    digitalWrite(7,HIGH);
    digitalWrite(8,HIGH);
    analogWrite(5,speed);
    analogWrite(6,speed);
}
void CFunDCMotor::back(uint8_t speed)
{
    pinMode(5,OUTPUT);
    pinMode(6,OUTPUT);
    pinMode(7,OUTPUT);
    pinMode(8,OUTPUT);
    digitalWrite(7,LOW);
    digitalWrite(8,LOW);
    analogWrite(5,speed);
    analogWrite(6,speed);
}
void CFunDCMotor::turnleft(uint8_t speed)
{
    pinMode(5,OUTPUT);
    pinMode(6,OUTPUT);
    pinMode(7,OUTPUT);
    pinMode(8,OUTPUT);
    digitalWrite(7,LOW);
    digitalWrite(8,HIGH);
    analogWrite(5,speed);
    analogWrite(6,speed);
}
void CFunDCMotor::turnright(uint8_t speed)
{
    pinMode(5,OUTPUT);
    pinMode(6,OUTPUT);
    pinMode(7,OUTPUT);
    pinMode(8,OUTPUT);
    digitalWrite(7,HIGH);
    digitalWrite(8,LOW);
    analogWrite(5,speed);
    analogWrite(6,speed);
}
