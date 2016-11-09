#ifndef CFun7SegmentDisplay_H
#define CFun7SegmentDisplay_H 
#include "CFunPort.h"
//************definitions for TM1637*********************
#define ADDR_AUTO 0x40
#define ADDR_FIXED 0x44
#define STARTADDR 0xc0
/**** definitions for the clock point of the digit tube *******/
#define POINT_ON 1
#define POINT_OFF 0
/**************definitions for brightness***********************/
#define BRIGHT_DARKEST 0
#define BRIGHT_TYPICAL 2
#define BRIGHTEST 7
///@brief Class for numeric display module
extern unsigned long _distime; 
extern float _disvalue;
class CFun7SegmentDisplay:public CFunPort
{
	public:
		CFun7SegmentDisplay();
		CFun7SegmentDisplay(uint8_t port);
                void reset(uint8_t port);
                void redisplay(float value);
		void display(float value);
                void display(double value);
                void display(int value);
                void display(int8_t DispData[]);
		void clearDisplay(void);
	private:
                int pows(int a,int b);
		int checkNum(float v,int b);
		uint8_t DIO;
		uint8_t SCLK;
                uint8_t RCLK;
}; 
#endif
