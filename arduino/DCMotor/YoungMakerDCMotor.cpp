#include "YoungMakerDCMotor.h"

YoungMakerDCMotor::YoungMakerDCMotor(): YoungMakerPort(0)
{

}
YoungMakerDCMotor::YoungMakerDCMotor(uint8_t port): YoungMakerPort(port)
{

}
void YoungMakerDCMotor::motorrun(uint8_t d,uint8_t s)
{
    if(d == 1) {
        YoungMakerPort::aWrite1(s);
        YoungMakerPort::dWrite3(HIGH);
    } else {
        YoungMakerPort::aWrite1(s);
        YoungMakerPort::dWrite3(LOW);
    }
}
void YoungMakerDCMotor::motorstop()
{
    YoungMakerDCMotor::motorrun(1,0);
}

void YoungMakerDCMotor::carstop()
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
void YoungMakerDCMotor::forward(uint8_t speed)
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
void YoungMakerDCMotor::back(uint8_t speed)
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
void YoungMakerDCMotor::turnleft(uint8_t speed)
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
void YoungMakerDCMotor::turnright(uint8_t speed)
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
