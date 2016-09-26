#include "YoungMakerPort.h"

#if defined(__AVR_ATmega32U4__) //MeBaseBoard use ATmega32U4 as MCU

YoungMakerPort_Sig cfunPort[32] = {{0,1,2},{1,2,3},{2,3,4},{3,4,5},{4,5,6},{5,6,7},{6,7,8},{7,8,9},{8,9,10},{9,10,11},{10,11,12},{11,12,13}
};
#else // else ATmega328
YoungMakerPort_Sig cfunPort[18] = {{0,1,2},{1,2,3},{2,3,4},{3,4,5},{4,5,6},{5,6,7},{6,7,8},{7,8,9},{8,9,10},{9,10,11},{10,11,12},{11,12,13},{A0,A1,A2},{A1,A2,A3},{A2,A3,A4},{A3,A4,A5},{A4,A5,A0},{A5,A0,A1}
};

#endif

union{
    byte b[4];
    float fVal;
    long lVal;
}u;

/*        Port       */
YoungMakerPort::YoungMakerPort(){
    s1 = cfunPort[0].s1;
    s2 = cfunPort[0].s2;
    s3 = cfunPort[0].s3;
    _port = 0;
}
YoungMakerPort::YoungMakerPort(uint8_t port)
{
    s1 = cfunPort[port].s1;
    s2 = cfunPort[port].s2;
    s3 = cfunPort[port].s3;
    _port = port;
	//The PWM frequency is 976 Hz
#if defined(__AVR_ATmega32U4__) //MeBaseBoard use ATmega32U4 as MCU

TCCR1A =  _BV(WGM10);
TCCR1B = _BV(CS11) | _BV(CS10) | _BV(WGM12);

TCCR3A = _BV(WGM30);
TCCR3B = _BV(CS31) | _BV(CS30) | _BV(WGM32);

TCCR4B = _BV(CS42) | _BV(CS41) | _BV(CS40);
TCCR4D = 0;

#else if defined(__AVR_ATmega328__) // else ATmega328

TCCR1A = _BV(WGM10);
TCCR1B = _BV(CS11) | _BV(CS10) | _BV(WGM12);

TCCR2A = _BV(WGM21) |_BV(WGM20);
TCCR2B = _BV(CS22);

#endif
}  



uint8_t YoungMakerPort::getPort(){
	return _port;
}
bool YoungMakerPort::dRead1()
{
    bool val;
    pinMode(s1, INPUT);
    val = digitalRead(s1);
    return val;
}

bool YoungMakerPort::dRead2()
{
    bool val;
	pinMode(s2, INPUT);
    val = digitalRead(s2);
    return val;
}
bool YoungMakerPort::dRead3()
{
    bool val;
	pinMode(s3, INPUT);
    val = digitalRead(s3);
    return val;
}
void YoungMakerPort::dWrite1(bool value)
{
    pinMode(s1, OUTPUT);
    digitalWrite(s1, value);
}

void YoungMakerPort::dWrite2(bool value)
{
    pinMode(s2, OUTPUT);
    digitalWrite(s2, value);
}
void YoungMakerPort::dWrite3(bool value)
{
    pinMode(s3, OUTPUT);
    digitalWrite(s3, value);
}
int YoungMakerPort::aRead1()
{
    int val;
    val = analogRead(s1);
    return val;
}

int YoungMakerPort::aRead2()
{
    int val;
    val = analogRead(s2);
    return val;
}
int YoungMakerPort::aRead3()
{
    int val;
    val = analogRead(s3);
    return val;
}
void YoungMakerPort::aWrite1(int value)
{   
    analogWrite(s1, value);  
}

void YoungMakerPort::aWrite2(int value)
{
    analogWrite(s2, value); 
}
void YoungMakerPort::aWrite3(int value)
{
    analogWrite(s3, value); 
}
void YoungMakerPort::reset(uint8_t port){
    s1 = cfunPort[port].s1;
    s2 = cfunPort[port].s2;
    s3 = cfunPort[port].s3;
    _port = port;
}
uint8_t YoungMakerPort::pin1(){
	return s1;
}
uint8_t YoungMakerPort::pin2(){
	return s2;
}
uint8_t YoungMakerPort::pin3(){
	return s3;
}
double YoungMakerPort::minicarVolt()
{
    int val;
    float voltage=0.0;
    val = analogRead(A5);
    voltage=(float)val*10.0/1024;
    return voltage;
}
