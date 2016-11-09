/*
 * Scratch Project Editor and Player
 * Copyright (C) 2014 Massachusetts Institute of Technology
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

// .as
// , June 2010
//
//  primitives.

package primitives {
	import blocks.Block;
	import flash.utils.Dictionary;
	import interpreter.*;
	import scratch.*;
	import flash.utils.ByteArray;
	import flash.filesystem.FileMode;

public class CfunPrims {

	private var app:Scratch;
	private var interp:Interpreter;
	
	//arduino
	public var ArduinoFlag:Boolean      = false;        //是否需要生成Arduino程序
	public var ArduinoLoopFlag:Boolean  = false;    //是否进入Loop
	public var ArduinoReadFlag:Boolean  = false;    //当前同一条目下是否为读操作
	public var ArduinoReadStr:Array     = new Array;   //先存储读的Arduino语句
	public var ArduinoValueFlag:Boolean = false;   //是否有变量保持字符类型
	public var ArduinoValueStr:String   = new String;//变量字符型
	public var ArduinoMathFlag:Boolean  = false;    //是否有运算保持字符类
	public var ArduinoMathStr:Array     = new Array;   //运算字符型
	public var ArduinoMathNum:Number    = 0;          //运算嵌入层数
	
	//Arduino 中可驱动的模块
	public var ArduinoUs:Boolean  = false;//超声波
	public var ArduinoSeg:Boolean = false;//数码管
	public var ArduinoRGB:Boolean = false;//三色灯
	public var ArduinoBuz:Boolean = false;//无源蜂鸣器
	public var ArduinoCap:Boolean = false;//电容值
	public var ArduinoDCM:Boolean = false;//方向电机
	public var ArduinoSer:Boolean = false;//舵机
	public var ArduinoIR:Boolean  = false;//红外遥控
	public var ArduinoTem:Boolean = false;//温度
	public var ArduinoAvo:Boolean = false;//避障
	public var ArduinoTra:Boolean = false;//循迹
	public var ArduinoLCD1602:Boolean = false;//LCD1602
	

	public function CfunPrims(app:Scratch, interpreter:Interpreter) {
		this.app = app;
		this.interp = interpreter;
	}

	public function addPrimsTo(primTable:Dictionary):void {
		
		//  Arduino Block
		primTable["whenArduino"]           = primArduino;   //Arduino程序头_wh
		
		primTable["readdigital:"]          = primReadDio;   //读数字口输入
		primTable["readanalog:"]           = primReadAio;   //读数字口输入
		primTable["setdigital:"]           = primSetDigital;//写数字口输出_wh
		primTable["setpwm:"]               = primSetPWM;    //写PWM口输出_wh
		
		primTable["readcap:"]              = primReadByte;//读数字口输入_wh
		primTable["readcapSend:"]          = primReadCap;//读数字口输入命令发送_wh
		
		primTable["readfraredR:"]          = primReadByte;//读红外遥控输入_wh
		primTable["readfraredRSend:"]      = primReadFraredR;//读红外遥控输入_wh
		
		primTable["readAfloat:"]           = primReadFloat;//读模拟口输入float值_wh
		primTable["readAfloatSend:"]       = primReadAFloat;//读模拟口输入float值命令发送_wh
		primTable["readPfloat:"]           = primReadFloat;//读超声波输入float值_wh
		primTable["readPfloatSend:"]       = primReadPFloat;//读超声波输入float值命令发送_wh
		
		primTable["setsg:"]                = primSetSG;//写舵机输出角度_wh
		primTable["setdm:"]                = primSetDM;//写电机正负PWM输出_wh
		primTable["setnum:"]               = primSetNUM;//写数码管输出值_wh
		primTable["setrgb:"] 			   = primSetRGB;//写RGB颜色
		primTable["setmusic:"]             = primSetMUS;//写无源蜂鸣器音乐输出值_wh
		primTable["setLCD1602string:"]     = primSetLCD1602String;
		
		//Arduino Robot   板上的固定的传感器
		primTable["readcksound"]			= function(b:*):* { return app.arduinoLib.arduinoSoundValue};
		primTable["readckslide"]	        = function(b:*):* { return app.arduinoLib.arduinoSlideValue};
		primTable["readcklight"]		    = function(b:*):* { return app.arduinoLib.arduinoLightValue};
		primTable["readckUltrasonicSensor"]	= function(b:*):* { return app.arduinoLib.arduinoUltrasonicValue};	
		
		primTable["readtrack:"]             = primReadShort;//读循迹输入_wh
		primTable["readtrackSend:"]         = primReadTrack;//读循迹输入_wh
		primTable["readavoid:"]             = primReadShort;//读红外避障输入_wh
		primTable["readavoidSend:"]         = primReadAvoid;//读红外避障输入_wh
		
		primTable["readpower:"]             = primReadFloat;//读电量输入_wh
		primTable["readpowerSend:"]         = primReadPower;//读电量输入_wh
		primTable["setgray:"]               = primSetgray;//写机器人灰度阀值_wh
		primTable["setforward:"]            = primSetforward;//写机器人前进速度_wh
		primTable["setback:"]               = primSetback;//写机器人后退速度_wh
		primTable["setleft:"]               = primSetleft;//写机器人左转弯速度_wh
		primTable["setright:"]              = primSetright;//写机器人右转弯速度_wh	
	}
	
	
	private function primArduino(b:Block):void
	{	
		app.arduinoLib.ArduinoLoopFlag    = false;
		app.arduinoLib.ArduinoBracketFlag = 0;
		app.arduinoLib.ArduinoMathFlag    = false;
		app.arduinoLib.ArduinoReadFlag    = false;
		app.arduinoLib.ArduinoValueFlag   = false;
		app.arduinoLib.ArduinoIEFlag      = 0;
		app.arduinoLib.ArduinoIEElseFlag  = 0;
		app.arduinoLib.ArduinoIEFlagIE    = false;
		app.arduinoLib.ArduinoIEFlagAll   = 0;
		app.arduinoLib.ArduinoIEElseNum   = 0;
		app.arduinoLib.ArduinoWarnFlag    = false;
		app.arduinoLib.ArduinoIEFlag2     = 0;
		//app.ArduinoIEBracketFlag = 0;
		
		app.arduinoLib.ArduinoUs  = false;//超声波_wh
		app.arduinoLib.ArduinoSeg = false;//数码管_wh
		app.arduinoLib.ArduinoRGB = false;//三色灯_wh
		app.arduinoLib.ArduinoBuz = false;//无源蜂鸣器_wh
		app.arduinoLib.ArduinoCap = false;//电容值_wh
		app.arduinoLib.ArduinoDCM = false;//方向电机_wh
		app.arduinoLib.ArduinoSer = false;//舵机_wh
		app.arduinoLib.ArduinoIR  = false;//红外遥控_wh
		app.arduinoLib.ArduinoTem = false;//温度_wh
		app.arduinoLib.ArduinoAvo = false;//避障_wh
		app.arduinoLib.ArduinoTra = false;//循迹_wh
		
		app.arduinoLib.ArduinoFlag = true;
		app.arduinoLib.ArduinoPin = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
		var j:Number = 0;
		for(var i:Number = 0; i <= 0xfff; i++)
		{
			switch (i)
			{
				case app.arduinoUart.ID_ReadAFloat:for(j = 0; j <= 13; j++)  app.arduinoLib.ArduinoBlock[app.arduinoUart.ID_ReadAFloat][j] = 0;break;
				case app.arduinoUart.ID_ReadPFloat:for(j = 0; j <= 13; j++)  app.arduinoLib.ArduinoBlock[app.arduinoUart.ID_ReadPFloat][j] = 0;break;
				case app.arduinoUart.ID_SetSG:for(j = 0; j <= 13; j++)  app.arduinoLib.ArduinoBlock[app.arduinoUart.ID_SetSG][j] = 0;break;
				case app.arduinoUart.ID_SetDM:for(j = 0; j <= 13; j++)  app.arduinoLib.ArduinoBlock[app.arduinoUart.ID_SetDM][j] = 0;break;
				case app.arduinoUart.ID_SetNUM:for(j = 0; j <= 13; j++)  app.arduinoLib.ArduinoBlock[app.arduinoUart.ID_SetNUM][j] = 0;break;
				case app.arduinoUart.ID_SetMUS:for(j = 0; j <= 13; j++)  app.arduinoLib.ArduinoBlock[app.arduinoUart.ID_SetMUS][j] = 0;break;
				default:app.arduinoLib.ArduinoBlock[i] = 0;break;
			}
		}
		
		app.arduinoLib.ArduinoPinFs.open(app.arduinoLib.ArduinoPinFile,FileMode.WRITE);
		app.arduinoLib.ArduinoPinFs.position = 0;
		
		app.arduinoLib.ArduinoDoFs.open(app.arduinoLib.ArduinoDoFile,FileMode.WRITE);
		app.arduinoLib.ArduinoDoFs.position = 0;
		
		app.arduinoLib.ArduinoHeadFs.open(app.arduinoLib.ArduinoHeadFile,FileMode.WRITE);
		app.arduinoLib.ArduinoHeadFs.position = 0;
		
		app.arduinoLib.ArduinoLoopFs.open(app.arduinoLib.ArduinoLoopFile,FileMode.WRITE);
		app.arduinoLib.ArduinoLoopFs.position = 0;
		
		app.arduinoLib.ArduinoFs.open(app.arduinoLib.ArduinoFile,FileMode.WRITE);
		app.arduinoLib.ArduinoFs.position = 0;
	}
	
	//读数字口输入
	private function primReadDio(b:Block):Boolean
	{			
		var pin:Number = interp.numarg(b, 0);//引脚号，模块参数第一个，参数类型为数字
		switch(pin)
		{
			case 0x02:
				return app.arduinoLib.arduinoDIOPin2;
			case 0x03:
				return app.arduinoLib.arduinoDIOPin3;
			case 0x04:
				return app.arduinoLib.arduinoDIOPin4;
			case 0x05:
				return app.arduinoLib.arduinoDIOPin5;
			case 0x06:
				return app.arduinoLib.arduinoDIOPin6;
			case 0x07:
				return app.arduinoLib.arduinoDIOPin7;
			case 0x08:
				return app.arduinoLib.arduinoDIOPin8;
			case 0x09:
				return app.arduinoLib.arduinoDIOPin9;
			case 0x0a:
				return app.arduinoLib.arduinoDIOPin10;
			case 0x0b:
				return app.arduinoLib.arduinoDIOPin11;
			case 0x0c:
				return app.arduinoLib.arduinoDIOPin12;
			case 0x0d:
				return app.arduinoLib.arduinoDIOPin13;
			default:
				break;			
		}
		return false;
	}
	
	//读模拟口输入
	private function primReadAio(b:Block):Boolean
	{			
		var pin:Number = interp.numarg(b, 0);//引脚号，模块参数第一个，参数类型为数字
		switch(pin)
		{
			case 0x00:
				return app.arduinoLib.arduinoAIOPin0;
			case 0x01:
				return app.arduinoLib.arduinoAIOPin1;
			case 0x02:
				return app.arduinoLib.arduinoAIOPin2;
			case 0x03:
				return app.arduinoLib.arduinoAIOPin3;
			case 0x04:
				return app.arduinoLib.arduinoAIOPin4;
			case 0x05:
				return app.arduinoLib.arduinoAIOPin5;
			default:
				break;			
		}
		return false;
	}
	
	private function primSetDigital(b:Block):Boolean
	{
		app.xuhy_test_log("primSetDigital");
		var pin:Number = interp.numarg(b, 0);  //找到需要设置的IO口
		
		var DIOStatus:Number = 0x00;           //找到该IO口需要设置的数据
		if(interp.arg(b,1) == 'low')
			DIOStatus = 0;
		else
			DIOStatus = 1;
		return  false;
		// 下发通讯协议			
	}
	
	/************************************
	Model arduino: 设置PWM输出
	模块参数
	@param1：管脚号
	@param2：PWM值
	************************************/
	private function primSetPWM(b:Block):void
	{
		app.xuhy_test_log("设置PWM输出");
		var pin:Number = app.interp.numarg(b,0);//引脚号，模块参数第一个，参数类型为数字_wh
		var pwm:Number = app.interp.numarg(b,1);//PWM值，模块参数第一个，参数类型为数字_wh
		if(app.arduinoLib.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			app.arduinoLib.ArduinoMathNum = 0;
			if(app.arduinoLib.ArduinoPin[pin] == 0)
			{
				app.arduinoLib.ArduinoPinFs.writeUTFBytes("pinMode(" + pin + ",OUTPUT);" + '\n');
				app.arduinoLib.ArduinoPin[pin] = 2;
			}
			
			var strcp:Array = new Array();
			strcp[0] = pin.toString();
			
			if(app.arduinoLib.ArduinoValueFlag == true)
			{
				strcp[1] = app.arduinoLib.ArduinoValueStr;
				app.arduinoLib.ArduinoValueFlag = false;
			}
			else
			{
				if(app.arduinoLib.ArduinoMathFlag == true)
				{
					strcp[1] = app.arduinoLib.ArduinoMathStr[0];
					app.arduinoLib.ArduinoMathFlag = false;
				}
				else
				{
					if(app.arduinoLib.ArduinoReadFlag == true)
					{
						strcp[1] = app.arduinoLib.ArduinoReadStr[0];
						app.arduinoLib.ArduinoReadFlag = false;
					}
					else
					{
						strcp[1] = pwm.toString();
					}
				}
			}			
			if(app.arduinoLib.ArduinoLoopFlag == true)
			{
				app.arduinoLib.ArduinoLoopFs.writeUTFBytes("analogWrite(" + strcp[0] + "," + strcp[1] + ");" + '\n');
			}
			else
			{
				app.arduinoLib.ArduinoDoFs.writeUTFBytes("analogWrite(" + strcp[0] + "," + strcp[1] + ");" + '\n');
			}
		}
		else//正常上位机运行模式_wh
		{
			//内嵌模块，没有有效返回_wh
			if(app.interp.activeThread.ArduinoNA)//加有效性判断_wh
			{
				app.interp.activeThread.ArduinoNA = false;
				return;
			}
			
			//通信协议：0xff 0x55; 0x82（IO输出PWM类型）; pin（管脚号）; pwm（WPM量）_wh 

//			app.arduino.writeByte(ID_SetPWM);
//			app.arduino.writeByte(pin);
//			app.arduino.writeByte(pwm);
//			app.CFunDelayms(5);//延时15ms_wh
		}
	}
	
	/************************************
	Model arduino: 设置舵机角度
	模块参数
	@param1：管脚号
	@param2：舵机转动角度
	************************************/
	private function primSetSG(b:Block):void
	{
		app.xuhy_test_log("设置舵机角度");
		if(app.arduinoLib.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			app.arduinoLib.ArduinoSer = true;
			app.arduinoLib.ArduinoMathNum = 0;
			var pin:Number = app.interp.numarg(b,0);//引脚号，模块参数第一个，参数类型为数字_wh
			if(app.arduinoLib.ArduinoBlock[app.arduinoUart.ID_SetSG][pin] == 0)
			{
				app.arduinoLib.ArduinoHeadFs.writeUTFBytes("Servo myservo" + pin +";" + '\n');
				app.arduinoLib.ArduinoBlock[app.arduinoUart.ID_SetSG][pin] = 1;
			}
			
			if(app.arduinoLib.ArduinoPin[pin] == 0)
			{
				app.arduinoLib.ArduinoPinFs.writeUTFBytes("pinMode(" + pin + ",OUTPUT);" + '\n');
				app.arduinoLib.ArduinoPin[pin] = 2;
			}
			
			var strcp:String = new String();
			var angle:Number = app.interp.numarg(b,1);//角度值，模块参数第一个，参数类型为数字_wh
			if(app.arduinoLib.ArduinoValueFlag == true)
			{
				strcp = app.arduinoLib.ArduinoValueStr;
				app.arduinoLib.ArduinoValueFlag = false;
			}
			else
				if(app.arduinoLib.ArduinoMathFlag == true)
				{
					strcp = app.arduinoLib.ArduinoMathStr[0];
					app.arduinoLib.ArduinoMathFlag = false;
				}
				else
					if(app.arduinoLib.ArduinoReadFlag == true)
					{
						strcp = app.arduinoLib.ArduinoReadStr[0];
						app.arduinoLib.ArduinoReadFlag = false;
					}
					else
						strcp = angle.toString();
			
			if(app.arduinoLib.ArduinoLoopFlag == true)
			{
				app.arduinoLib.ArduinoLoopFs.writeUTFBytes("myservo" +pin + ".attach(" + pin + ");" + '\n');
				app.arduinoLib.ArduinoLoopFs.writeUTFBytes("myservo" +pin + ".write(" + strcp + ");" + '\n');
			}
			else
			{
				app.arduinoLib.ArduinoDoFs.writeUTFBytes("myservo" +pin + ".attach(" + pin + ");" + '\n');
				app.arduinoLib.ArduinoDoFs.writeUTFBytes("myservo" +pin + ".write(" + strcp + ");" + '\n');
			}
		}
		else
		{
			pin = app.interp.numarg(b,0);//引脚号，模块参数第一个，参数类型为数字_wh
			angle = app.interp.numarg(b,1);//角度值，模块参数第一个，参数类型为数字_wh
			//内嵌模块，没有有效返回_wh
			if(app.interp.activeThread.ArduinoNA)//加有效性判断_wh
			{
				app.interp.activeThread.ArduinoNA = false;
				return;
			}
			
			//通信协议：0xff 0x55; 0x83（舵机角度类型）; pin（管脚号）; 角度_wh 
			var numf:Array = new Array();
			numf[0] = app.arduinoUart.ID_SetSG;
			numf[1] = pin;
			numf[2] = angle;
				
			//通信协议：0xff 0x55; 0x86（电机正负PWM类型）; pin（管脚号）; pwm（WPM量）_wh 	
			app.arduinoUart.sendDataToUartBuffer(numf);
		}
	}
	
		/*
	模块的作用分为两种：
	1) 生成固件，直接下载到arduino板子当中
	2) 通过串口下发控制数据
	以上两种作用的区分参数为ArduinoFlag。
	ArduinoFlag = true ：判断为Arduino语句生成过程
	ArduinoFlag = false：判断为串口下发数据
	
	primSetDM():设置直流电机的驱动 方向 转速等
	*/
	private function primSetDM(b:Block):void
	{
		var pins:String;
		var pin:Number;
		if(app.arduinoLib.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			app.arduinoLib.ArduinoDCM = true;
			app.arduinoLib.ArduinoMathNum = 0;
			pins = interp.arg(b,0);//引脚号，模块参数第一个，参数类型为数字_wh
			if(pins == "M1")
				pin = 5;
			else
				pin = 6;
			
			if(app.arduinoLib.ArduinoBlock[app.arduinoUart.ID_SetDM][pin] == 0)
			{
				app.arduinoLib.ArduinoHeadFs.writeUTFBytes("YoungMakerDCMotor   dcMotor" + pin + "(" + pin + ");" + '\n');
				app.arduinoLib.ArduinoBlock[app.arduinoUart.ID_SetDM][pin] = 1;
			}
//				if(app.ArduinoBlock[ID_DIR] == 0)
//				{
//					app.ArduinoHeadFs.writeUTFBytes("double dir_cfun;" + '\n');
//					app.ArduinoBlock[ID_DIR] = 1;
//				}
			
			if(app.arduinoLib.ArduinoPin[pin] == 0)
			{
				app.arduinoLib.ArduinoPinFs.writeUTFBytes("pinMode(" + pin + ",OUTPUT);" + '\n');
				app.arduinoLib.ArduinoPin[pin] = 2;
			}
			if(app.arduinoLib.ArduinoPin[pin+2] == 0)
			{
				app.arduinoLib.ArduinoPinFs.writeUTFBytes("pinMode(" + (pin+2) + ",OUTPUT);" + '\n');
				app.arduinoLib.ArduinoPin[pin+1] = 2;
			}
			
			var strcp:Array = new Array;
			strcp[0] = pin.toString();
			
			//注意：方向电机中不能为
			var dirs:String = interp.arg(b,1);
			var pwm:Number = interp.numarg(b,2);//角度值，模块参数第一个，参数类型为数字_wh
			if(app.arduinoLib.ArduinoValueFlag == true)
			{
				strcp[1] = app.arduinoLib.ArduinoValueStr;
				app.arduinoLib.ArduinoValueFlag = false;
			}
			else
				if(app.arduinoLib.ArduinoMathFlag == true)
				{
					strcp[1] = app.arduinoLib.ArduinoMathStr[0];
					app.arduinoLib.ArduinoMathFlag = false;
				}
				else
					if(app.arduinoLib.ArduinoReadFlag == true)
					{
						strcp[1] = app.arduinoLib.ArduinoReadStr[0];
						app.arduinoLib.ArduinoReadFlag = false;
					}
					else
						strcp[1] = pwm.toString();
			
			if(app.arduinoLib.ArduinoLoopFlag == true)
			{
				if(dirs == "forward")
					app.arduinoLib.ArduinoLoopFs.writeUTFBytes("dcMotor" + strcp[0] + ".motorrun(1,"  +strcp[1] + ");" + '\n');
				else
					app.arduinoLib.ArduinoLoopFs.writeUTFBytes("dcMotor" + strcp[0] + ".motorrun(0,"  +strcp[1] + ");" + '\n');
			}
			else
			{
				if(dirs == "forward")
					app.arduinoLib.ArduinoDoFs.writeUTFBytes("dcMotor" + strcp[0] + ".motorrun(1," +  strcp[1] + ");" + '\n');
				else
					app.arduinoLib.ArduinoDoFs.writeUTFBytes("dcMotor" + strcp[0] + ".motorrun(0," +  strcp[1] + ");" + '\n');
			}
		}
		else
		{
			pins = app.interp.arg(b,0);//引脚号，模块参数第一个，参数类型为数字_wh
			if(pins == "M1")
			{
				pin = 5;
			}
			else
			{
				pin = 6;
			}
			
			dirs = app.interp.arg(b,1);//角度值，模块参数第一个，参数类型为数字_wh
			pwm  = app.interp.numarg(b,2);//角度值，模块参数第一个，参数类型为数字_wh
			if(pwm > 256) 	//设置PWM 最大值为256;
			{
				pwm = 256;
			}
			//内嵌模块，没有有效返回_wh
			if(app.interp.activeThread.ArduinoNA)//加有效性判断_wh
			{
				app.interp.activeThread.ArduinoNA = false;
				return;
			}
			
			var dir:uint = 1;
			if(dirs == "back")
			{
				dir = 0;
			}
			
			var numf:Array = new Array();
			numf[0] = app.arduinoUart.ID_SetDM;
			numf[1] = pin;
			numf[2] = dir;
			numf[3] = pwm;	
			app.arduinoUart.sendDataToUartBuffer(numf);
		}
	}
	
	
	/*
	模块的作用分为两种：
	1) 生成固件，直接下载到arduino板子当中
	2) 通过串口下发控制数据
	以上两种作用的区分参数为ArduinoFlag。
	ArduinoFlag = true ：判断为Arduino语句生成过程
	ArduinoFlag = false：判断为串口下发数据
	
	primSetNUM():设置7段LED显示的数字
	*/
	private function primSetNUM(b:Block):void{
		if(app.arduinoLib.ArduinoFlag == true)				//判断是否为Arduino语句生成过程_wh
		{
			app.arduinoLib.ArduinoSeg = true;
			app.arduinoLib.ArduinoMathNum = 0;
			var pin:Number = app.interp.numarg(b,0);		//引脚号，模块参数第一个，参数类型为数字_wh
			if(app.arduinoLib.ArduinoBlock[app.arduinoUart.ID_SetNUM][pin] == 0)
			{
				app.arduinoLib.ArduinoHeadFs.writeUTFBytes("YoungMaker7SegmentDisplay seg" + pin + "(" + pin + ");" + '\n');
				app.arduinoLib.ArduinoHeadFs.writeUTFBytes("unsigned long _distime;" + '\n');
				app.arduinoLib.ArduinoHeadFs.writeUTFBytes("float  _disvalue;" + '\n');
				app.arduinoLib.ArduinoBlock[app.arduinoUart.ID_SetNUM][pin] = 1;
			}
			
			if(app.arduinoLib.ArduinoPin[pin] == 0)
			{
				app.arduinoLib.ArduinoPinFs.writeUTFBytes("pinMode(" + pin + ",OUTPUT);" + '\n');
				app.arduinoLib.ArduinoPin[pin] = 2;
			}
			if(app.arduinoLib.ArduinoPin[pin+1] == 0)
			{
				app.arduinoLib.ArduinoPinFs.writeUTFBytes("pinMode(" + (pin+1) + ",OUTPUT);" + '\n');
				app.arduinoLib.ArduinoPin[pin+1] = 2;
			}
			if(app.arduinoLib.ArduinoPin[pin+2] == 0)
			{
				app.arduinoLib.ArduinoPinFs.writeUTFBytes("pinMode(" + (pin+2) + ",OUTPUT);" + '\n');
				app.arduinoLib.ArduinoPin[pin+2] = 2;
			}
			
			var strcp:Array = new Array;
			strcp[0] = pin.toString();
			
			var num:Number = interp.numarg(b,1);
			if(app.arduinoLib.ArduinoValueFlag == true)
			{
				strcp[1] = app.arduinoLib.ArduinoValueStr;
				app.arduinoLib.ArduinoValueFlag = false;
			}
			else
			{
				if(app.arduinoLib.ArduinoMathFlag == true)
				{
					strcp[1] = app.arduinoLib.ArduinoMathStr[0];
					app.arduinoLib.ArduinoMathFlag = false;
				}
				else
				{
					if(app.arduinoLib.ArduinoReadFlag == true)
					{
						strcp[1] = app.arduinoLib.ArduinoReadStr[0];
						app.arduinoLib.ArduinoReadFlag = false;
					}
					else
					{
						strcp[1] = num.toString();
					}
				}
			}
			if(app.arduinoLib.ArduinoLoopFlag == true)
			{
				app.arduinoLib.ArduinoLoopFs.writeUTFBytes("seg" + strcp[0] + ".display(" + strcp[1] + ");" + '\n');
			}
			else
			{
				app.arduinoLib.ArduinoDoFs.writeUTFBytes("seg" + strcp[0] + ".display(" + strcp[1] + ");" + '\n');
			}
		}
		else
		{
			pin = app.interp.numarg(b,0);
			num = app.interp.numarg(b,1);
			//内嵌模块，没有有效返回_wh
			if(app.interp.activeThread.ArduinoNA)//加有效性判断_wh
			{
				app.interp.activeThread.ArduinoNA = false;
				return;
			}
			
			var numf:Array = new Array();
			var numfs:ByteArray = new ByteArray();
			numfs.writeFloat(num);
			numfs.position = 0;
			numf[0] = app.arduinoUart.ID_SetNUM;
			numf[0] = pin;
			numf[1] = numfs.readByte();
			numf[2] = numfs.readByte();
			numf[3] = numfs.readByte();
			numf[4] = numfs.readByte();
					
			//通信协议：0xff 0x55; 0x85（数码管类型）; pin（管脚号）; 数值_wh 
			app.arduinoUart.sendDataToUartBuffer(numf);
		}
	}
	
	/*
	模块的作用分为两种：
	1) 生成固件，直接下载到arduino板子当中
	2) 通过串口下发控制数据
	以上两种作用的区分参数为ArduinoFlag。
	ArduinoFlag = true ：判断为Arduino语句生成过程
	ArduinoFlag = false：判断为串口下发数据
	
	primSetRGB():设置RGB LED的颜色
	*/
	
	private function primSetRGB(b:Block):void{
		if(app.arduinoLib.ArduinoFlag == true)	//判断是否为Arduino语句生成过程_wh
		{
			app.arduinoLib.ArduinoRGB = true;	//三色灯，包含头文件时需要参数
			if(app.arduinoLib.ArduinoBlock[app.arduinoUart.ID_SetRGB] == 0)
			{
				app.arduinoLib.ArduinoHeadFs.writeUTFBytes("YoungMakerRGBLed RGBled;" + '\n');
				app.arduinoLib.ArduinoBlock[app.arduinoUart.ID_SetRGB] = 1;
			}
			
			if(app.arduinoLib.ArduinoPin[9] == 0)
			{
				app.arduinoLib.ArduinoPinFs.writeUTFBytes("pinMode(9,OUTPUT);" + '\n');
				app.arduinoLib.ArduinoPin[9] = 2;
			}
			if(app.arduinoLib.ArduinoPin[10] == 0)
			{
				app.arduinoLib.ArduinoPinFs.writeUTFBytes("pinMode(10,OUTPUT);" + '\n');
				app.arduinoLib.ArduinoPin[10] = 2;
			}
			if(app.arduinoLib.ArduinoPin[11] == 0)
			{
				app.arduinoLib.ArduinoPinFs.writeUTFBytes("pinMode(11,OUTPUT);" + '\n');
				app.arduinoLib.ArduinoPin[11] = 2;
			}
			
			var strcp:Array = new Array;
			app.arduinoLib.ArduinoMathNum = 0;
			var red:Number = app.interp.numarg(b,0);
			if(app.arduinoLib.ArduinoValueFlag == true)
			{
				strcp[0] = ArduinoValueStr;
				app.arduinoLib.ArduinoValueFlag = false;
			}
			else
			{
				if(app.arduinoLib.ArduinoMathFlag == true)
				{
					strcp[0] = app.arduinoLib.ArduinoMathStr[0];
					app.arduinoLib.ArduinoMathFlag = false;
				}
				else
				{
					if(app.arduinoLib.ArduinoReadFlag == true)
					{
						strcp[0] = ArduinoReadStr[0];
						app.arduinoLib.ArduinoReadFlag = false;
					}
					else
					{
						strcp[0] = red.toString();
					}
				}
			}
			app.arduinoLib.ArduinoMathNum = 0;
			var green:Number = app.interp.numarg(b,1);//red_wh
			if(app.arduinoLib.ArduinoValueFlag == true)
			{
				strcp[1] = ArduinoValueStr;
				ArduinoValueFlag = false;
			}
			else
			{
				if(app.arduinoLib.ArduinoMathFlag == true)
				{
					strcp[1] = ArduinoMathStr[0];
					ArduinoMathFlag = false;
				}
				else
				{
					if(app.arduinoLib.ArduinoReadFlag == true)
					{
						strcp[1] = ArduinoReadStr[0];
						ArduinoReadFlag = false;
					}
					else
						strcp[1] = green.toString();
				}
			}
			ArduinoMathNum = 0;
			var blue:Number = app.interp.numarg(b,2);//red_wh
			if(ArduinoValueFlag == true)
			{
				strcp[2] = ArduinoValueStr;
				ArduinoValueFlag = false;
			}
			else
			{
				if(ArduinoMathFlag == true)
				{
					strcp[2] = ArduinoMathStr[0];
					ArduinoMathFlag = false;
				}
				else
				{
					if(ArduinoReadFlag == true)
					{
						strcp[2] = ArduinoReadStr[0];
						ArduinoReadFlag = false;
					}
					else
					{
						strcp[2] = blue.toString();
					}
				}
			}
			if(app.arduinoLib.ArduinoLoopFlag == true)
			{
				app.arduinoLib.ArduinoLoopFs.writeUTFBytes("RGBled.setColorAt(" + strcp[0] + "," + strcp[1] + "," + strcp[2] + ");" + '\n');
			}
			else
			{
				app.arduinoLib.ArduinoDoFs.writeUTFBytes("RGBled.setColorAt(" + strcp[0] + "," + strcp[1] + "," + strcp[2] + ");" + '\n');
			}
		}
		else
		{
			red   = interp.numarg(b,0);//red_wh
			green = interp.numarg(b,1);//red_wh
			blue  = interp.numarg(b,2);//red_wh
			//内嵌模块，没有有效返回
			if(app.interp.activeThread.ArduinoNA)//加有效性判断_wh
			{
				app.interp.activeThread.ArduinoNA = false;
				return;
			}
			
			var numf:Array = new Array();
			var numfred:ByteArray = new ByteArray();
			numfred.writeShort(red);
			numfred.position = 0;
			numf[0] = app.arduinoUart.ID_SetRGB;
			numf[1] = 0x09;
			numf[2] = numfred.readByte();
			numf[3] = numfred.readByte();
			
			var numfgreen:ByteArray = new ByteArray();
			numfgreen.writeShort(green);
			numfgreen.position = 0;
			numf[4] = 0x0a;
			numf[5] = numfgreen.readByte();
			numf[6] = numfgreen.readByte();
			
			
			var numfblue:ByteArray = new ByteArray();
			numfblue.writeShort(blue);
			numfblue.position = 0;
			numf[7] = 0x0b;
			numf[8] = numfblue.readByte();
			numf[9] = numfblue.readByte();
			
			if(app.interp.activeThread.ArduinoNA)//加有效性判断_wh
			{
				app.interp.activeThread.ArduinoNA = false;
				return;
			}
			
			//通信协议：0xfe 0xfd len; 0x87（三色LED）; pin（0x09）; 三色pwm（PWM量）_wh 

			app.arduinoUart.sendDataToUartBuffer(numf);
		}
	}
	/*
	 * 设置无源蜂鸣器音调和时长
	 * */
	private function primSetMUS(b:Block):void{
		var pin:Number = interp.numarg(b,0);//引脚号，模块参数第一个，参数类型为数字_wh
		var tone:Number;//音调，模块参数第一个，参数类型为数字，需要16位 short 型表示
		var meter:Number;//节拍，需要16位 short型表示
		switch(interp.arg(b,1))
		{
			case "C2":tone = 65;break;
			case "D2":tone = 73;break;
			case "E2":tone = 82;break;
			case "F2":tone = 87;break;
			case "G2":tone = 98;break;
			case "A2":tone = 110;break;
			case "B2":tone = 123;break;
			case "C3":tone = 134;break;
			case "D3":tone = 147;break;
			case "E3":tone = 165;break;
			case "F3":tone = 175;break;
			case "G3":tone = 196;break;
			case "A3":tone = 220;break;
			case "B3":tone = 247;break;
			case "C4":tone = 262;break;
			case "D4":tone = 294;break;
			case "E4":tone = 330;break;
			case "F4":tone = 349;break;
			case "G4":tone = 392;break;
			case "A4":tone = 440;break;
			case "B4":tone = 494;break;
			case "C5":tone = 523;break;
			case "D5":tone = 587;break;
			case "E5":tone = 659;break;
			case "F5":tone = 698;break;
			case "G5":tone = 784;break;
			case "A5":tone = 880;break;
			case "B5":tone = 998;break;
			case "C6":tone = 1047;break;
			case "D6":tone = 1175;break;
			case "E6":tone = 1319;break;
			case "F6":tone = 1397;break;
			case "G6":tone = 1568;break;
			case "A6":tone = 1760;break;
			case "B6":tone = 1976;break;
			case "C7":tone = 2093;break;
			case "D7":tone = 2349;break;
			case "E7":tone = 2637;break;
			case "F7":tone = 2794;break;
			case "G7":tone = 3136;break;
			case "A7":tone = 3520;break;
			default:break;
		}
		switch(interp.arg(b,2))
		{
			case "1/2":meter = 500;break;
			case "1/4":meter = 250;break;
			case "1/8":meter = 125;break;
			case "whole":meter = 1000;break;
			case "double":meter = 2000;break;
			case "stop":meter = 0;break;
			default:break;
		}
		if(app.arduinoLib.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			app.arduinoLib.ArduinoBuz = true;
			app.arduinoLib.ArduinoMathNum = 0;
			
			if(app.arduinoLib.ArduinoBlock[app.arduinoUart.ID_SetMUS][pin] == 0)
			{
				app.arduinoLib.ArduinoHeadFs.writeUTFBytes("YoungMakerBuzzer buzzer" + pin + "(" + pin + ");" + '\n');
				app.arduinoLib.ArduinoBlock[app.arduinoUart.ID_SetMUS][pin] = 1;
			}
			
			if(app.arduinoLib.ArduinoPin[pin] == 0)
			{
				app.arduinoLib.ArduinoPinFs.writeUTFBytes("pinMode(" + pin + ",OUTPUT);" + '\n');
				app.arduinoLib.ArduinoPin[pin] = 2;
			}
			
			if(app.arduinoLib.ArduinoLoopFlag == true)
			{
				app.arduinoLib.ArduinoLoopFs.writeUTFBytes("buzzer" + pin + ".tone(" + pin + "," + tone + "," +meter + ");" + '\n');
				app.arduinoLib.ArduinoLoopFs.writeUTFBytes("delay(" + meter  + ");" + '\n');
			}
			else
			{
				app.arduinoLib.ArduinoDoFs.writeUTFBytes("buzzer" + pin + ".tone(" + pin + "," + tone + "," +meter + ");" + '\n');
				app.arduinoLib.ArduinoDoFs.writeUTFBytes("delay(" + meter  + ");" + '\n');
			}
		}
		else//正常上位机运行模式_wh
		{
			var numf:Array = new Array();
			var numfs:ByteArray = new ByteArray();
			numfs.writeShort(tone);
			numfs.position = 0;
			numf[0] = app.arduinoUart.ID_SetMUS;
			numf[1] = numfs.readByte();
			numf[2] = numfs.readByte();
			
			var numfms:ByteArray = new ByteArray();
			numfms.writeShort(meter);
			numfms.position = 0;
			numf[3] = numfms.readByte();
			numf[4] = numfms.readByte();
			app.arduinoUart.sendDataToUartBuffer(numf);
		}
	}
	
	
	private function primSetLCD1602String(b:Block):void
	{
		var lcd_string:String = app.interp.arg(b,0);
		if(app.arduinoLib.ArduinoFlag == true)	//判断是否为Arduino语句生成过程_wh
		{
			app.arduinoLib.ArduinoLCD1602 = true;	//LCD1602，包含头文件时需要参数
			if(app.arduinoLib.ArduinoBlock[app.arduinoUart.ID_SetLCD1602String] == 0)
			{
				app.arduinoLib.ArduinoHeadFs.writeUTFBytes("YoungMakerCrystal lcd(0x20, 16, 2);" + '\n');
				app.arduinoLib.ArduinoBlock[app.arduinoUart.ID_SetLCD1602String] = 1;
			}
			
			var strcp:Array = new Array;
			app.arduinoLib.ArduinoMathNum = 0;
			
			if(app.arduinoLib.ArduinoValueFlag == true)
			{
				strcp[0] = ArduinoValueStr;
				app.arduinoLib.ArduinoValueFlag = false;
			}
			else
			{
				if(app.arduinoLib.ArduinoMathFlag == true)
				{
					strcp[0] = app.arduinoLib.ArduinoMathStr[0];
					app.arduinoLib.ArduinoMathFlag = false;
				}
				else
				{
					if(app.arduinoLib.ArduinoReadFlag == true)
					{
						strcp[0] = ArduinoReadStr[0];
						app.arduinoLib.ArduinoReadFlag = false;
					}
					else
					{
//						strcp[0] = red.toString();
					}
				}
			}
							
			app.arduinoLib.ArduinoDoFs.writeUTFBytes("lcd.init();" + '\n');
			app.arduinoLib.ArduinoDoFs.writeUTFBytes("delay(10);" + '\n');
			
			if(app.arduinoLib.ArduinoLoopFlag == true)
			{
				app.arduinoLib.ArduinoLoopFs.writeUTFBytes("lcd.LiquidCrystaldisplay(" + '"' + lcd_string + '"' + ");"+ '\n');
			}
			else
			{
				app.arduinoLib.ArduinoDoFs.writeUTFBytes("lcd.LiquidCrystaldisplay(" + '"' + lcd_string + '"' + ");"+ '\n');
			}
		}
		else
		{	
			var numf:Array = new Array();
			var numfs:Array = new Array();
			
			if(app.interp.activeThread.ArduinoNA)//加有效性判断_wh
			{
				app.interp.activeThread.ArduinoNA = false;
				return;
			}
			
			numf = lcd_string.split("");				//将得到的字符串拆成Array格式
			numfs[0] = app.arduinoUart.ID_SetLCD1602String;	//组合字符，将功能ID加入进去
			numfs = numfs.concat(numf);
			
			for(var i:int = numfs.length; i<32; i++)		//对于LCD没有更改的部分增加空白字符占位，否则出现乱码
			{
				numfs[i] = 0x20;
			}
			
			//通信协议：0xfe 0xfd len; ID_SetLCD1602String ; 显示的字符;  

			app.arduinoUart.sendDataToUartBuffer(numfs);
		}
		
	}
	
	private function primSetgray(b:Block):void
	{
		
	}
	private function primSetforward(b:Block):void
	{
		
	}
	private function primSetback(b:Block):void
	{
		
	}
	private function primSetleft(b:Block):void
	{
		
	}
	private function primSetright(b:Block):void
	{
		
	}
	
	
	private function primReadShort(b:Block):void
	{
		
	}
	private function primReadTrack(b:Block):void
	{
		
	}	
	private function primReadAvoid(b:Block):void
	{
		
	}
	private function primReadPower(b:Block):void
	{
		if(app.arduinoLib.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			if(app.arduinoLib.ArduinoBlock[app.arduinoUart.ID_ReadPOWER] == 0)
			{
				app.arduinoLib.ArduinoHeadFs.writeUTFBytes("YoungMakerPort  volt;" + '\n');
				app.arduinoLib.ArduinoBlock[app.arduinoUart.ID_ReadPOWER] = 1;
			}
			
			app.arduinoLib.ArduinoReadStr[0] = "volt.minicarVolt()";
			app.arduinoLib.ArduinoReadFlag = true;
		}
		else
		{
			
//			app.arduino.writeByte(ID_ReadPOWER);
			
		}	
	}
	
	/*
	*/
	private function primReadByte(b:Block):int
	{
		app.xuhy_test_log("primReadByte");
//		var byte:Number = app.comDataArray[7];
//		app.comDataArray.length = 0;		
//		app.comDataArrayOld.length = 0;		
		return 0;
	}
	
	
	private function primReadCap(b:Block):void
	{
		app.xuhy_test_log("读取电容器的电容值");
		var pin:Number = app.interp.numarg(b,0);//引脚号，模块参数第一个，参数类型为数字_wh	
		if(app.arduinoLib.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			app.arduinoLib.ArduinoCap = true;
			if(app.arduinoLib.ArduinoPin[pin] == 0)
			{
				app.arduinoLib.ArduinoPinFs.writeUTFBytes("pinMode(" + pin + ",INPUT);" + '\n');
				app.arduinoLib.ArduinoPin[pin] = 1;
			}
			
			var strcp:String = new String();
			strcp = pin.toString();
			app.arduinoLib.ArduinoReadStr[0] = "readCapacitivePin(" + strcp + ")";
			app.arduinoLib.ArduinoReadFlag = true;
		}
		else//正常上位机运行模式_wh
		{
			//通信协议：0xff 0x55; 0x08（IO输入电容值类型）; pin（管脚号）; 00 00 00 00_wh 	
			var numf:Array = new Array();
			numf[0] = app.arduinoUart.ID_ReadCap;
			numf[1] = pin;
			app.arduinoUart.sendDataToUartBuffer(numf);		
		}
	}
	
	
	

	
	private function primReadFraredR(b:Block):void
	{
		app.xuhy_test_log("读取红外遥控器的发送数据：");
		var pin:Number = app.interp.numarg(b,0);//引脚号，模块参数第一个，参数类型为数字_wh
		if(app.arduinoLib.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			app.arduinoLib.ArduinoIR = true;
			if(app.arduinoLib.ArduinoBlock[app.arduinoUart.ID_READFRAREDR] == 0)
			{
				app.arduinoLib.ArduinoHeadFs.writeUTFBytes("YoungMakerIR  ir" + pin + "(" + pin + ");" + '\n');
				app.arduinoLib.ArduinoBlock[app.arduinoUart.ID_READFRAREDR] = 1;
			}
			
			if(app.arduinoLib.ArduinoPin[pin] == 0)
			{
				app.arduinoLib.ArduinoPinFs.writeUTFBytes("pinMode(" + pin + ",INPUT);" + '\n');
				app.arduinoLib.ArduinoPin[pin] = 1;
			}
			
			app.arduinoLib.ArduinoReadStr[0] = "ir" + pin + ".getCode()";
			app.arduinoLib.ArduinoReadFlag = true;
		}
		else
		{

//			app.arduino.writeByte(ID_READFRAREDR);
//			app.arduino.writeByte(pin);

		}
	}
	
	private function primReadFloat(b:Block):void
	{
		
	}
	
	private function primReadAFloat(b:Block):void
	{
		
	}
	
	private function primReadPFloat(b:Block):void
	{
		
	}
}}
