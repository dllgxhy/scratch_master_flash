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

// ArduinoUart.as
// John Maloney, September 2009
//
// 该部分的作用是对串口进行处理,只处理串口数据的接收和发送功能

/*******************************************
串口设置初始化函数应用举例
public var arduino:ArduinoConnector;

public function initApp():void
{
        arduino = new ArduinoConnector();
        arduino.connect("COM10",9600);
}

protected function closeApp(event:Event):void
{
        arduino.dispose();                              
}



串口写入数据的api函数
public function writeByte(byte:uint):Boolean
public function writeString(stringToSend:String):Boolean
public function writeBytes(bytesToSend:ByteArray?):Boolean

串口读取数据的api函数
public function readBytesAsArray():Array
public function readBytesAsString():String
public function readBytesAsByteArray():ByteArray
public function readByte():uint
*******************************************/

package arduino{

import com.quetwo.Arduino.ArduinoConnector;
import com.quetwo.Arduino.ArduinoConnectorEvent;

import flash.display.Sprite;
import flash.utils.getTimer;
import flash.utils.Timer;
import flash.utils.*;
import flash.events.TimerEvent;
import flash.display.Shape;

import flash.filesystem.FileStream;
import flash.filesystem.FileMode;
import flash.filesystem.File;

public class ArduinoUart extends Sprite {
	
	public var arduinoUart:ArduinoConnector         = new ArduinoConnector();	    //新建串口类
	public var app:Scratch ;

	public  var scratchComID:int                    = 0x01;					//当前选中打开的COM口,COM口从1开始计数
	public  var scratchUartStayAlive:Boolean        = false;				//串口是否还可以正常通讯
	
	public  var comStatusTrueFlag:Boolean           = false;
	private var uartCloseFlag:Boolean 			    = false;
	
	
	public var busy:int 					       = 0x01;
	public var free:int 					       = 0x00;
	public  var uartBusyStatus:int                 = free;           //是否有通讯占用串口,取值为busy 或 free
	/*串口通讯协议*/
	public var comDataBuffer:Array                 = new Array();       //串口接收数据缓存
	public var comDataBufferOld:Array              = new Array();       //串口接收数据缓存未处理数据
	public var comDataBufferSend:Array             = new Array();       //要发送的数据，但由于串口被占用而没有发送出去的数据
	public var comDataBufferSend_flag:Boolean      = false;             //comDataBufferSend中是否有数据
	
	public const uartDataID_checkUartAvail:int     = 0x01;  			//串口通讯心跳包，数据包括各种板载传感器的数据
	public const uartDataID_Readshort:int          = 0x00;
	
	public const ID_SetDigital:int       = 0x81;//写数字口输出_wh
	public const ID_SetPWM:int           = 0x82;//写pwm口输出_wh
	public const ID_SetSG:int            = 0x83;//写舵机输出角度_wh
	public const ID_SetMUS:int           = 0x84;//写无源蜂鸣器音乐输出_wh
	public const ID_SetNUM:int           = 0x85;//写数码管输出值_wh
	public const ID_SetDM:int            = 0x86;//写舵机输出角度_wh
	public const ID_SetRGB:int           = 0x87;//三色LED_wh
	public const ID_SetLCD1602String:int = 0x88 //LCD1602写字符串
	
	public const ID_SetFORWARD:int       = 0xA0;//机器人前进_wh
	public const ID_SetBACK:int          = 0xA1;//机器人后退_wh
	public const ID_SetLEFT:int          = 0xA2;//机器人左转弯_wh
	public const ID_SetRIGHT:int         = 0xA3;//机器人右转弯_wh
	public const ID_SetGRAY:int          = 0xA5;//机器人灰度阀值_wh
	
	public const ID_ReadDigital:int      = 0x01;//读数字口输入_wh
	public const ID_ReadAnalog:int       = 0x02;//读模拟口输入_wh
	public const ID_ReadAFloat:int       = 0x03;//读模拟口输入float值_wh
	public const ID_ReadPFloat:int       = 0x04;//超声波传感器输入float值_wh
	public const ID_ReadCap:int          = 0x08;//读取电容byte值_wh
	
	public const ID_ReadTRACK:int        = 0x52;//读机器人循迹输入_wh
	public const ID_ReadAVOID:int        = 0x50;//读机器人避障输入_wh
	public const ID_ReadULTR:int         = 0x51;//读机器人超声波输入_wh
	public const ID_ReadPOWER:int        = 0x53;//读机器人电量输入_wh
	public const ID_READFRAREDR:int      = 0x54;//读机器人红外遥控输入_wh
	
	public const ID_CarDC:int = 0x0100;//机器人前进方式_wh
	public const ID_DIR:int = 0x0101;//方向电机变量_wh	

	
	 
	public function ArduinoUart(app:Scratch)
	{	
		this.app = app;	
//		checkUartAvail(13);  //测试使用,正常使用时应删除	
	}
	
	/************************************************
	串口开启
	************************************************/
	public function arduinoUartOpen(comID:int):Boolean{	
	
		if(arduinoUart.connect("COM" + comID, 115200))
		{
			app.xuhy_test_log("open COM:"+comID+ " success");
			return true;
		}
		app.xuhy_test_log("open COM:"+comID+ " failed");
		return false;
	}
	
	/************************************************
	串口关闭
	************************************************/
	public function arduinoUartClose():void{	
		arduinoUart.flush();
		arduinoUart.close();
	}
	
	
	/**************************************************
	将串口接收到的数据按照协议进行解包
	数据种类与Arduino板一致
	**************************************************/
	public function paraUartData_OnTick(data:Array):void
	{		
		app.arduinoLib.arduinoLightValue = data[0] * 256 + data[1];
		app.arduinoLib.arduinoUltrasonicValue =  data[5];
	}
		
	
	/*如果scratchComID 的串口连接不上，则通过插拔USB接口检测哪个COM口可用，得到scratchComID。*/	
	public function checkArduinoCableIsPlugIn():void{								
		app.uartDialog.setText("please Check the cable plugout");
		app.uartDialog.showOnStage(app.stage);	
	}
		
	
	

	/*********************************************************************
	串口数据发送事件处理
	*********************************************************************/
	
	/*将需要下载的数据放置在发送comDataBufferSend中，
	 * 如果该buffer中有数据则在ScratchRuntime.as的stepRuntime中下发出去
	 * 
	 * @para dataArray：需要下发的数据
	 */
	public function sendDataToUartBuffer(dataArray:Array):void {
		var tempUartData:Array = new Array();	
		tempUartData[0] = 0xfe;     					//包头
		tempUartData[1] = 0xfd;
		tempUartData[2] = dataArray.length + 4 + 1;     //数据长度，从包头开始计算，直到包尾(4),再加上本身的数据长度(1)  
		tempUartData[3] = dataArray[0];					//数据类型
		dataArray.shift();
		for (var i:int in dataArray)
		{
			tempUartData.push(dataArray[i]);
		}
		tempUartData.push(0xfe, 0xfb);
		comDataBufferSend = comDataBufferSend.concat(tempUartData);		//将数据整理到UART下发数据的buffer中
		app.xuhy_test_log("sendDataToUartBuffer:"+comDataBufferSend);
	}
	/*
	 *将buffer中的数据下发 
	 * 
	 */
	public function uartSendDataFromScratchToArduino():void
	{
		var uartDataCount:int = 0x00;
		if (uartBusyStatus == free)//串口处于可使用的状态
		{
			uartBusyStatus = busy;
			for (uartDataCount = 0x00; uartDataCount < comDataBufferSend.length;uartDataCount++) {	//如果buffer中存在数据 
				arduinoUart.writeByte(comDataBufferSend[0]);    									//将第一个数据下发出去
				arduinoUart.flush();																//发送完毕后清空数据
				app.xuhy_test_log("uartSendDataFromScratchToArduino data=" + comDataBufferSend[0]);
				comDataBufferSend.shift();
			}
			uartBusyStatus = free;
		}
		else {
		}
	}
	
	/***************************************************
	Scratch 向 Arduino发送串口数据心跳包
	***************************************************/
	public function uartHeartDatascratch2Arduino():void
	{
		var tempUartData:Array = new Array();
		tempUartData[0] = 0xfe;
		tempUartData[1] = 0xfd;
		tempUartData[2] = 0x01;
		tempUartData[3] = 0x02;
		tempUartData[4] = 0xfe;
		tempUartData[5] = 0xfb;
		
		for (var i:int = 0x00; i < tempUartData.length; i++)
		{
			arduinoUart.writeByte(tempUartData[i]);
		}		
	}
	
	
	
	/*********************************************************************
	串口数据接收事件处理
	*********************************************************************/
	public function fncArduinoData(aEvt: ArduinoConnectorEvent):void
	{
		var paraDataBuffer:Array = new Array();
		uartBusyStatus = busy; 
		try
		{
			comDataBufferOld = comDataBufferOld.concat(arduinoUart.readBytesAsArray());//将接收到的数据放在comDataArrayOld数组中_wh
			app.arduinoUartConnect.uartDetectStatustimerStop = getTimer();
			uartBusyStatus = free;
		}
		catch(Error)
		{
			return;
		}
		
		while(1)
		{
			comDataBuffer.length =0;
			for (i = 0; i < comDataBufferOld.length; i++)
			{
				comDataBuffer[i] = comDataBufferOld[i].charCodeAt(0);
			}
			if (comDataBuffer.length < 8)	
				break;					
			//接收通信协议：0xfe 0xfd 0xXX(数据长度) 0xXX(类型); 0xXX(数据) 若干个; 0xfe 0xfb(值)
			if((comDataBuffer[0] == 0xfe) && (comDataBuffer[1] == 0xfd) && (comDataBuffer[comDataBuffer.length-2] == 0xfe) && (comDataBuffer[comDataBuffer.length-1] == 0xfb))//comDataArray中为ASCII码字符型，判断不等
			{
				if (comDataBuffer[2] == comDataBuffer.length)
				{
					switch(comDataBuffer[3])
					{
						case uartDataID_checkUartAvail:
							for(var i:int = 0; i < comDataBufferOld.length-5; i++)
							{
								paraDataBuffer[i] = comDataBuffer[i+4];
							}
							paraUartData_OnTick(paraDataBuffer);
							break;	
						default:
							break;
					}
					break;
				}				
				//数据左移一位_wh
				if(comDataBuffer.length >= 2)
					comDataBufferOld.shift();//数组整体前移一位_wh
					//数据未接收全_wh
				else
					break;
			}
			else
			{
				comDataBufferOld.shift();//数组整体前移一位_wh
			}
		}
	}
}}









































