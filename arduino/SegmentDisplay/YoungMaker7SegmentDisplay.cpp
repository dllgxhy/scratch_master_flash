#include "YoungMaker7SegmentDisplay.h"
/*
static int8_t TubeTab[] = { //共阳数码管
                           0xc0,0xf9,0xa4,0xb0,//0~3
                           0x99,0x92,0x82,0xf8,//4~7
                           0x80,0x90,0x88,0x83,//8~b
                           0xc6,0xa1,0x86,0x8e, //c~f 
                           //with dot
                           0x40,0x79,0x24,0x30,//0~3
                           0x19,0x12,0x02,0x78,//4~7
                           0x00,0x10,0x08,0x03,//8~b
                           0x46,0x21,0x06,0x0e,0xbf //c~f,-
                           };
 */
 static int8_t TubeTab[] = { //共阴数码管
                           0x3f,0x06,0x5b,0x4f,//0~3
                           0x66,0x6d,0x7d,0x07,//4~7
                           0x7f,0x6f,0x77,0x7c,//8~b
                           0x39,0x5e,0x79,0x71, //c~f 
                           //with dot
                           0xbf,0x86,0xdb,0xcf,//0~3
                           0xe6,0xed,0xfd,0x87,//4~7
                           0xff,0xef,0xf7,0xfc,//8~b
                           0xb9,0xde,0xf9,0xf1,0x40 //c~f,-
                           };
boolean YoungMaker7SegmentDisplay_first=0;
YoungMaker7SegmentDisplay::YoungMaker7SegmentDisplay():YoungMakerPort()
{
}
YoungMaker7SegmentDisplay::YoungMaker7SegmentDisplay(uint8_t port):YoungMakerPort(port)
{
	DIO = s1;
	SCLK = s2;
        RCLK= s3;
	pinMode(DIO,OUTPUT);
	pinMode(SCLK,OUTPUT);
    pinMode(RCLK,OUTPUT);
	clearDisplay();
}
void YoungMaker7SegmentDisplay::reset(uint8_t port){
    _port = port;
	s1 = youngmakerport[port].s1;
	s2 = youngmakerport[port].s2;
    s3 = youngmakerport[port].s3;
	DIO = s1;
	SCLK = s2;
        RCLK= s3;
	pinMode(DIO,OUTPUT);
	pinMode(SCLK,OUTPUT);
        pinMode(RCLK,OUTPUT);
}
void YoungMaker7SegmentDisplay::display(float value){
  if(!YoungMaker7SegmentDisplay_first)
  {
     redisplay(value);
     YoungMaker7SegmentDisplay_first++;
  }
  if(value!=_disvalue)
  {
    _disvalue=value;
  if((millis()-_distime)>100)
  {
    _distime=millis();
    redisplay(value);
  }
  }

}

void YoungMaker7SegmentDisplay::display(double value){
  if(!YoungMaker7SegmentDisplay_first)
  {
     redisplay(value);
     YoungMaker7SegmentDisplay_first++;
  }
  if(value!=_disvalue)
  {
    _disvalue=value;
  if((millis()-_distime)>100)
  {
    _distime=millis();
    redisplay(value);
  }
  }

}

void YoungMaker7SegmentDisplay::display(int value){
  if(!YoungMaker7SegmentDisplay_first)
  {
     redisplay(value);
     YoungMaker7SegmentDisplay_first++;
  }
  if(value!=_disvalue)
  {
    _disvalue=value;
  if((millis()-_distime)>100)
  {
    _distime=millis();
    redisplay(value);
  }
  }

}

void YoungMaker7SegmentDisplay::redisplay(float value){
	int i=0;
	bool isStart = false;
	int index = 0;
	int8_t disp[]={0,0,0,0};
	bool isNeg = false;
	if(value<0){
		isNeg = true;
		value = -value;
		disp[0] = 0x20;
		index++;
	}
	for(i=0;i<7;i++){
		int n = checkNum(value,3-i);
		if(n>=1||i==3){
			isStart=true;
		}
		if(isStart){
			if(i==3){
				disp[index]=n+0x10;
			}else{
				disp[index]=n;
			}
			index++;
		}
		if(index>3){
			break;
		}
	}
	display(disp);
}

int YoungMaker7SegmentDisplay::pows(int a,int b){
  int c = 1;
  int i =0;
  for(i=0;i<b;i++)
    c *= a;
    return c;
}

int YoungMaker7SegmentDisplay::checkNum(float v,int b){
	if(b>=0){
		return floor((v-floor(v/pows(10,b+1))*(pows(10,b+1)))/pows(10,b));
	}else{
		b=-b;
		int i=0;
		for(i=0;i<b;i++){
			v = v*10;
		}
		return ((int)(v)%10);
	}
}
//******************************************
void YoungMaker7SegmentDisplay::display(int8_t DispData[])
{
  uint8_t i;
  for(i=0;i<4;i++){
           shiftOut(DIO, SCLK, MSBFIRST, TubeTab[DispData[3-i]]); 
           digitalWrite(RCLK, LOW); //刷新显示
           digitalWrite(RCLK, HIGH);
     }    
}
void YoungMaker7SegmentDisplay::clearDisplay(void)
{   
   for(unsigned char x = 0;x<4;x++) {
      shiftOut(DIO, SCLK, MSBFIRST, 0xc0 ); 
      digitalWrite(RCLK, LOW); //刷新显示
      digitalWrite(RCLK, HIGH);
     }
}
