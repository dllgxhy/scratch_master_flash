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
import flash.events.TimerEvent;


public class ArduinoUart extends Sprite {
	
	public var arduinoUart:ArduinoConnector = new ArduinoConnector();	//新建串口类
	public var arduinolib:ArduinoLibrary = new ArduinoLibrary();
	private var arduinoUartBaud:Number = 115200;
	private var scratchComID:int = 0x00;				//当前选中打开的COM口
	
	public var comWorkingFlag:Boolean = false;			//COM口是否开启
	public var scratchUartStayAlive:Boolean = false;			
	public var comRevDataAvailable:Boolean = false;//串口数据接收完整性判断标识
	
	private var uartCommunicationPackageHead:Array = [0xfe, 0xfd]; //通讯协议的包头和包尾
	private var uartCommunicationPackageTail:Array = [0xfe, 0xfb];	
	public var comDataBuffer:Array = new Array();//串口接收数据缓存
	public var comDataBufferOld:Array = new Array();//串口接收数据缓存未处理数据
	
	private var uartDataID_checkUartAvail:int = 0x01;  //串口通讯心跳包，数据包括各种板载传感器的数据
	private var uartDataID_Readshort:int = 0x00;
	
	private var uartDetectStatustimerStart:Number = 0x00;
	private var uartDetectStatustimerStop:Number = 0x00;
	
	public var uartOnTickTimer:Timer = new Timer(2000, 0);  //生成一个无限次循环的定时器，专门用于检测串口是否开启
	private var comHeartTimeStart:Number = 0x00;
	private var comHeartTimeStop:Number = 0x00;
	
	
	/*
	Scratch与Arduino
	*/


	public function ArduinoUart(baud:Number):void
	{
		this.arduinoUartBaud = baud;	
		uartOnTickTimer.addEventListener(TimerEvent.TIMER, onTick);
		uartOnTickTimer.start();
	}
	
	/*************************************************
	 串口连接
	 参数:可连接的有效串口
	 返回值:true:连接成功
			false:连接失败
	**************************************************/	
	

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
	public function checkUartAvail(scratchComID:int):Boolean
	{	
		if (scratchUartStayAlive == true)
		{
			return true;
		}
		else
		{
			arduinoUart.close();//重新关闭_wh
			arduinoUart.connect("COM" + scratchComID, 115200);
			arduinoUart.addEventListener("socketData", fncArduinoData);
			return false;
		}	
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
			//将接收到的ASCII码字符型转成数值型_wh
			for (i = 0; i < comDataBufferOld.length; i++)
			{
				comDataBuffer[i] = comDataBufferOld[i].charCodeAt(0);
			}
			if (comDataBuffer.length < 8)		//通讯协议最短要有8Byte，少于这个则为错误数据
				break;					
			//接收通信协议：0xfe 0xfd 0xXX(数据长度) 0xXX(类型);0xXX(子类型) 0xXX(数据) 若干个; 0xfe 0xfb(值)
			if((comDataBuffer[0] == 0xfe) && (comDataBuffer[1] == 0xfd) && (comDataBuffer[comDataBuffer.length-2] == 0xfe) && (comDataBuffer[comDataBuffer.length-1] == 0xfb))//comDataArray中为ASCII码字符型，判断不等
			{
				//根据类别进行初步数据有效性判断_wh
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
							break;//数据接收完整判断_wh
							
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
	**************************************************/
	public function paraUartData_OnTick(data:Array):void
	{		
		ArduinoLibrary.arduinoLightValue = data[0] * 256 + data[1];
	}
	
	/*
	 
	*/
	protected function onTick(event:TimerEvent):void
	{
		if (uartDetectStatustimerStop != uartDetectStatustimerStart)
		{
//			trace ("uart stay alive");
			scratchComID = 0x00;
		}
		else
		{	
//			trace ("uart is failed");
			scratchUartStayAlive = false;
			if (checkUartAvail(scratchComID))
			{
				scratchComID = scratchComID - 1;
			}
			else 
			{
				scratchComID ++;
			}
			
			if (scratchComID > 16)
			{
				scratchComID = 0x00;
			}
		}	
		uartDetectStatustimerStop = uartDetectStatustimerStart = getTimer();
	}
}}
