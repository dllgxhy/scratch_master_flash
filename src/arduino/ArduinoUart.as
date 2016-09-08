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
// 该部分的作用是对串口进行处理

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

public class ArduinoUart extends Sprite {
	
	public var arduinoUart:ArduinoConnector = new ArduinoConnector();	//新建串口类
	public var app:Scratch ;

	public var scratchComID:int = 0x01;								//当前选中打开的COM口,COM口从1开始计数
	public  var scratchUartStayAlive:Boolean = false;					//串口是否还可以正常通讯
	public var comStatusTrueArray:Array = new Array();
	public var comStatusTrueFlag:Boolean = false;
	private var uartCloseFlag:Boolean = false;
	
	/*串口通讯协议*/
	public var comDataBuffer:Array = new Array();//串口接收数据缓存
	public var comDataBufferOld:Array = new Array();//串口接收数据缓存未处理数据
	private var uartCommunicationPackageHead:Array = [0xfe, 0xfd]; 		//通讯协议的包头
	private var uartCommunicationPackageTail:Array = [0xfe, 0xfb];		//通讯协议的包尾
	
	public const uartDataID_checkUartAvail:int = 0x01;  					//串口通讯心跳包，数据包括各种板载传感器的数据
	public const uartDataID_Readshort:int      = 0x00;
	
	
	public const ID_SetDigital:int = 0x81;//写数字口输出_wh
	public const ID_SetPWM:int = 0x82;//写pwm口输出_wh
	public const ID_SetSG:int = 0x83;//写舵机输出角度_wh
	public const ID_SetMUS:int = 0x84;//写无源蜂鸣器音乐输出_wh
	public const ID_SetNUM:int = 0x85;//写数码管输出值_wh
	public const ID_SetDM:int = 0x86;//写舵机输出角度_wh
	public const ID_SetRGB:int = 0x87;//三色LED_wh
	public const ID_SetLCD1602String:int = 0x88 //LCD1602写字符串
	
	public const ID_SetFORWARD:int = 0xA0;//机器人前进_wh
	public const ID_SetBACK:int = 0xA1;//机器人后退_wh
	public const ID_SetLEFT:int = 0xA2;//机器人左转弯_wh
	public const ID_SetRIGHT:int = 0xA3;//机器人右转弯_wh
	//public static const ID_SetBUZZER:int = 0xA4;//机器人蜂鸣器_wh
	public const ID_SetGRAY:int = 0xA5;//机器人灰度阀值_wh
	//public static const ID_SetARM:int = 0xA5;//机器人机械臂_wh
	
	public const ID_ReadDigital:int = 0x01;//读数字口输入_wh
	public const ID_ReadAnalog:int = 0x02;//读模拟口输入_wh
	public const ID_ReadAFloat:int = 0x03;//读模拟口输入float值_wh
	public const ID_ReadPFloat:int = 0x04;//超声波传感器输入float值_wh
	public const ID_ReadCap:int = 0x08;//读取电容byte值_wh
	
	public const ID_ReadTRACK:int = 0x52;//读机器人循迹输入_wh
	public const ID_ReadAVOID:int = 0x50;//读机器人避障输入_wh
	public const ID_ReadULTR:int = 0x51;//读机器人超声波输入_wh
	public const ID_ReadPOWER:int = 0x53;//读机器人电量输入_wh
	public const ID_READFRAREDR:int = 0x54;//读机器人红外遥控输入_wh
	
	public const ID_CarDC:int = 0x0100;//机器人前进方式_wh
	public const ID_DIR:int = 0x0101;//方向电机变量_wh
	
	/*串口在线计时器
	 * 在串口监测定时器结束前，设置这两个参数，如果串口接收到数据，则重新置 uartDetectStatustimerStop 的值，
	 * 如果uartDetectStatustimerStart 和 uartDetectStatustimerStop 两个值不等，说明串口接收到过数据，证明串口在线
	 * uartOnTickTimer: 串口在线定时器
	 */
	private var uartDetectStatustimerStart:Number = 0x00;
	private var uartDetectStatustimerStop:Number = 0x00;
	public var uartOnTickTimer:Timer = new Timer(1500, 0);  //生成一个无限次循环的定时器，专门用于检测串口是否开启

	
	private var IntervalID:uint = 0x00; //查询UART是否工作正常定时器的ID号，可以用于清除定时器。
	
	
	 
	public function ArduinoUart(app:Scratch)
	{	
		this.app = app;	
	}
	
	
	/***************************************************
	scratch 通过UART 向Arduino写入数据
	该数据为固定值，Arduino收到该值，则认为UART是通的
	***************************************************/
	public function uartHeartDatascratch2Arduino():void
	{
		var tempUartData:Array = new Array();
		tempUartData[0] = uartCommunicationPackageHead[0];
		tempUartData[1] = uartCommunicationPackageHead[1];
		tempUartData[2] = 0x01;
		tempUartData[3] = 0x02;
		tempUartData[4] = uartCommunicationPackageTail[0];
		tempUartData[5] = uartCommunicationPackageTail[1];
		
		for (var i:int = 0x00; i < tempUartData.length; i++)
		{
			arduinoUart.writeByte(tempUartData[i]);
		}		
	}

	/*	
	串口检测，输出扫描到的所有有效串口号
	有效串口号可能有几个，比如在电脑上插入了串口调试助手等，所以还需要检测是否通讯成功。
	*/	
	public function checkUartAvail(scratchComID:int):void
	{	
		arduinoUart.connect("COM" + scratchComID, 115200);
		arduinoUart.addEventListener("socketData", fncArduinoData);	
		arduinoUart.flush();
	}

	/*********************************************************************
	串口数据接收事件处理

	*********************************************************************/
	public function fncArduinoData(aEvt: ArduinoConnectorEvent):void
	{
		var paraDataBuffer:Array = new Array();
		try
		{
			comDataBufferOld = comDataBufferOld.concat(arduinoUart.readBytesAsArray());//将接收到的数据放在comDataArrayOld数组中_wh
			uartDetectStatustimerStop = getTimer();
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
	
	/**************************************************
	将串口接收到的数据按照协议进行解包
	数据种类与Arduino板一致
	**************************************************/
	public function paraUartData_OnTick(data:Array):void
	{		
		app.arduinoLib.arduinoLightValue = data[0] * 256 + data[1];
		app.arduinoLib.arduinoUltrasonicValue =  data[5];
	}
	
	/*
	 *检查可用的UART接口 
	*/
	public function findComStatusTrue():Array
	{
		for (var i:int = 0x01; i <= 32;i++)//暂时设定只有32个com口，为com1 到 com32
		{
			if (arduinoUart.connect("COM" + i, 115200))
			{
				comStatusTrueArray.push(i);
				arduinoUart.close();
			}
		}
		return comStatusTrueArray;
	}
	
	
	/*
	 * 
	 **/
	public function setAutoConnect():uint
	{
		var intervalDuration:Number = 1000;
		IntervalID = setInterval(onTick_searchAndCheckUart, intervalDuration);
		uartDetectStatustimerStop = uartDetectStatustimerStart = 0x00;
		return IntervalID;
	}
	
	private var needFindComStatusFlag:Boolean = false;  //是否需要检查有哪些COM 口可用的标识
	public var comStatus:int = 0x03;  //com口的工作状态 0x00:连接正常 0x01:意外断开 0x02断开com口
	
	public function onTick_searchAndCheckUart():void
	{	
//		app.xuhy_test_log("uart connect test time " + uartDetectStatustimerStart +" ? " + uartDetectStatustimerStop);
		if (uartDetectStatustimerStop != uartDetectStatustimerStart)
		{
			arduinoUart.flush();
			comStatus = 0x00;
			needFindComStatusFlag = false;	
		}
		else
		{
			if (needFindComStatusFlag == false)
			{
				comStatusTrueArray.splice();    		  //清除数组数据
				comStatusTrueArray = findComStatusTrue(); //先检测是否有可用的com口
				needFindComStatusFlag = true ;
				app.xuhy_test_log("com is ready");
			}else if(comStatusTrueArray.length != 0x00){
				scratchComID = comStatusTrueArray[comStatusTrueArray.length -1];
				checkUartAvail(scratchComID);
				comStatusTrueArray.pop();
				app.xuhy_test_log("test " + scratchComID + " is availed for arduino");
			}
			else
			{
				arduinoUart.close();	//uart意外断开
				arduinoUart.flush();
				comStatus = 0x01;
//				scratchComID = 0x01;
				clearInterval(IntervalID); //关闭时钟
				needFindComStatusFlag = false;
				app.xuhy_test_log("uart disconnect unexpected");
				app.uartDialog.showOnStage(app.stage); //此处后续可以添加dialog 提示链接USB接口	
			}
		}
		uartDetectStatustimerStop = uartDetectStatustimerStart = getTimer();
	}
	
	/*
	 * 断开UART连接
	 * */
	public function setUartDisconnect():void
	{		
		arduinoUart.close();
		arduinoUart.flush();
//		scratchComID = 0x01;
		comStatus = 0x02;   
		clearInterval(IntervalID);
		needFindComStatusFlag = false;
		app.xuhy_test_log("Uart Disconnect");
	}
	
	/*
	 * 重启UART
	 * 
	*/
	public function uartReStart()
	{
		setUartDisconnect();
		arduinoUart.flush();
		arduinoUart.connect("COM" + scratchComID);
	}
	
	/*
	 * 通过Scratch 向Arduino写入数据，数据的协议为
	 * 包头  数据长度  数据类型 数据 包尾
	 * */
	public function uartSendDataFromScratchToArduino(dataArray:Array):void
	{
		
	}
}}
