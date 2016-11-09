////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////
//#include <Wire.h>
#include <Servo.h>
#include "CFunPort.h"
#include "CFunDCMotor.h"
#include "CFunAvoid.h"
#include "CFunTrack.h"
#include "CFunUltrasonic.h"
#include "CFun7SegmentDisplay.h"
#include "CFunTemperature.h"
//#include "CFunTemperature2.h"
#include "CFunRGBLed.h"
#include "CFunIR.h"
#include "CFunreadCapacitive.h"
#include "CFunBuzzer.h"
#include "CFunLiquidCrystal.h"

///////////////////////////////Servo/////////////
Servo myservo2;
Servo myservo3;
Servo myservo4;
Servo myservo5;
Servo myservo6;
Servo myservo7;
Servo myservo8;
Servo myservo9;
Servo myservo10;
Servo myservo11;
Servo myservo12;
Servo myservo13;
///////////////////////////////
CFunPort cp;//CFunport
CFunDCMotor dc;
CFunAvoid av;
CFunTrack tr;
CFunTemperature ts;
//CFunTemperature2 ts2;
CFunRGBLed led;
CFunUltrasonic us;
CFun7SegmentDisplay seg;
CFunPort generalDevice;
CFunIR ir;
CFunBuzzer buzz;
CFunLiquidCrystal lcd(0x20, 16, 2); // set the LCD address to 0x20 for a 16 chars and 2 line display
///////////////////////////////////////////////////
#if defined(ARDUINO) && ARDUINO >= 100
#define printByte(args)  write(args);
#else
#define printByte(args)  print(args,BYTE);
#endif
//////////////////////////////////////////////////

union {
  byte byteVal[4];
  float floatVal;
  // long longVal;
} val;

//CFunModule modules[12];
#if defined(__AVR_ATmega32U4__)
int analogs[12] = {A0, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11};
#else
int analogs[8] = {A0, A1, A2, A3, A4, A5, A6, A7};
#endif
boolean isAvailable = false;
boolean isBluetooth = false;
unsigned char Bt[4];
char buffer[52];
char bufferBt[52];
byte index = 0;
byte dataLen;

boolean isStart = false;
unsigned char irRead;
unsigned char irAvaliable = 0; //0:no. 1:yes
char serialRead;
unsigned char prevc = 0;

unsigned int Tgray = 600;//xunxian
float CFun_last_time = 0; //时间清零模块
char _LCD[32] = {0};//LCD1602
///////////////////////////////////////////////////
//boolean _buzz_ir;
//boolean _servo_flag;                //for avoiding servo initial again and again
//boolean _servo_num;                 //for several servo work at the same time
boolean ir_begin = 1;              //for avoiding IR initial again and again

unsigned long _itime;               //for Ultrasonic interrupt function
unsigned long _iustime;             //for Ultrasonic interrupt function

unsigned long _distime;            //seg current time
float _disvalue;                   // store last dispaly value

char _LCD_flag=1;                //ensure LCD intialize only once
/////////////////////////////////////////////////////////////
unsigned char readBuffer(int index);
void writeBuffer(int index, unsigned char c);
void writeEnd();
void writeSerial(unsigned char c) ;
void readSerial();
void dec2bit(int value);
void sendValue(float value);
void parseData();
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
 
  // ir.begin();
}
///////////////////////////////////////////////////////////////////////
void loop() {

  readSerial();
  if (isAvailable) {                         //ruguo you shuju shuru
    unsigned char c = serialRead & 0xff;     //duqu shuru shuju
    if (c == 0x55 && isStart == false ) {    //
      if (prevc == 0xff) {
        index = 1;
        isStart = true;
      }
    } else {
      prevc = c;
      if (isStart) {
        if (index == 2) {
          if(prevc == 0x88){
          dataLen = 32+1; //加复杂模块，字节数要改变，建议加上一个用于表示后面有多少字节的标志位
          }
          else
          dataLen =4+1;
        } else if (index > 2) {
          dataLen--;
        }
        writeBuffer(index, c);
      }
    }
    index++;
    if (index > 40) {
      index = 0;
      isStart = false;
    }
    if (isStart && dataLen == 0 && index > 3) {
      isStart = false;
      parseData();
      index = 0;
    }
  }

}
///////////////////////////////////////////////////////////////////////
unsigned char readBuffer(int index) {
  return isBluetooth ? bufferBt[index] : buffer[index];
}
void writeBuffer(int index, unsigned char c) {
  if (isBluetooth) {
    bufferBt[index] = c;
  } else {
    buffer[index] = c;
  }
}
void writeEnd() {

#if defined(__AVR_ATmega32U4__)
  isBluetooth ? Serial1.println() : Serial.println();
#else
  Serial.println();
#endif
}
void writeSerial(unsigned char c) {
#if defined(__AVR_ATmega32U4__)
  isBluetooth ? Serial1.write(c) : Serial.write(c);
#else
  Serial.write(c);
#endif
}
void readSerial() {
  isAvailable = false;
  if (Serial.available() > 0) {
    isAvailable = true;
    isBluetooth = false;
    serialRead = Serial.read();
  }
#if defined(__AVR_ATmega32U4__)
  else if (Serial1.available() > 0) {
    isAvailable = true;
    isBluetooth = true;
    serialRead = Serial1.read();
  }
#endif
}
void parseData() {
  isStart = false;
  float value = 0.0;
  switch (readBuffer(2)) {
    case 0x01: { //数字量读取
        int pin = readBuffer(3);
        writeSerial(0xEE);
        writeSerial(0x66);
        writeSerial(0x01);
        writeSerial(pin);
        pinMode(pin, INPUT);
        writeSerial(0x00);
        writeSerial(0x00);
        writeSerial(0x00);
        writeSerial(digitalRead(pin));
        //writeEnd();
      }
      break;
    case 0x02: { //模拟量读取
        char pin = readBuffer(3);
        writeSerial(0xEE);
        writeSerial(0x66);
        writeSerial(0x02);
        writeSerial(pin);
        pinMode(analogs[pin], INPUT);
        dec2bit(analogRead(analogs[pin]));
        /*
        writeSerial(Bt[3]);
        writeSerial(Bt[2]);
        writeSerial(Bt[1]);
        writeSerial(Bt[0]);
        */
        // writeEnd();
      }
      break;
    case 0x03: { //LM35温度传感器
        int pin = readBuffer(3);
        writeSerial(0xEE);
        writeSerial(0x66);
        writeSerial(0x03);
        writeSerial(pin);
        ts.reset(pin);
        sendValue(ts.temperature());
        // writeEnd();
      }
      break;

    case 0x04: { //超声波传感器
        value = us.distanceCm();
        writeSerial(0xEE);
        writeSerial(0x66);
        writeSerial(0x04);
        writeSerial(0x00);
        sendValue(value);
      }
      break;
    case 0x05: { //摇杆模块(X)
        int pin = readBuffer(3);
        writeSerial(0xEE);
        writeSerial(0x66);
        writeSerial(0x05);
        writeSerial(pin);
        pinMode(analogs[pin], INPUT);
        dec2bit(analogRead(analogs[pin]));
        /*
        writeSerial(Bt[3]);
        writeSerial(Bt[2]);
        writeSerial(Bt[1]);
        writeSerial(Bt[0]);
        */
        //writeEnd();
      }
      break;
    case 0x06: { //摇杆模块(Y)
        int pin = readBuffer(3);
        writeSerial(0xEE);
        writeSerial(0x66);
        writeSerial(0x06);
        writeSerial(pin);
        pinMode(analogs[pin], INPUT);
        dec2bit(analogRead(analogs[pin]));
        /*
        writeSerial(Bt[3]);
        writeSerial(Bt[2]);
        writeSerial(Bt[1]);
        writeSerial(Bt[0]);
        */
        // writeEnd();
      }
      break;
    case 0x07: { //摇杆模块(K)
        int pin = readBuffer(3);
        writeSerial(0xEE);
        writeSerial(0x66);
        writeSerial(0x07);
        writeSerial(pin);
        pinMode(analogs[pin], INPUT);
        dec2bit(analogRead(analogs[pin]));
        /*
        writeSerial(Bt[3]);
        writeSerial(Bt[2]);
        writeSerial(Bt[1]);
        writeSerial(Bt[0]);
        */
        //writeEnd();
      }
      break;
    case 0x08: { //触摸模块
        int pin = readBuffer(3);
        writeSerial(0xEE);
        writeSerial(0x66);
        writeSerial(0x08);
        writeSerial(pin);
        writeSerial(0x00);
        writeSerial(0x00);
        writeSerial(0x00);
        writeSerial(readCapacitivePin(pin));
        //writeEnd();
      }

      break;
      //     case 0x09:{ //DS18B20测温模块
      //      int pin = readBuffer(3);
      //        writeSerial(0xEE);
      //        writeSerial(0x66);
      //        writeSerial(0x09);
      //        writeSerial(pin);
      //        sendValue(value);
      //
      //        //writeEnd();
      //     }
      //     break;
    case 0x0A: { //计时模块

        value = millis() - CFun_last_time;
        value = value / 1000.0;
        writeSerial(0xEE);
        writeSerial(0x66);
        writeSerial(0x0A);
        writeSerial(0x00);
        sendValue(value);
      }
      break;
      ////////////////////////////////////////////////////////////////////////////////////////////
      /////////////////////minicar part//////////////////////
      ///////////////////////////////////////////////////////////////////////////////////////////
    case 0x50: { //avoid
        writeSerial(0xEE);
        writeSerial(0x66);
        writeSerial(0x50);
        writeSerial(0x00);
        writeSerial(0x00);
        writeSerial(0x00);
        writeSerial(0x00);
        writeSerial(av.Avoid());
        //writeEnd();
      }
      break;
      //    case 0x51: { //ultransonic
      //        value = us.distanceCm();
      //        writeSerial(0xEE);
      //        writeSerial(0x66);
      //        writeSerial(0x51);
      //        writeSerial(0x00);
      //        sendValue(value);
      //      }
      //      break;
    case 0x52: { //track
        ///////////////////////digital////////////////////////////
        writeSerial(0xEE);
        writeSerial(0x66);
        writeSerial(0x52);
        writeSerial(0x00);
        dec2bit(tr.Track(Tgray));
        /*
        writeSerial(Bt[3]);
        writeSerial(Bt[2]);
        writeSerial(Bt[1]);
        writeSerial(Bt[0]);
        */
        //writeEnd();
      }
      break;
    case 0x53: { //voltage measure
        value = cp.minicarVolt();
        writeSerial(0xEE);
        writeSerial(0x66);
        writeSerial(0x53);
        writeSerial(0x00);
        sendValue(value);
      }
      break;
    case 0x54: { //IR:
        int pin = readBuffer(3);
        if (ir_begin)
        {
          ir.begin(pin);
          ir_begin = 0;
        }
        irAvaliable = 1;
        writeSerial(0xEE);
        writeSerial(0x66);
        writeSerial(0x54);
        writeSerial(pin);
        writeSerial(0x00);
        writeSerial(0x00);
        writeSerial(0x00);
        writeSerial(ir.getCode());
        // irRead = 0;
      }
      break;


    case 0xA0: { //forward
        int dataIndex = 3;
        int pin = readBuffer(dataIndex++);
        ///////////////////////digital////////////////////////////
        val.byteVal[3] = readBuffer(dataIndex++);
        val.byteVal[2] = readBuffer(dataIndex++);
        val.byteVal[1] = readBuffer(dataIndex++);
        val.byteVal[0] = readBuffer(dataIndex++);

        dc.forward(val.byteVal[0]);
      }
      break;

    case 0xA1: { //back
        int dataIndex = 3;
        int pin = readBuffer(dataIndex++);
        ///////////////////////digital////////////////////////////
        val.byteVal[3] = readBuffer(dataIndex++);
        val.byteVal[2] = readBuffer(dataIndex++);
        val.byteVal[1] = readBuffer(dataIndex++);
        val.byteVal[0] = readBuffer(dataIndex++);
        dc.back(val.byteVal[0]);
      }
      break;


    case 0xA2: { //turnleft
        int dataIndex = 3;
        int pin = readBuffer(dataIndex++);
        ///////////////////////digital////////////////////////////
        val.byteVal[3] = readBuffer(dataIndex++);
        val.byteVal[2] = readBuffer(dataIndex++);
        val.byteVal[1] = readBuffer(dataIndex++);
        val.byteVal[0] = readBuffer(dataIndex++);
        dc.turnleft(val.byteVal[0]);
      }
      break;

    case 0xA3: { //turnright
        int dataIndex = 3;
        int pin = readBuffer(dataIndex++);
        ///////////////////////digital////////////////////////////
        val.byteVal[3] = readBuffer(dataIndex++);
        val.byteVal[2] = readBuffer(dataIndex++);
        val.byteVal[1] = readBuffer(dataIndex++);
        val.byteVal[0] = readBuffer(dataIndex++);
        dc.turnright(val.byteVal[0]);
      }
      break;

    case 0xA5: { //track value
        int dataIndex = 3;
        int pin = readBuffer(dataIndex++);
        ///////////////////////digital////////////////////////////
        val.byteVal[3] = readBuffer(dataIndex++);
        val.byteVal[2] = readBuffer(dataIndex++);
        val.byteVal[1] = readBuffer(dataIndex++);
        val.byteVal[0] = readBuffer(dataIndex++);
        Tgray = val.byteVal[1] * 256 + val.byteVal[0];

      }
      break;

      ///////////////////////////////////////////////////////
      ////////////////keep for others sensor///////////////
      //////////////////////////////////////////////////////
    case 0x81: { //digital write
        int dataIndex = 3;
        int pin = readBuffer(dataIndex++);
        ///////////////////////digital////////////////////////////
        val.byteVal[3] = readBuffer(dataIndex++);
        val.byteVal[2] = readBuffer(dataIndex++);
        val.byteVal[1] = readBuffer(dataIndex++);
        val.byteVal[0] = readBuffer(dataIndex++);
        pinMode(pin, OUTPUT);
        digitalWrite(pin, val.byteVal[0] >= 1 ? HIGH : LOW);
      }
      break;
    case 0x82: { //PWM
        int dataIndex = 3;
        int pin = readBuffer(dataIndex++);
        ///////////////////////digital////////////////////////////
        val.byteVal[3] = readBuffer(dataIndex++);
        val.byteVal[2] = readBuffer(dataIndex++);
        val.byteVal[1] = readBuffer(dataIndex++);
        val.byteVal[0] = readBuffer(dataIndex++);
        pinMode(pin, OUTPUT);
        analogWrite(pin, val.byteVal[0]);
      }
      break;
    case 0x83: { //舵机模块
        int dataIndex = 3;
        int pin = readBuffer(dataIndex++);
        //     _servo_flag = 1;
        // int angle;
        ///////////////////////digital////////////////////////////
        val.byteVal[3] = readBuffer(dataIndex++);
        val.byteVal[2] = readBuffer(dataIndex++);
        val.byteVal[1] = readBuffer(dataIndex++);
        val.byteVal[0] = readBuffer(dataIndex++);
        //        if (val.byteVal[0] != angle) {
        //          angle = val.byteVal[0];
        //          if (_servo_flag)
        //          {
        //            _servo_flag = 0;
        //            myservo.attach(pin);  // attaches the servo on pin 9 to the servo object
        //          }
        //          //  myservo.attach(pin);  // attaches the servo on pin 9 to the servo object
        //          myservo.write(val.byteVal[0]);              // tell servo to go to position in variable 'pos'
        //        }
        switch (pin) {
          case 2: {
              myservo2.attach(2);
              myservo2.write(val.byteVal[0]);

            }
            break;
          case 3: {
              myservo3.attach(3);
              myservo3.write(val.byteVal[0]);

            }
            break;
          case 4: {
              myservo4.attach(4);
              myservo4.write(val.byteVal[0]);

            }
            break;
          case 5: {
              myservo5.attach(5);
              myservo5.write(val.byteVal[0]);

            }
            break;
          case 6: {
              myservo6.attach(6);
              myservo6.write(val.byteVal[0]);

            }
            break;
          case 7: {
              myservo7.attach(7);
              myservo7.write(val.byteVal[0]);

            }
            break;
          case 8: {
              myservo8.attach(8);
              myservo8.write(val.byteVal[0]);

            }
            break;
          case 9: {
              myservo9.attach(9);
              myservo9.write(val.byteVal[0]);

            }
            break;
          case 10: {
              myservo10.attach(10);
              myservo10.write(val.byteVal[0]);

            }
            break;
          case 11: {
              myservo11.attach(11);
              myservo11.write(val.byteVal[0]);

            }
            break;
          case 12: {
              myservo12.attach(12);
              myservo12.write(val.byteVal[0]);

            }
            break;
          case 13: {
              myservo13.attach(13);
              myservo13.write(val.byteVal[0]);

            }
            break;
        }
      }
      break;
    case 0x84: { //无源蜂鸣器
        int dataIndex = 3;
        int pin = readBuffer(dataIndex++);
        ///////////////////////digital////////////////////////////
        val.byteVal[3] = readBuffer(dataIndex++);
        val.byteVal[2] = readBuffer(dataIndex++);
        val.byteVal[1] = readBuffer(dataIndex++);
        val.byteVal[0] = readBuffer(dataIndex++);
        pinMode(pin, OUTPUT);
        int toneHz = val.byteVal[3] * 256 + val.byteVal[2];
        int timeMs = val.byteVal[1] * 255 + val.byteVal[0];
        if (timeMs != 0) {
          buzz.tone(pin, toneHz, timeMs);
        }
        else
          buzz.noTone(pin);

      }
      break;
    case 0x85: { //串行数码管
        int dataIndex = 3;
        int pin = readBuffer(dataIndex++);
        ///////////////////////digital////////////////////////////
        val.byteVal[3] = readBuffer(dataIndex++);
        val.byteVal[2] = readBuffer(dataIndex++);
        val.byteVal[1] = readBuffer(dataIndex++);
        val.byteVal[0] = readBuffer(dataIndex++);
        seg.reset(pin);
        seg.display(val.floatVal);
      }
      break;
    case 0x86: { //电机模块
        int dataIndex = 3;
        int pin = readBuffer(dataIndex++);
        ///////////////////////digital////////////////////////////
        val.byteVal[3] = readBuffer(dataIndex++);
        val.byteVal[2] = readBuffer(dataIndex++);
        val.byteVal[1] = readBuffer(dataIndex++);
        val.byteVal[0] = readBuffer(dataIndex++);
        dc.reset(pin);
        dc.motorrun(val.byteVal[1], val.byteVal[0]);
      }
      break;
    case 0x87: { //三色LED
        int dataIndex = 3;
        int pin = readBuffer(dataIndex++);
        int index = readBuffer(dataIndex++);
        int red = readBuffer(dataIndex++);
        int green = readBuffer(dataIndex++);
        int blue = readBuffer(dataIndex++);
        //   led.reset(9);
        led.setColorAt(red, green, blue);
      }
      break;

    case 0x88: { //LCD1602
        if(_LCD_flag)
       { 
         lcd.init();
         _LCD_flag = 0; 
       } 
        
        int dataIndex = 3;
        int pin = readBuffer(dataIndex++);
        for (int i = 0; i < 32; i++)
        {
          _LCD[i] = readBuffer(dataIndex++);
        }
        //  pinMode(pin, OUTPUT);
        //  digitalWrite(13, LOW);
        lcd.LiquidCrystaldisplay(_LCD);
      }
      break;

    case 0x89: { //Timer清零
        CFun_last_time = millis();
      }
      break;
  }
}


void InsertionSort(int* array, int n)
{
  for (int i = 1; i < n; i++)
    for (int j = i; (j > 0) && ( array[j] < array[j-1] ); j--)
      swap( array, j, j-1 );
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


void sendValue(float value) {
  val.floatVal = value;
  writeSerial(val.byteVal[3]);
  writeSerial(val.byteVal[2]);
  writeSerial(val.byteVal[1]);
  writeSerial(val.byteVal[0]);
}
void dec2bit(int value) {
  int dec = value;
  Bt[3] = 0x00;
  Bt[2] = 0x00;
  Bt[1] = (dec >> 8) & 0xff;
  Bt[0] = dec;
  writeSerial(Bt[3]);
  writeSerial(Bt[2]);
  writeSerial(Bt[1]);
  writeSerial(Bt[0]);
}
////////////////////////////interrupt/////////////////////////////////////////

void ius() {
  _iustime = micros() - _itime;
  noInterrupts();
}
