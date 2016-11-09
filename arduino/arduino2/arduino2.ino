#include <Servo.h>
#include "YoungMakerPort.h"
#include "YoungMakerDCMotor.h"
#include "YoungMakerAvoid.h"
#include "YoungMakerTrack.h"
#include "YoungMaker7SegmentDisplay.h"
#include "YoungMakerRGBLed.h"
#include "YoungMakerIR.h"
#include "YoungMakerCapacitive.h"
#include "YoungMakerBuzzer.h"
#include "YoungMakerCrystal.h"
#include "YoungMakerTemperature.h"
#include "YoungMakerUltrasonic.h"

#define TIMER2_PRELOAD 100

char outputs[10];
int states[10];

unsigned long initialPulseTime;
unsigned long lastDataReceivedTime;

volatile boolean updateServoMotors;
volatile boolean newInterruption;

Servo servo;
YoungMakerPort 					cp;//CFunport
YoungMakerDCMotor 				dcmotor;
YoungMakerAvoid 				iravoid;
YoungMakerTrack 				irtrack;
YoungMakerTemperature 			ts;
YoungMakerRGBLed 				led;
YoungMaker7SegmentDisplay 		seg_led;
YoungMakerIR 					ir;
YoungMakerBuzzer 				buzz;

YoungMakerCrystal lcd(0x20, 16, 2);  //LCD1602显示


long ultraSonicValue = 0;			 //超声波传感器
#define TRIG_PIN 2
#define ECHO_PIN 3 
YoungMakerUltrasonic ultraSonic = YoungMakerUltrasonic(ECHO_PIN,TRIG_PIN);	//将超声波传感器设置为全局变量，随时可以进行调用

///////////////////////////////////////////////////
#if defined(ARDUINO) && ARDUINO >= 100
#define printByte(args)  write(args);
#else
#define printByte(args)  print(args,BYTE);
#endif
//////////////////////////////////////////////////
/***************************
串口工作信号量
以信号量的方法设定串口数据可否发送与接收
***************************/
char uartSignal = 0x00;
void setUartBusy()
{
	uartSignal = 0x01;
}

void setUartFree()
{
	uartSignal = 0x00;
}

bool checkUartStatus()
{
	if(uartSignal) return true;
	else return false;
}

//串口发送数据的Buffer
char uartTxBuffer[] = {0x00};
char uartRxBuffer[] = {0x00};

union {
  byte byteVal[4];
  float floatVal;
} val;

//CFunModule modules[12];
#if defined(__AVR_ATmega32U4__)
int analogs[12] = {A0, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11};
#else
int analogs[8] = {A0, A1, A2, A3, A4, A5, A6, A7};
#endif

typedef enum Sensor_Type{
	HEART_PACKAGE 				= 0x01,  //心跳包数据
	READ_DIGITAL_DATA   		= 0x02,
	READ_ANALOG_DATA   			= 0x03,
	READ_LM35_TEMPERATURE_DATA  = 0x04, //读取LM35温度传感器
	READ_ROCKER_XY 				= 0X05,
	
	/**********Scratch写入Arduino的数据******************/
	ID_SetDigital 		   = 0x81,
	ID_SetPWM 			   = 0x82,
	ID_SetSG 			   = 0x83,
	ID_SetMUS 			   = 0x84,
	ID_SetNUM			   = 0x85,
	ID_SetDM 			   = 0x86,
	ID_SetRGB 			   = 0x87,
	ID_SetLCD1602String    = 0x88,
}Sensor_Type;
Sensor_Type sensor_type;

/*
解析接收到的串口数据
串口协议的定义详见《通讯协议》
*/
void parseReceiveData()
{
	char uartRxBufferSize = sizeof(uartRxBuffer);
	if((uartRxBuffer[0] == 0xfe)&	//检查接收到的包头和包尾是否正确
		(uartRxBuffer[1] == 0xfd) & 
		(uartRxBuffer[uartRxBufferSize -1] == 0xfb) &
		(uartRxBuffer[uartRxBufferSize -2] == 0xfe))
 	{
 		if(uartRxBuffer[2] == uartRxBufferSize)//检查接收到的数据长度是否准确
		{
			processData(&uartRxBuffer[3]);
		}
		else
		{
		}
 	}
 	else
	{
		
	}
}
/*
解析数据段
*/
void processData(char *data)
{
	char *data_tmp = data;
	switch(data_tmp[0])
	{
/***********************************************/
		case READ_DIGITAL_DATA:
			break;
		case READ_ANALOG_DATA:
			break;
		case READ_LM35_TEMPERATURE_DATA:
			break;
/***********************************************/
		case ID_SetDigital:
			write_digital(&data_tmp[1]);
			break;
		case ID_SetPWM:
			write_pwm(&data_tmp[1]);
			break;
		case ID_SetSG:
			write_Servo(&data_tmp[1]);
			break;
		case ID_SetMUS:
			write_beep(&data_tmp[1]);
			break;	
		case ID_SetNUM:
			write_7seg_led(&data_tmp[1]);
			break;
		case ID_SetDM:
			write_dcmotor(&data_tmp[1]);
			break;
		case ID_SetRGB:
			write_dcmotor(&data_tmp[1]);
			break;
                case ID_SetLCD1602String:
                        write_LCD1602String(&data_tmp[1]);
		default :
			break;
	}
}

void write_digital(char* data)
{
	char pin = 0x00;
	pin = data[0];
	val.byteVal[0] = data[1];
	pinMode(pin, OUTPUT);
    digitalWrite(pin, val.byteVal[0] >= 1 ? HIGH : LOW);
}

void write_Servo(char* data)
{
	char pin = 0x00;
	char angel = 0x00;
	pin = data[0];	
	angel = data[1];
  servo.attach(pin);
  servo.write(angel);
}

void write_pwm(char* data)
{
}
void write_beep(char* data)
{
}

void write_7seg_led(char* data)
{
	char pin = 0x00;
	pin = data[0];
	val.byteVal[3] = data[1];
	val.byteVal[2] = data[2];
	val.byteVal[1] = data[3];
	val.byteVal[0] = data[4];
	seg_led.reset(pin);
    seg_led.display(val.floatVal);
}

void write_dcmotor(char* data)
{
	char pin = 0x00;
	char direction = 0x00;
	char time = 0x00;
	pin = data[0];	
	direction = data[1];
	time = data[2];
  dcmotor.reset(pin);
  dcmotor.motorrun(direction, time);
}
void write_LCD1602String(char* data)
{
}

/****************************************
//板载传感器的数据//
包括如下种类的传感器,顺序具有唯一性,与scratch是一一对应的关系：
1) 光敏传感器：A5
2) 声音传感器: A3
3) 滑动变阻器: A4
4) 红色按键  : D2
5) 绿色按键  : D3
6) 超声波测距:  占用4个字节  需要单独处理
注：测试代码只有光敏和超声波两种传感器

***************************************/
struct CKSensorVale
{
	unsigned char lightValue_H;
	unsigned char lightValue_L;
	
	unsigned char ultraSonicValue_H;
	unsigned char ultraSonicValue_MH;
	unsigned char ultraSonicValue_ML;
	unsigned char ultraSonicValue_L;
}cksensorValue;

//存储传感器数据的数组
char CKSensorValue[6] = {0x00};

/*IO口设置*/
/*  */
void setup()
{
 Serial.begin(115200);  
 Serial.flush();
 configurePins();
 configureServomotors();
 lastDataReceivedTime = millis();
 pinMode(A0,INPUT_PULLUP);
 pinMode(A1,INPUT_PULLUP);
 pinMode(A2,INPUT_PULLUP);
 pinMode(A3,INPUT_PULLUP);
 pinMode(A4,INPUT_PULLUP);
 pinMode(A5,INPUT_PULLUP);
}



void loop()
{
 
 if (updateServoMotors)
 {
	sendUpdateServomotors();
	ScratchBoardSensorReport();
	updateServoMotors = false;
 }
 else
 {
   readSerialPort();
 }
}

void configurePins()
{
 for (int index = 0; index < 10; index++)
 {
    states[index] = 0;
    pinMode(index+4, OUTPUT);
    digitalWrite(index+4, LOW); //reset pins
 }

 //pinMode(2,INPUT);
 //pinMode(3,INPUT);
 
 outputs[0] = 'c'; //pin 4
 outputs[1] = 'a'; //pin 5
 outputs[2] = 'a'; //pin 6
 outputs[3] = 'c'; //pin 7
 outputs[4] = 's'; //pin 8
 outputs[5] = 'a'; //pin 9
 outputs[6] = 'd'; //pin 10
 outputs[7] = 'd'; //pin 11
 outputs[8] = 'd'; //pin 12
 outputs[9] = 'd'; //pin 13
}

void configureServomotors() //servomotors interruption configuration (interruption each 10 ms on timer2)
{
 newInterruption = false;
 updateServoMotors = false;

 TCCR2A = 0;
 TCCR2B = 1<<CS22 | 1<<CS21 | 1<<CS20;
 TIMSK2 = 1<<TOIE2; //timer2 Overflow Interrupt
 TCNT2 = TIMER2_PRELOAD; //start timer
}

/*
直接读取模拟口和数字口的数据
*/
void readSensorValues()
{
	int sensorValues, readings[5]; 
	int sensorIndex = 0x05;

	for (int p = 0; p < 5; p++)
		readings[p] = analogRead(sensorIndex);   //
		InsertionSort(readings, 5); 						//sort readings
    CKSensorValue[0] = (readings[2] >> 8 & B11 );   
    CKSensorValue[1] = (readings[2]  &  B11111111);  
}

/*读取超声波传感器的数据*/
void readUltraSonicValues()
{
		ultraSonicValue = ultraSonic.Distance();  //读取超声波的值

		CKSensorValue[2] = (ultraSonicValue >> 24) & B11111111;
		CKSensorValue[3] = (ultraSonicValue >> 16) & B11111111;
		CKSensorValue[4] = (ultraSonicValue >> 8) & B11111111;
		CKSensorValue[5] = (ultraSonicValue) & B11111111;
		
}


void InsertionSort(int* array, int n)
{
  for (int i = 1; i < n; i++)
    for (int j = i; (j > 0) && ( array[j] < array[j-1] ); j--)
      swap( array, j, j-1 );
}

void swap (int* array, int a, int b)
{
  int temp = array[a];
  array[a] = array[b];
  array[b] = temp;
}

/*
ScratchBoardSensorReport
//通讯协议拟定为
包头       数据长度  数据类型      数据     包尾
0xfe 0xfd      n        0x01       xxxxx   0xfe 0xfb
数据类型
*/
void ScratchBoardSensorReport() //PicoBoard protocol, 2 bytes per sensor
{
  char i = 0x00; 
  readSensorValues();
  readUltraSonicValues();
  delay(10);
  Serial.write(0xfe);
  Serial.write(0xfd);  
  Serial.write(0x0C);  
  Serial.write(0x01);
  for(i = 0x00;i <= 0x05;i++)
  {
	  Serial.write(CKSensorValue[i]);   //通过串口上报数据
  }  
  Serial.write(0xfe);
  Serial.write(0xfb);
}


/************************************************************
readSerialPort:读取串口接收到的数据
************************************************************/
void readSerialPort()
{
  int pin, inByte, sensorHighByte;

  if (Serial.available() > 1)
  {
    lastDataReceivedTime = millis();
    inByte = Serial.read();
    Serial.println(__LINE__);
    if (inByte >= 128) // Are we receiving the word's header?
    {
      sensorHighByte = inByte;
      pin = ((inByte >> 3) & 0x0F);
      while (!Serial.available()); // Wait for the end of the word with data
      inByte = Serial.read();
      if (inByte <= 127) // This prevents Linux ttyACM driver to fail
      {
        states[pin - 4] = ((sensorHighByte & 0x07) << 7) | (inByte & 0x7F);
          updateActuator(pin - 4);
      }
    }
  }
  else checkScratchDisconnection();
}

void reset() //with xbee module, we need to simulate the setup execution that occurs when a usb connection is opened or closed without this module
{
  for (int pos = 0; pos < 10; pos++)  //stop all actuators
  {
    states[pos] = 0;
    digitalWrite(pos + 2, LOW);
  }

  //reset servomotors
  newInterruption = false;
  updateServoMotors = false;
  TCNT2 = TIMER2_PRELOAD;

  //protocol handshaking
  ScratchBoardSensorReport();
  lastDataReceivedTime = millis();
}

void updateActuator(int pinNumber)
{
  if (outputs[pinNumber] == 'd')  digitalWrite(pinNumber + 4, states[pinNumber]);
  else if (outputs[pinNumber] == 'a')  analogWrite(pinNumber + 4, states[pinNumber]);
}

void sendUpdateServomotors()
{
  for (int p = 0; p < 10; p++)
  {
    if (outputs[p] == 'c') servomotorC(p + 4, states[p]);
    if (outputs[p] == 's') servomotorS(p + 4, states[p]);
  }
}

void servomotorC (int pinNumber, int dir)
{
  if (dir == 1) pulse(pinNumber, 1300); //clockwise rotation
  else if (dir == 2) pulse(pinNumber, 1700); //anticlockwise rotation
}

void servomotorS (int pinNumber, int angle)
{
  if (angle < 0) pulse(pinNumber, 600);
  else if (angle > 180) pulse(pinNumber, 2400);
  else pulse(pinNumber, (angle * 10) + 600);
}

void pulse (int pinNumber, int pulseWidth)
{
  initialPulseTime = micros();
  digitalWrite(pinNumber, HIGH);

  while (micros() < pulseWidth + initialPulseTime){}
  digitalWrite(pinNumber, LOW);
}

void checkScratchDisconnection() //the reset is necessary when using an wireless arduino board (because we need to ensure that arduino isn't waiting the actuators state from Scratch) or when scratch isn't sending information (because is how serial port close is detected)
{
  if (millis() - lastDataReceivedTime > 1000) reset(); //reset state if actuators reception timeout = one second
}

ISR(TIMER2_OVF_vect) //timer1 overflow interrupt vector handler
{ //timer2 => 8 bits counter => 256 clock ticks
  //preeescaler = 1024 => this routine is called 61 (16.000.000/256/1024) times per second approximately => interruption period =  1 / 16.000.000/256/1024 = 16,384 ms
  //as we need a 20 ms interruption period but timer2 doesn't have a suitable preescaler for this, we program the timer with a 10 ms interruption period and we consider an interruption every 2 times this routine is called.
  //to have a 10 ms interruption period, timer2 counter must overflow after 156 clock ticks => interruption period = 1 / 16.000.000/156/1024 = 9,984 ms => counter initial value (TCNT) = 100
  if (newInterruption)
  {
    updateServoMotors = true;
  }
  newInterruption = !newInterruption;
  TCNT2 = TIMER2_PRELOAD;  //reset timer
}
/*
//IO口中断
void ius() {
  _iustime = micros() - _itime;
  noInterrupts();
}*/


