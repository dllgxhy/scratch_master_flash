#include "YoungMakerTemperature.h"
YoungMakerTemperature::YoungMakerTemperature():YoungMakerPort(){
}
YoungMakerTemperature::YoungMakerTemperature(uint8_t port):YoungMakerPort(port){
	_port = port;
	s1 = youngmakerport[port+12].s1;
        LM35=s1;
        pinMode(LM35,INPUT);
}
void YoungMakerTemperature::reset(uint8_t port){
        _port = port;
	s1 = youngmakerport[port+12].s1;
        LM35=s1;
        pinMode(LM35,INPUT);
}
float YoungMakerTemperature::temperature(){
        int LM35_val=analogRead(LM35);//温度传感器LM35接到模拟PIN0上；val变量为从LM35信号口读取到的数值
        float temp = (LM35_val*0.0048828125*100); //把读取到的val转换为温度数值,系数一：0.00488125=5/1024,0~5V对应模拟口读数1~1024,系数二：100=1000/10,1000是毫伏与伏的转换；10是每10毫伏对应一度温升。
        return temp;
}
