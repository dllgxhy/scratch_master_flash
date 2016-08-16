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
public function readBytesAsByteArray():ByteArray?
public function readByte():uint
*******************************************/

package arduino{

import com.quetwo.Arduino.ArduinoConnector;
import com.quetwo.Arduino.ArduinoConnectorEvent;

import flash.display.Sprite;

public class ArduinoUart extends Sprite{
	
	private var arduinoUartBaud:Number = 115200;
	private var arduinoComID:String = '0';
	
	public var arduinoUart:ArduinoConnector = new ArduinoConnector();	//新建串口类
	
	public var comWorkingFlag:Boolean = false;		//COM口是否开启
	public var comWorkingID:String = '0';				//当前选中打开的COM口
	public var comDataBuffer:Array = new Array();//串口接收数据缓存
	public var comDataBufferOld:Array = new Array();//串口接收数据缓存未处理数据
	public var comRevDataAvailable:Boolean = false;//串口数据接收完整性判断标识
	
	public var readUartDataType:String = '0';   //读取到的数据类型
	public var readUartOperaCode:Array;         //读取到的数据内容
	private var uartCommunicationPackageHead:Array = [0xfe, 0xfd];
	private var uartCommunicationPackageTail:Array = [0xfe, 0xfb];

	private var checkUartAvailID:int = 0x01;
	
	private var communicationBetweenScratchArduinoStatus:Boolean = false;
	
	

	public function ArduinoUart(baud:Number):void
	{
		this.arduinoUartBaud = baud;	
	}
//通讯协议定义
	
/*************************************************
 串口连接
 参数:可连接的有效串口
 返回值:true:连接成功
		false:连接失败
**************************************************/	
	public function uartConnect(comID:String):Boolean 
	{
		return arduinoUart.connect(comID,arduinoUartBaud);
	}
	
/*串口断开*/
	public function uartDisconnet():void
	{	
		arduinoUart.dispose();
		comWorkingFlag = false;
	}
	

/***************************************************
scratch 通过UART 向Arduino写入数据
***************************************************/
	public function scratchWriteData2Arduino(scratchWrite2ArduinoBuffer:Array):void
	{
		for (var i:int = 0x00; i < scratchWrite2ArduinoBuffer.length; i++)
		{
			arduinoUart.writeByte(scratchWrite2ArduinoBuffer[i]);
		}		
	}

/*	
串口检测，输出扫描到的所有有效串口号
有效串口号可能有几个，比如在电脑上插入了串口调试助手等，所以还需要检测是否通讯成功。
*/
	public function checkUartAvail():Boolean
	{
		var comAvailArray:Array = new Array();
		var tempUartData:Array = new Array;
		
		tempUartData[0] = uartCommunicationPackageHead[0];
		tempUartData[1] = uartCommunicationPackageHead[1];
		tempUartData[2] = checkUartAvailID;
		tempUartData[3] = 0x01;
		tempUartData[4] = 0x02;
		tempUartData[5] = uartCommunicationPackageTail[0];
		tempUartData[6] = uartCommunicationPackageTail[1];
		
		for(var i:int = 1;i<=16;i++)
		{		
			arduinoUart.close();//重新关闭_wh
			if(uartConnect("COM"+i))//判断是否能打开成功_wh
			{
				scratchWriteData2Arduino(tempUartData);
				if (0)   //此处需要更改xuhy_20160816
				{		
					comWorkingFlag = true;
					return true;
				}
			}	
		}
		arduinoUart.close();//重新关闭_wh
		return false;
	}	

/*********************************************************************
串口数据接收事件处理
ArduinoConnector.ane读取串口数据的api接口
public function readBytesAsArray():Array
public function readBytesAsString():String
public function readBytesAsByteArray():ByteArray?
public function readByte():uint
*********************************************************************/
public function fncArduinoData(aEvt: ArduinoConnectorEvent):void
{
	try
	{
		comDataBufferOld = comDataBufferOld.concat(arduinoUart.readBytesAsArray());//将接收到的数据放在comDataArrayOld数组中_wh
	}
	catch(Error)
	{
		return;
	}
	
	while(1)
	{
		comDataBuffer.length =0;
		//将接收到的ASCII码字符型转成数值型_wh
		for(var i:int = 0; i < comDataBufferOld.length; i++)
			comDataBuffer[i] = comDataBufferOld[i].charCodeAt(0);
		//接收通信协议：0xfe 0xfd 0xXX(数据长度) 0xXX(类型); 0xXX(数据) 若干个; 0xfe 0xfd(值)
		if((comDataBuffer[0] == 0xfe) || (comDataBuffer[1] == 0xfd) ||(comDataBufferOld.length == 0))//comDataArray中为ASCII码字符型，判断不等
		{
			if(comDataBuffer[1] == 0x66)
			{
				//根据类别进行初步数据有效性判断_wh
				switch(comDataBuffer[2])
				{
//					case CFunPrims.ID_ReadDigital:if(comDataBuffer.length >= 8) comRevFlag = true;break;//数据接收完整判断_wh
//					case CFunPrims.ID_ReadAnalog:if(comDataBuffer.length >= 8) comRevFlag = true;break;//数据接收完整判断_wh
					default:break;
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
	private function paraUartData():void
	{
		
	}
	
}}
