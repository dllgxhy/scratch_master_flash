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

// Arduino.as
// xuhy, September 2009
//
// 该部分的作用为处理串口读取到的数据后续处理

package arduino{

import flash.desktop.NativeProcess;
import flash.desktop.NativeProcessStartupInfo;
import flash.display.Sprite;
import flash.filesystem.File;
import flash.utils.Timer;
import flash.events.TimerEvent;
import flash.events.ProgressEvent;

import translation.Translator;
import scratch.ScratchStage;

import uiwidgets.DialogBox;

public class ArduinoLibrary extends Sprite{
	
	
	public var app:Scratch;
	
	public static var arduinoLightValue:int = 0x00;  //作为全局变量
	public static var arduinoSlideValue:int = 0x00;
	public static var arduinoSoundValue:int = 0x00;
	public static var arduinoUltrasonicValue:int = 0x00;
	
	//固件下载
	
	public var file0:File;
	public var process:NativeProcess = new NativeProcess();
	public var process2:NativeProcess = new NativeProcess();
	public var nativePSInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
	public var upLoadFirmTimerCount:int = 0x00;// 用于上传固件时的计时处理，有超时处理功能
	public var upLoadFirmTimer:Timer;//定时器
	public var ArduinoFirmFlag:Number = 0;
	public var ArduinoRPFlag:Boolean = false;//Arduino生成模块右键选择相关项是否按下
	public var ArduinoRPNum:Number = 0;//Arduino生成模块右键选择相关项编号
	public var UpDialog:DialogBox = new DialogBox();
	public var upDialogSuccessFlag:Boolean = false;
	private var heartpackage:String = "heartpackage.hex";
	//安装驱动
	public var DriveFlag:Number = 0;//驱动安装变量值_wh
	
	public function ArduinoLibrary(app:Scratch)
	{
		this.app = app;
		upLoadFirmTimer = new Timer(1000, 75);//每1s一个中断，持续75s 在线约10s，无线61s
		upLoadFirmTimer.addEventListener(TimerEvent.TIMER, onUpLoadFirmTimerTick); 
		upLoadFirmTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onupLoadFirmTimerComplete);
		UpDialog.addTitle('Upload');
		UpDialog.addButton('Close',cancel);
		UpDialog.addText(Translator.map("uploading") + " ... ");
	}
	
	/*Arduino固件烧入程序
	* AS3中调用Arduino的编译器程序
	* 
	*/
	public function dofirm():void {
		//烧入固件前先判断串口，未打开则之间退出，打开则先关闭（否则串口被占用）_wh
		app.xuhy_test_log("do firm");
		var firmTeststr:String = "firmware_test";
		
		if(app.arduinoUart.comStatus == 0x00) //有可用串口
		{
			app.arduinoUart.setUartDisconnect();  //关闭串口
		}	
		else
		{
			app.xuhy_test_log("find avail com");
			app.arduinoUart.findComStatusTrue();  //找到可以使用的IO口
			if (app.arduinoUart.comStatusTrueArray.len != 0x00)   
			{
				app.arduinoUart.scratchComID = app.arduinoUart.comStatusTrueArray[0];
				app.xuhy_test_log("avail com is COM"+app.arduinoUart.comStatusTrueArray[0]);
			}
			else  //长度为0，没有可以使用的串口
			{ 
				DialogBox.warnconfirm(Translator.map("error about firmware"),Translator.map("please open the COM"), null, app.stage);//软件界面中部显示提示框_wh
				return;
			}
		}
		writeUploaderOrderToCmd(app.arduinoUart.scratchComID);
	}
	
	public function writeUploaderOrderToCmd(scratchComID:int):void
	{
		file0= new File(File.applicationDirectory.resolvePath("avrtool").nativePath);//在相应目录下寻找或建立cmd.bat_wh
		var file:File = new File();
		file = file.resolvePath(file0.nativePath+"/cmd.exe");//调用cmd.exe_wh
		nativePSInfo.executable = file;
		process.start(nativePSInfo);//执行dos命令_wh
		process.standardInput.writeUTFBytes("cd /d "+file0.nativePath+"\r\n");//cmd命令路径，回车符，/r/n_wh
		process.standardInput.writeUTFBytes("avrdude -p m328p -c arduino -b 115200 -P COM"+scratchComID+" -U flash:w:S4A.hex"+"\r\n");//avrdude命令行_wh
		
		//等待文本框提示_wh
		UpDialog.setText(Translator.map("uploading") + " ... ");
		UpDialog.showOnStage(app.stage);
		ArduinoFirmFlag = 0;
		
		process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, cmdDataHandler);//cmd返回数据处理事件_wh	
		upLoadFirmTimer.start();//开启定时器,2s后开启cmd监听，跳过前两句返回信息
		upLoadFirmTimerCount = 1;		
	}
	
	private function onUpLoadFirmTimerTick(event:TimerEvent):void  
	{ 
		upLoadFirmTimerCount ++;
		if(ArduinoRPFlag == true)
		{
			if(upLoadFirmTimerCount == 71)//70s
			{
				{
					process.exit(nativePSInfo);//退出cmd.exe_wh
					process.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, cmdDataHandler);//移除侦听器_wh
					process2.start(nativePSInfo);//执行dos命令_wh
					process2.standardInput.writeUTFBytes("taskkill /f /im ArduinoUploader.exe /t"+"\r\n");//强行关闭avrdude进程_wh
					UpDialog.setText(Translator.map("upload failed"));
					upDialogSuccessFlag = false;
				}
			}
			if(upLoadFirmTimerCount == 73)//72s
			{
				upLoadFirmTimerCount = 0;
				process2.exit(nativePSInfo);
				upLoadFirmTimer.reset();
				ArduinoRPFlag = false;
//				app.arduinoUart.arduinoUart.connect("COM" +　app.arduinoUart.scratchComID,115200);//重新开启串口_wh
			}
		}
		else
		{
			if(upLoadFirmTimerCount == 71)//70s
			{
				{
					process.exit(nativePSInfo);//退出cmd.exe_wh
					process.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, cmdDataHandler);//移除侦听器_wh
					process2.start(nativePSInfo);//执行dos命令_wh
					process2.standardInput.writeUTFBytes("taskkill /f /im avrdude.exe /t"+"\r\n");//强行关闭avrdude进程_wh
					UpDialog.setText(Translator.map("upload failed"));
					upDialogSuccessFlag = false;
				}
			}
			if(upLoadFirmTimerCount == 73)//72s
			{
				upLoadFirmTimerCount = 0;
				process2.exit(nativePSInfo);
				upLoadFirmTimer.reset();
//				app.arduinoUart.arduinoUart.connect("COM" +　app.arduinoUart.scratchComID,115200);//重新开启串口_wh
			}
		}
	}
	
	//40s长时间没收到信息，说明下载出现问题，进行停止措施，该函数一般不会执行到_wh
	private function onupLoadFirmTimerComplete(event:TimerEvent):void 
	{ 
		process2.exit(nativePSInfo);
		upLoadFirmTimer.reset();
		ArduinoRPFlag = false;
		upLoadFirmTimerCount = 0;
//		app.arduinoUart.arduinoUart.connect("COM" +　app.arduinoUart.scratchComID,115200);//重新开启串口_wh
	} 
	
	//cmd返回数据处理事件函数_wh
	public function cmdDataHandler(event:ProgressEvent):void {
		var str:String = process.standardOutput.readUTFBytes(process.standardOutput.bytesAvailable); 
		trace(str);
		if(DriveFlag)
		{
			if(DriveFlag == 2)
			{
				process.exit(nativePSInfo);//退出cmd.exe_wh
				process.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, cmdDataHandler);//移除侦听器_wh
				DriveFlag = 0;
			}
			if(str.indexOf("CH341SER") != -1)
			{
				DriveFlag = 2;
			}	
		}
		else
		{
			if(ArduinoRPFlag == true)
			{
				if(str.indexOf("Compiliation:") != -1)
				{
					UpDialog.setText(Translator.map("uploading") + " ... ");
				}
				if(str.indexOf("Writing | ") != -1)
				{
					UpDialog.setText(Translator.map("upload success"));
					upDialogSuccessFlag = true;
					process.exit(nativePSInfo);//退出cmd.exe_wh
					process.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, cmdDataHandler);//移除侦听器_wh
//					app.arduinoUart.arduinoUart.connect("COM" +　app.arduinoUart.scratchComID,115200);//重新开启串口_wh
					upLoadFirmTimer.reset();
					upLoadFirmTimerCount = 0;
					ArduinoRPFlag = false;
				}
			}
			else
			{
				if(str.indexOf("avrtool>") != -1)
				{
					if(ArduinoFirmFlag)
					{
						if(upLoadFirmTimerCount < 4)
						{
							upLoadFirmTimerCount = 70;//表示停止_wh
							ArduinoFirmFlag = 9;
						}
						else
						{
							if(ArduinoFirmFlag < 9)
							{
								UpDialog.setText(Translator.map("upload success"));
								upDialogSuccessFlag = true;
								process.exit(nativePSInfo);//退出cmd.exe_wh
								process.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, cmdDataHandler);//移除侦听器_wh
//								app.arduinoUart.arduinoUart.connect("COM" +　app.arduinoUart.scratchComID,115200);//重新开启串口_wh
								upLoadFirmTimer.reset();
								upLoadFirmTimerCount = 0;
							}
						}
					}
					else
						ArduinoFirmFlag ++;
				}
			}
		}
	}
	
	public function cancel():void {
		UpDialog.cancel();
		if((upLoadFirmTimerCount < 70) && (upLoadFirmTimerCount != 0))
			upLoadFirmTimerCount = 70;//表示停止_wh
	}
	
}}
