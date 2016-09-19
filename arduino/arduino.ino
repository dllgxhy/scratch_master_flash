////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////
//#include <Wire.h>
#include <Servo.h>
#include "YoungMakerPort.h"
#include "YoungMakerBuzzer.h"
#include "YoungMakerUltrasonic.h"

/*定义各功能模块*/

YoungMakerPort cp;
YoungMakerBuzzer buzz;
/********************************
//超声波传感器//
********************************/
long ultraSonicValue = 0;
#define TRIG_PIN 2
#define ECHO_PIN 3 
YoungMakerUltrasonic ultrasonic = YoungMakerUltrasonic(ECHO_PIN,TRIG_PIN);

/*定义全局变量*/
union {
  byte byteVal[4];
  float floatVal;
} val;

boolean isAvailable = false;
boolean isBluetooth = false;

unsigned char CKSensorValue[] = {0x00}; //存储传感器数据的数组，随心跳包发出至scratch

unsigned long initialPulseTime;
unsigned long lastDataReceivedTime;
unsigned long _itime;               //for Ultrasonic interrupt function
unsigned long _iustime;             //for Ultrasonic interrupt function

unsigned char uartTxBuffer[20] = {0x00};    //串口发送数据的Buffer
unsigned char uartRxBuffer[20] = {0x00};
char uartRx_idx = 0x00;

#define BLUETOOTH_BUF_SIZE      20
unsigned char  bleuart_rec_buf[BLUETOOTH_BUF_SIZE] = {0};
unsigned int bluetooth_len = 0;


//CFunModule modules[12];
#if defined(__AVR_ATmega32U4__)
int analogs[12] = {A0, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11};
#else
int analogs[8] = {A0, A1, A2, A3, A4, A5, A6, A7};
#endif


#define TIMER2_PRELOAD 100

char outputs[10];
int states[10];

////////////////////////////////////////////////////////////
void setup() {
  pinMode(13, OUTPUT);
  digitalWrite(13, HIGH);
  delay(300);
  digitalWrite(13, LOW);
#if defined(__AVR_ATmega32U4__)
  Serial1.begin(115200);
  gyro.begin();
#endif
  Serial.begin(115200);
 
	pinMode(A0,INPUT_PULLUP);
	pinMode(A1,INPUT_PULLUP);
	pinMode(A2,INPUT_PULLUP);
	pinMode(A3,INPUT_PULLUP);
	pinMode(A4,INPUT_PULLUP);
	pinMode(A5,INPUT_PULLUP);
}

///////////////////////////////////////////////////////////////////////
void loop()
{
//	readSerialPort();
	receive_data_proc();
        delay(1000);

//    heartPackageSend();
//  ArduinoBoardSend2Scratch(type,data,sizeof(data));
//	char hexdata = 0xFe;
//	char asciidata[] = {0x00};
//	hex2ascii(&hexdata,asciidata);
//	Serial.println(asciidata[0]);
//	Serial.println(asciidata[1]);

 /*if (updateServoMotors)
 {
		sendUpdateServomotors();
		ScratchBoardSensorReport();
		updateServoMotors = false;
 }
 else
 {
   readSerialPort();
 }*/
}
#define sensor_num 5 
void heartPackageSend()
{
  char type = 1;
  readSensorValues();
  ArduinoBoardSend2Scratch(type,CKSensorValue,10);
}


/*
ScratchBoardSensorReport
//通讯协议拟定为
包头         数据类型     数据     包尾
0xfe 0xfd     0x01       xxxxx   0xfe 0xfb
@para[1] type: 数据种类
@para[2] data: 发送的数据 hex类型，在函数内部转换成ASCII码
注：选择ASCII的好处为  scratch中对0x00 定义为Nan，比较难处理，
采用ASCII上传则不会出现这个问题
*/
void ArduinoBoardSend2Scratch(unsigned char type,unsigned char *data,char len) 
{
  unsigned char len_tmp = 0x00;
  
  unsigned char asciidata_tmp[2] = {0x00};
  
  Serial.print("fefd");	 //包头
  hex2ascii(&type,asciidata_tmp);
  Serial.print(asciidata_tmp[0]);   //通过串口上报数据
  Serial.print(asciidata_tmp[1]);

  
  len_tmp = len + 1; 
  hex2ascii(&len_tmp,asciidata_tmp);
  Serial.print(asciidata_tmp[0]);   //通过串口上报数据
  Serial.print(asciidata_tmp[1]);
  for(char i = 0x00;i < len;i++)  //数据长度
  {
	hex2ascii(&data[i],asciidata_tmp);
    Serial.print(asciidata_tmp[0]);   //通过串口上报数据
    Serial.print(asciidata_tmp[1]);
  } 
  Serial.println("fefb");//包尾
}

void hex2ascii(unsigned char *hexdata,unsigned char *ascdata)
{
	 unsigned char data_tmp_h = 0x00;
	 unsigned char data_tmp_l = 0x00;
	 data_tmp_h = (*hexdata >> 4)&0x0f;
	 data_tmp_l = (*hexdata)&0x0f; 
	 
	 if((0 <= data_tmp_h) && (data_tmp_h <= 9))
	 {
	 		data_tmp_h = data_tmp_h + 0x30;
	 }
	 else if((0x0a <= data_tmp_h) && (data_tmp_h <= 0x0f))
	 {
	 	 data_tmp_h = data_tmp_h + 0x61 - 0x0a;
	 }
	 else if((0x0A <= data_tmp_h) && (data_tmp_h <= 0x0F))
	 {
	 	data_tmp_h = data_tmp_h + 0x41 - 0x0a;
	 }
	 else
	 {
	 }
	 ascdata[0] = data_tmp_h;
	 if((0 <= data_tmp_l) && (data_tmp_l <= 9))
	 {
	 		data_tmp_l = data_tmp_l + 0x30;
	 }
	 else if((0x0a <= data_tmp_l) && (data_tmp_l <= 0x0f))
	 {
	 	 data_tmp_l = data_tmp_l + 0x61-0x0a;
	 }
	 else if((0x0A <= data_tmp_l) && (data_tmp_l <= 0x0F))
	 {
	 	data_tmp_l = data_tmp_l + 0x41 - 0x0a;
	 }
	 else
	 {
	 }
	 ascdata[1] = data_tmp_l;
}


void receive_data_proc(void)
{
    unsigned char  len = 0;
    unsigned char buf[20] = {0x00};
    unsigned char  flag = 0;
    unsigned int i = 0;
    unsigned int idx = 0;
    unsigned int size = 0; 

    len = readSerialPort();
	
    if(len)
    {
      if( bleuart_rec_buf[i] == 0xfe && bleuart_rec_buf[i+1] == 0xfd && bleuart_rec_buf[len-2] == 0xfe && bleuart_rec_buf[len-1] == 0xfb)
      {
        Serial.println("receive_data_proc");
        processData(&bleuart_rec_buf[2],len-4);
      }
    }
}

unsigned char analyze_bluetooth_data(unsigned char *p_data,unsigned int size)
{
    return  0x00;
}

/*
// readSerialPort  //
*/
unsigned char readSerialPort()
{  
  char i = 0x00;
  unsigned len = 0x00;
  if (Serial.available() > 0)
  {
	lastDataReceivedTime = millis();
  	uartRxBuffer[uartRx_idx] = Serial.read();
        Serial.flush();	
	
	if((uartRxBuffer[uartRx_idx - 1] == 0xfe) & (uartRxBuffer[uartRx_idx] == 0xfb) )
	{
		len = uartRx_idx + 1;
		uartRx_idx = 0x00;
		memcpy(bleuart_rec_buf,uartRxBuffer,len);
		memset(uartRxBuffer,0x00,20);
		return len;
	}
	uartRx_idx++;
  }
	
	
/*	
    if (inByte >= 128) // Are we receiving the word's header?
    {
      sensorHighByte = inByte;
      pin = ((inByte >> 3) & 0x0F);
	  Serial.print("readSerialPort pin = ");
	  Serial.println(pin);
      while (!Serial.available()); // Wait for the end of the word with data
      inByte = Serial.read();
      if (inByte <= 127) // This prevents Linux ttyACM driver to fail
      {
        states[pin - 4] = ((sensorHighByte & 0x07) << 7) | (inByte & 0x7F);
          updateActuator(pin - 4);
		   Serial.println("xuhy");
      }
    }*/
//  }
  else checkScratchDisconnection();
  return len;
}

/*
直接读取模拟口和数字口的数据,
这类数据
*/
void readSensorValues()
{
	int  readings[5] = {0x00}; 
	int sensorIndex = 0x00;
	for(sensorIndex = 0x00;sensorIndex < sensor_num;sensorIndex++)
	{
		for (int p = 0; p < 5; p++) //连续读5次传感器的值
    {
			readings[p] = analogRead(sensorIndex);   
	  }
	  InsertionSort(readings, 5); 						//sort readings
    CKSensorValue[sensorIndex*2] = (readings[2] >> 8 & B11);   
    CKSensorValue[sensorIndex*2+1] = (readings[2] &  B11111111);
	}
}

/*读取超声波传感器的数据*/
void readUltraSonicValues(unsigned char *CKSensorValue)
{
		ultraSonicValue = ultrasonic.Distance();  //读取超声波的值

		CKSensorValue[12] = (ultraSonicValue >> 24) & B11111111 + '0';
		CKSensorValue[13] = (ultraSonicValue >> 16) & B11111111 + '0';
		CKSensorValue[14] = (ultraSonicValue >> 8) & B11111111 + '0';
		CKSensorValue[15] = (ultraSonicValue) & B11111111 + '0';	
}

void sendUpdateServomotors()
{
  for (int p = 0; p < 10; p++)
  {
    if (outputs[p] == 'c') servomotorC(p + 4, states[p]);
    if (outputs[p] == 's') servomotorS(p + 4, states[p]);
  }
}


typedef enum {
	HEART_PACKAGE = 0x01,  //心跳包数据
	READ_DIGITAL_DATA  = 0x02,
	READ_ANALOG_DATA   = 0x03,
	READ_LM35_TEMPERATURE_DATA = 0x04, //读取LM35温度传感器
	READ_ROCKER_XY = 0X05,
	
	/**********Scratch写入Arduino的数据******************/
	WRITE_DIGITAL_WRITE = 0x81,
	WRITE_PWM = 0x82,
	WRITE_Servo = 0x83,
	WRITE_BUZZER = 0x84,
	WRITE_7SEG_LED = 0x85,
	WRITE_DCMOTOR = 0x86,
	WRITE_3COLOR_LED = 0x87,
	WRITE_LCD1602 = 0x88,
}SENSOR_TYPE;
SENSOR_TYPE sensortype;
/***************************
串口工作信号量
以信号量的方法设定串口数据可否发送与接收
***************************/
char uartSignal = 0x00;
void setUartBusy()
{
	uartSignal = 0x01;
}

void setUartfree()
{
	uartSignal = 0x00;
}

bool checkUartStatus()
{
	if(uartSignal) return true;
	else return false;
}

/*
解析数据段
*/
void processData(unsigned char *data,unsigned char len)
{
	unsigned char *data_tmp = data;
        sensortype = (SENSOR_TYPE)data_tmp[0];
	switch(sensortype)
	{
/***********************************************/
		case READ_DIGITAL_DATA:
			break;
		case READ_ANALOG_DATA:
			break;
		case READ_LM35_TEMPERATURE_DATA:
			break;
/***********************************************/
		case WRITE_DIGITAL_WRITE:
			write_digital(&data_tmp[1]);
			break;
		case WRITE_PWM:
			write_pwm(&data_tmp[1]);
			break;
		case WRITE_Servo:
			write_Servo(&data_tmp[1]);
			break;
		case WRITE_BUZZER:
			write_buzzer(&data_tmp[1]);
			break;	
		case WRITE_7SEG_LED:
			write_7seg_led(&data_tmp[1]);
			break;
		case WRITE_DCMOTOR:
			write_dcmotor(&data_tmp[1]);
			break;
		case WRITE_3COLOR_LED:
			write_dcmotor(&data_tmp[1]);
			break;
		default :
			break;
	}
}

void write_digital(unsigned char* data)
{

}

void write_Servo(unsigned char* data)
{

}


void write_7seg_led(unsigned char* data)
{

}

void write_dcmotor(unsigned char* data)
{

}


void write_pwm(unsigned char* data)
{

}

void write_buzzer(unsigned char* data)
{	
	int dataIndex = 0;
	unsigned char pin = data[dataIndex++];
	Serial.println("write_buzzer");
	val.byteVal[3] = data[dataIndex++];
	val.byteVal[2] = data[dataIndex++];
	val.byteVal[1] = data[dataIndex++];
	val.byteVal[0] = data[dataIndex++];
	pinMode(pin, OUTPUT);
	int toneHz = val.byteVal[3] * 256 + val.byteVal[2];
	int timeMs = val.byteVal[1] * 255 + val.byteVal[0];
	if (timeMs != 0) {
	  buzz.tone(pin, toneHz, timeMs);
	}
	else
	  buzz.noTone(pin);
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

void reset() //with xbee module, we need to simulate the setup execution that occurs when a usb connection is opened or closed without this module
{
  for (int pos = 0; pos < 10; pos++)  //stop all actuators
  {
    states[pos] = 0;
    digitalWrite(pos + 2, LOW);
  }

  //reset servomotors
//  newInterruption = false;
//  updateServoMotors = false;
  TCNT2 = TIMER2_PRELOAD;

  //protocol handshaking
//  ScratchBoardSensorReport();
  lastDataReceivedTime = millis();
}

void updateActuator(int pinNumber)
{
  if (outputs[pinNumber] == 'd')  digitalWrite(pinNumber + 4, states[pinNumber]);
  else if (outputs[pinNumber] == 'a')  analogWrite(pinNumber + 4, states[pinNumber]);
}
void checkScratchDisconnection() //the reset is necessary when using an wireless arduino board (because we need to ensure that arduino isn't waiting the actuators state from Scratch) or when scratch isn't sending information (because is how serial port close is detected)
{
  if (millis() - lastDataReceivedTime > 1000) reset(); //reset state if actuators reception timeout = one second
}

////////////////////////////interrupt/////////////////////////////////////////

void ius() {
  _iustime = micros() - _itime;
  noInterrupts();
}
