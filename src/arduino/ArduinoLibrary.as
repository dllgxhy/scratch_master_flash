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
import flash.utils.Timer;
import flash.events.TimerEvent;
import flash.events.ProgressEvent;

import translation.Translator;

import uiwidgets.DialogBox;


import primitives.Primitives;
import flash.filesystem.File;
import flash.filesystem.FileStream;
import flash.filesystem.FileMode;

public class ArduinoLibrary extends Sprite{
	
	public var app:Scratch;
	public var ArduinoWarnFlag:Boolean    = false;//Arduino过程中是否有警告框弹出_wh
	
	public var arduinoLightValue:int      = 0x00;  //板载sensor数据
	public var arduinoSlideValue:int      = 0x00;
	public var arduinoSoundValue:int      = 0x00;
	public var arduinoUltrasonicValue:int = 0x00;
	
	public var arduinoDIOPin2:int = 0x00;    //读取到的数字IO口数据，D2~D13
	public var arduinoDIOPin3:int = 0x00;
	public var arduinoDIOPin4:int = 0x00;    
	public var arduinoDIOPin5:int = 0x00;
	public var arduinoDIOPin6:int = 0x00;
	public var arduinoDIOPin7:int = 0x00;
	public var arduinoDIOPin8:int = 0x00;
	public var arduinoDIOPin9:int = 0x00;   
	public var arduinoDIOPin10:int = 0x00;
	public var arduinoDIOPin11:int = 0x00;
	public var arduinoDIOPin12:int = 0x00;
	public var arduinoDIOPin13:int = 0x00;
	
	public var arduinoAIOPin0:int = 0x00; 	//读取的模拟IO口数据，A0~A5  
	public var arduinoAIOPin1:int = 0x00;
	public var arduinoAIOPin2:int = 0x00;
	public var arduinoAIOPin3:int = 0x00;
	public var arduinoAIOPin4:int = 0x00;
	public var arduinoAIOPin5:int = 0x00;
	
	//固件下载
	public var file0:File;
	public var process:NativeProcess = new NativeProcess();  //用来调用本地程序
	public var process2:NativeProcess = new NativeProcess();
	public var nativePSInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
	public var upLoadFirmTimerCount:int = 0x00;// 用于上传固件时的计时处理，有超时处理功能
	public var upLoadFirmTimer:Timer;//定时器
	public var ArduinoFirmFlag:Number = 0;
	public var ArduinoRPFlag:Boolean = false;//Arduino生成模块右键选择相关项是否按下
	public var ArduinoRPNum:Number = 0;//Arduino生成模块右键选择相关项编号
	//public var UpDialog:DialogBox = new DialogBox();
	public var upDialogSuccessFlag:Boolean = false;
	
	//CH340安装驱动
	public var DriveFlag:Number = 0;    //驱动安装变量值
	
	//Scratch生成程序
							                      //下面四个变量的用途没搞明白
	public var ArduinoValDefStr:Array  = new Array;//是否Arduino程序生成中已经变量定义_wh
	public var ArduinoValDefFlag:Array = new Array;//是否Arduino程序生成中已经变量定义_wh
	public var ArduinoValDefi:Number   = 0;//是否Arduino程序生成中已经变量定义_wh
	public var ArduinoIfElseB:Array    = new Array;//ifelse模块的stack2_wh
	
	public var ArduinoFlag:Boolean      = false;//是否需要生成Arduino程序_wh
	public var ArduinoLoopFlag:Boolean  = false;//是否进入Loop_wh
	public var ArduinoReadFlag:Boolean  = false;//当前同一条目下是否为读操作_wh
	public var ArduinoReadStr:Array     = new Array;//先存储读的Arduino语句_wh
	public var ArduinoValueFlag:Boolean = false;//是否有变量保持字符类型_wh
	public var ArduinoValueStr:String   = new String;//变量字符型_wh
	public var ArduinoMathFlag:Boolean  = false;//是否有运算保持字符类型_wh
	public var ArduinoMathStr:Array     = new Array;//运算字符型_wh
	public var ArduinoMathNum:Number    = 0;//运算嵌入层数_wh
	
	public var ArduinoFile:File;//_wh
	public var ArduinoFs:FileStream;//_wh
	public var ArduinoFileB:File;//_wh
	public var ArduinoFsB:FileStream;//_wh
	public var ArduinoPinFile:File;//pinmode_wh
	public var ArduinoPinFs:FileStream;//_wh
	public var ArduinoDoFile:File;//_wh
	public var ArduinoDoFs:FileStream;//_wh
	public var ArduinoHeadFile:File;//include和变量定义_wh
	public var ArduinoHeadFs:FileStream;//_wh
	public var ArduinoLoopFile:File;//循环_wh
	public var ArduinoLoopFs:FileStream;//_wh

	
	// 包含头文件时需要这个参数
	public var ArduinoUs: Boolean = false;//超声波_wh
	public var ArduinoSeg:Boolean = false;//数码管_wh
	public var ArduinoRGB:Boolean = false;//三色灯_wh
	public var ArduinoBuz:Boolean = false;//无源蜂鸣器_wh
	public var ArduinoCap:Boolean = false;//电容值_wh
	public var ArduinoDCM:Boolean = false;//方向电机_wh
	public var ArduinoSer:Boolean = false;//舵机_wh
	public var ArduinoIR: Boolean = false;//红外遥控_wh
	public var ArduinoTem:Boolean = false;//温度_wh
	public var ArduinoAvo:Boolean = false;//避障_wh
	public var ArduinoTra:Boolean = false;//循迹_wh
	public var ArduinoLCD1602:Boolean = false;//LCD1602_xuhy
	
	//if--else-- 语句 for 语句等都需要添加{};此处标注哪里有"}" 生成
	public var ArduinoPin:Array          = new Array;//pinmode无定义：0；输入：1；输出：2_wh
	public var ArduinoBlock:Array        = new Array ;//创趣模块类变量是否定义：无：0；是：1_wh
	public var ArduinoBracketFlag:Number = 0;//是否需要加尾部括号（例如if内部代码块尾部）_wh
	public var ArduinoIEFlag:int         = 0;//是否需要加尾部括号（IfElse的if后面）_wh
	public var ArduinoIEFlag2:int        = 0;//_wh
	public var ArduinoIEFlagIE:Boolean   = false;//_wh
	public var ArduinoIEFlagAll:int      = 0;//需要加尾部括号总量（IfElse的if后面）
	public var ArduinoIEElseNum:int      = 0;
	public var ArduinoIEElseFlag:int     = 0;//是否需要加尾部括号（IfElse的else后面）
	public var ArduinoIEElseFlag2:int    = 0;
	
	
	
	//Arduino
	
	
	public function ArduinoLibrary(app:Scratch)
	{
		this.app = app;
		upLoadFirmTimer = new Timer(300, 75);//每1s一个中断，持续75s 在线约10s，无线61s
		upLoadFirmTimer.addEventListener(TimerEvent.TIMER, onUpLoadFirmTimerTick); 
		upLoadFirmTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onupLoadFirmTimerComplete);
		//UpDialog.addTitle('Upload');
		//UpDialog.addButton('Close',cancel);
		//UpDialog.addText(Translator.map("uploading") + " ... ");
		GenerateFilesForScratch2ArduinoFirmwareCode();
		
		ArduinoBlock[app.arduinoUart.ID_ReadAFloat] = new Array();//二维数组新建，Arduino生成过程避免变量反复定义用_wh
		ArduinoBlock[app.arduinoUart.ID_ReadPFloat] = new Array();//二维数组新建，Arduino生成过程避免变量反复定义用_wh
		ArduinoBlock[app.arduinoUart.ID_SetSG] = new Array();//二维数组新建，Arduino生成过程避免变量反复定义用_wh
		ArduinoBlock[app.arduinoUart.ID_SetDM] = new Array();//二维数组新建，Arduino生成过程避免变量反复定义用_wh
		ArduinoBlock[app.arduinoUart.ID_SetNUM] = new Array();//二维数组新建，Arduino生成过程避免变量反复定义用_wh
		ArduinoBlock[app.arduinoUart.ID_SetMUS] = new Array();//二维数组新建，Arduino生成过程避免变量反复定义用_wh
	}
	
	/*Arduino固件烧入程序
	* AS3中调用Arduino的编译器程序
	* 
	*/
	public function dofirm():void {
		//烧入固件前先判断串口，未打开则之间退出，打开则先关闭（否则串口被占用）_wh
		app.xuhy_test_log("dofirm()");
		writeUploaderOrderToCmd(app.arduinoUart.scratchComID);
	}
	
	public function writeUploaderOrderToCmd(scratchComID:int):void{
		file0= new File(File.applicationDirectory.resolvePath("avrtool").nativePath);//在相应目录下寻找或建立cmd.bat_wh
		var file:File = new File();
		file = file.resolvePath(file0.nativePath+"/cmd.exe");//调用cmd.exe_wh
		nativePSInfo.executable = file;
		process.start(nativePSInfo);//执行dos命令_wh
		process.standardInput.writeUTFBytes("cd /d "+file0.nativePath+"\r\n");//cmd命令路径，回车符，/r/n_wh
		process.standardInput.writeUTFBytes("avrdude -p m328p -c arduino -b 115200 -P COM"+scratchComID+" -U flash:w:S4A.hex"+"\r\n");//avrdude命令行_wh
		
		//等待文本框提示_wh
		//UpDialog.setText(Translator.map("uploading") + " ... ");
		//UpDialog.showOnStage(app.stage);
		ArduinoFirmFlag = 0;
		
		process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, cmdDataHandler);//cmd返回数据处理事件_wh	
		upLoadFirmTimer.start();//开启定时器,2s后开启cmd监听，跳过前两句返回信息
		upLoadFirmTimerCount = 1;		
	}
	
	private function onUpLoadFirmTimerTick(event:TimerEvent):void { 
		upLoadFirmTimerCount ++;
		app.xuhy_test_log("upLoadFirmTimerCount ="+ upLoadFirmTimerCount);
		if(ArduinoRPFlag == true)
		{
			if(upLoadFirmTimerCount == 71)//70s
			{
				{
					process.exit(nativePSInfo);//退出cmd.exe_wh
					process.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, cmdDataHandler);//移除侦听器_wh
					process2.start(nativePSInfo);//执行dos命令_wh
					process2.standardInput.writeUTFBytes("taskkill /f /im ArduinoUploader.exe /t"+"\r\n");//强行关闭avrdude进程_wh
					//UpDialog.setText(Translator.map("upload failed"));		
				}
			}
			if(upLoadFirmTimerCount == 73)//72s
			{
				upLoadFirmTimerCount = 0;
				process2.exit(nativePSInfo);
				upLoadFirmTimer.reset();
				ArduinoRPFlag = false;
				app.arduinoUart.arduinoUartClose();
				app.arduinoUartConnect.findAvailComIDForArduinoTimerIDOccupy = false;
				app.xuhy_test_log("onUpLoadFirmTimerTick ArduinoRPFlag upLoadFirmTimerCount = 73");
				upDialogSuccessFlag = false;
			}
		}
		else
		{
			if(upLoadFirmTimerCount == 71)//70s
			{
				process.exit(nativePSInfo);//退出cmd.exe_wh
				process.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, cmdDataHandler);//移除侦听器_wh
				process2.start(nativePSInfo);//执行dos命令_wh
				process2.standardInput.writeUTFBytes("taskkill /f /im avrdude.exe /t"+"\r\n");//强行关闭avrdude进程_wh
				//UpDialog.setText(Translator.map("upload failed"));
				upDialogSuccessFlag = false;
				
			}
			if(upLoadFirmTimerCount == 73)//72s
			{
				upLoadFirmTimerCount = 0;
				process2.exit(nativePSInfo);
				upLoadFirmTimer.reset();
				app.arduinoUart.arduinoUartClose();
				app.arduinoUartConnect.findAvailComIDForArduinoTimerIDOccupy = false;
				app.xuhy_test_log("onUpLoadFirmTimerTick        upLoadFirmTimerCount == 73");
			}
		}
	}
	
	//40s长时间没收到信息，说明下载出现问题，进行停止措施，该函数一般不会执行到_wh
	private function onupLoadFirmTimerComplete(event:TimerEvent):void{ 
		process2.exit(nativePSInfo);
		upLoadFirmTimer.reset();
		ArduinoRPFlag = false;
		upLoadFirmTimerCount = 0;
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
					//UpDialog.setText(Translator.map("uploading") + " ... ");
				}
				if(str.indexOf("Writing | ") != -1)
				{
					//UpDialog.setText(Translator.map("upload success"));
					upDialogSuccessFlag = true;
					process.exit(nativePSInfo);//退出cmd.exe_wh
					process.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, cmdDataHandler);//移除侦听器_wh
					upLoadFirmTimer.reset();
					upLoadFirmTimerCount = 0;
					ArduinoRPFlag = false;
					app.arduinoUartConnect.findAvailComIDForArduinoTimerIDOccupy = false;
					app.arduinoUartConnect.checkUartAvail(app.arduinoUart.scratchComID);
					app.arduinoUartConnect.setAutoConnect();
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
							app.xuhy_test_log("str.indexOf  upLoadFirmTimerCount = "+upLoadFirmTimerCount);
							upLoadFirmTimerCount = 70;//表示停止_wh
							ArduinoFirmFlag = 9;
						}
						else
						{
							if(ArduinoFirmFlag < 9)
							{
								//UpDialog.setText(Translator.map("upload success"));
								upDialogSuccessFlag = true;
								process.exit(nativePSInfo);//退出cmd.exe_wh
								process.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, cmdDataHandler);//移除侦听器_wh
								upLoadFirmTimer.reset();
								upLoadFirmTimerCount = 0;
								app.arduinoUartConnect.findAvailComIDForArduinoTimerIDOccupy = false;
								app.arduinoUartConnect.checkUartAvail(app.arduinoUart.scratchComID);
								app.arduinoUartConnect.setAutoConnect();
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
		app.arduinoUartConnect.resetUartStateLightState();			//关闭串口连接指示灯和时钟add by xuhy	
		app.arduinoUartConnect.setUartDisconnect();				//关闭串口
		//UpDialog.cancel();
		if((upLoadFirmTimerCount < 70) && (upLoadFirmTimerCount != 0))
			upLoadFirmTimerCount = 0;//表示停止_wh
	}
	
	
	/*
	 * *以下程序为Scratch生成Arduino固件代码的程序
	 * */
	
	public function GenerateFilesForScratch2ArduinoFirmwareCode():void{
	 		//Arduino程序生成相关文件新建_wh
		ArduinoHeadFile= new File(File.userDirectory.resolvePath("AS-Block/arduinos/head.txt").nativePath);
		ArduinoHeadFs = new FileStream();
		ArduinoPinFile= new File(File.userDirectory.resolvePath("AS-Block/arduinos/pin.txt").nativePath);
		ArduinoPinFs = new FileStream();
		ArduinoDoFile= new File(File.userDirectory.resolvePath("AS-Block/arduinos/do.txt").nativePath);
		ArduinoDoFs = new FileStream();
		ArduinoLoopFile= new File(File.userDirectory.resolvePath("AS-Block/arduinos/loop.txt").nativePath);
		ArduinoLoopFs = new FileStream();
		ArduinoFile= new File(File.userDirectory.resolvePath("AS-Block/arduinos/arduinos.ino").nativePath);
		ArduinoFs = new FileStream();
		ArduinoFileB= new File(File.userDirectory.resolvePath("AS-Block/ArduinoBuilder/arduinos.ino").nativePath);
		ArduinoFsB = new FileStream();

		app.xuhy_test_log("GenerateFilesForScratch2ArduinoFirmwareCode");
	} 
	
	
	
	public function GenerateArduinoFirmwareCode():void {	
		if(ArduinoFlag == true)
		{
			if(ArduinoRPFlag == true){
				ArduinoFs.writeUTFBytes('/* 少年创客 */' + '\n' + 
											'/* YoungMaker */' + '\n' +
											'/* www.youngmaker.com */' + '\n');
				ArduinoFs.writeUTFBytes('#include "YoungMakerPort.h"' + '\n');
				
				if(ArduinoLCD1602)
				{
					ArduinoFs.writeUTFBytes('#include "YoungMakerCrystal.h" ' + '\n');
				}
				else
				{
					ArduinoFs.writeUTFBytes('#include <Wire.h>' + '\n');
				}				
					
				if(ArduinoUs)
					ArduinoFs.writeUTFBytes('#include "YoungMakerUltrasonic.h" ' + '\n');
				if(ArduinoSeg)
					ArduinoFs.writeUTFBytes('#include "YoungMaker7SegmentDisplay.h" ' + '\n');
				if(ArduinoRGB)
					ArduinoFs.writeUTFBytes('#include "YoungMakerRGBLed.h" ' + '\n');	
				if(ArduinoBuz)
					ArduinoFs.writeUTFBytes('#include "YoungMakerBuzzer.h" ' + '\n');
				if(ArduinoCap)
					ArduinoFs.writeUTFBytes('#include "YoungMakerCapacitive.h" ' + '\n');
				if(ArduinoDCM)
					ArduinoFs.writeUTFBytes('#include "YoungMakerDCMotor.h" ' + '\n');
				if(ArduinoSer)
					ArduinoFs.writeUTFBytes('#include "Servo.h" ' + '\n');
				if(ArduinoIR)
					ArduinoFs.writeUTFBytes('#include "YoungMakerIR.h" ' + '\n');
				if(ArduinoTem)
					ArduinoFs.writeUTFBytes('#include "YoungMakerTemperature.h" ' + '\n');
				if(ArduinoAvo)
					ArduinoFs.writeUTFBytes('#include "YoungMakerAvoid.h" ' + '\n');
				if(ArduinoTra)
					ArduinoFs.writeUTFBytes('#include "YoungMakerTrack.h" ' + '\n');
				
				ArduinoHeadFs.open(ArduinoHeadFile,FileMode.READ);
				ArduinoHeadFs.position = 0;
				ArduinoFs.writeUTFBytes(ArduinoHeadFs.readMultiByte(ArduinoHeadFs.bytesAvailable,'utf-8'));//head_wh
				
				ArduinoFs.writeUTFBytes('\n' + "void setup(){" + '\n');
				
				//app.ArduinoPinFs.close();
				ArduinoPinFs.open(ArduinoPinFile,FileMode.READ);
				ArduinoPinFs.position = 0;
				ArduinoFs.writeUTFBytes(ArduinoPinFs.readMultiByte(ArduinoPinFs.bytesAvailable,'utf-8'));//pinmode_wh
				
				//app.ArduinoDoFs.close();
				ArduinoDoFs.open(ArduinoDoFile,FileMode.READ);
				ArduinoDoFs.position = 0;
				ArduinoFs.writeUTFBytes(ArduinoDoFs.readMultiByte(ArduinoDoFs.bytesAvailable,'utf-8'));//do_wh
				
				ArduinoFs.writeUTFBytes("}"+'\n');
				
				ArduinoFs.writeUTFBytes('\n'+"void loop(){"+'\n');
			
				ArduinoLoopFs.open(ArduinoLoopFile,FileMode.READ);
				ArduinoLoopFs.position = 0;
				ArduinoFs.writeUTFBytes(ArduinoLoopFs.readMultiByte(ArduinoLoopFs.bytesAvailable,'utf-8'));//loop_wh
				
				ArduinoFs.writeUTFBytes("}"+'\n');
				
				//超声波中断处理函数
				if(ArduinoUs)
					ArduinoFs.writeUTFBytes('\n' + 'void ius(){' +'\n'
												+ '_iustime = micros()-_itime;' +'\n'
												+ 'noInterrupts();' +'\n'
												+ '}'
												+'\n');
			}
			
			ArduinoHeadFs.close();
			ArduinoPinFs.close();
			ArduinoDoFs.close();
			ArduinoFs.close();
			ArduinoFlag = false;
			
			//xuhy 20160927
			for (var i:int = 0; i < ArduinoValDefi; i++)//变量定义标志重新归0_wh
			{
				ArduinoValDefFlag[i] = 0;
			}
			
			if(ArduinoRPFlag == true)
			{
				if(ArduinoWarnFlag == false)
				{
					if(ArduinoRPNum == 2)
					{
						ArduinoRPNum = 0;
						ArduinoFile.openWithDefaultApplication();//用默认的IDE打开_wh
						app.xuhy_test_log("用IDE打开程序代码");
					}
					
					if(ArduinoRPNum == 1)
					{
						ArduinoRPNum = 0;
						ArduinoFile.copyTo(ArduinoFileB,true);//将arduinos.ino复制到ArduinoBuilder目录下_wh
						
						if(app.arduinoUartConnect.comStatus == 0x00)
							app.arduinoUartConnect.setUartDisconnect();

						else
						{
							ArduinoRPFlag = false;
							DialogBox.warnconfirm(Translator.map("error about uploading to arduino"),Translator.map("please open the COM"), null, app.stage);//软件界面中部显示提示框_wh
							return;
						}
						var file:File = new File();
	//							var process:NativeProcess = new NativeProcess();
	//							var nativePSInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
						file = file.resolvePath(File.userDirectory.resolvePath("AS-Block/ArduinoBuilder/cmd.exe").nativePath);//调用cmd.exe_wh
						nativePSInfo.executable = file;
						process.start(nativePSInfo);//执行dos命令_wh
						var str:String = File.userDirectory.resolvePath("AS-Block/ArduinoBuilder").nativePath;
						process.standardInput.writeUTFBytes("cd /d "+ File.userDirectory.resolvePath("AS-Block/ArduinoBuilder").nativePath +"\r\n");//cmd命令路径，回车符，/r/n_wh
						process.standardInput.writeUTFBytes("ArduinoUploader arduinos.ino 1 " + app.arduinoUart. scratchComID + " 16MHZ" + "\r\n");//avrdude命令行_wh

						//UpDialog.setText(Translator.map("compiliation") + " ... ");
						//UpDialog.showOnStage(app.stage);

						upLoadFirmTimer.start();//开启定时器_wh
						upLoadFirmTimerCount = 1;
						process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA,cmdDataHandler);//cmd返回数据处理事件_wh	
					}
				}
			}
		}
	}
	
	/*
	 * *
	 * 下载CH340驱动
	 * CH340的驱动程序名为CH341SER.exe,文件所在位置为avrtool的目录下
	*/
	public function dodrive():void {
		file0= new File(File.applicationDirectory.resolvePath("avrtool").nativePath); //找到avrtool的目录
		var file:File = new File();
		file = file.resolvePath(file0.nativePath+"/cmd.exe");//调用cmd.exe
		nativePSInfo.executable = file;
		process.start(nativePSInfo);//执行cmd.exe命令
		process.standardInput.writeUTFBytes("cd /d "+file0.nativePath+"\r\n");//进入avrtool的目录
		process.standardInput.writeUTFBytes("CH341SER"+"\r\n");//运行CH341SER命令，调用驱动
		process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, cmdDataHandler);//cmd返回数据处理事件_wh	
		DriveFlag = 1;	
	}
	
	

	/**************************************************************************************************/
	/* Model Math*/
	/* function add*/
	public function funtionAdd(b:*):* {
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			ArduinoMathNum++;
			app.interp.numarg(b, 0);
			ArduinoMathNum--;
			if(ArduinoReadFlag == true){
				ArduinoMathStr[ArduinoMathNum] = "(" + "(" + ArduinoReadStr[0] + ") + (";
				ArduinoReadFlag = false;
			}
			else{
				if(ArduinoMathFlag == true)
				{
					ArduinoMathStr[ArduinoMathNum] = "(" + "(" + ArduinoMathStr[ArduinoMathNum+1] + ") + (";
					ArduinoMathFlag = false;
				}
				else{
					if(ArduinoValueFlag == true){
						ArduinoMathStr[ArduinoMathNum] = "(" + "(" + ArduinoValueStr + ") + (";
						ArduinoValueFlag = false;
					}
					else{
						ArduinoMathStr[ArduinoMathNum] = "(" + "(" + app.interp.numarg(b, 0) + ") + (";
					}
				}	
			}							
			ArduinoMathNum ++;
			app.interp.numarg(b, 1);
			ArduinoMathNum --;
			if(ArduinoReadFlag == true){
				ArduinoMathStr[ArduinoMathNum] += ArduinoReadStr[0] + "))";
				ArduinoReadFlag = false;
			}
			else
			{
				if(ArduinoMathFlag == true)
				{
					ArduinoMathStr[ArduinoMathNum] += ArduinoMathStr[ArduinoMathNum+1] + "))";
					ArduinoMathFlag = false;
				}
				else{
					if(ArduinoValueFlag == true)
					{
						ArduinoMathStr[ArduinoMathNum] += ArduinoValueStr + "))";
						ArduinoValueFlag = false;
					}
					else{
						ArduinoMathStr[ArduinoMathNum] += app.interp.numarg(b, 1) + "))";
					}
				}		
			}
				
			ArduinoMathFlag = true;
			
		}
		else{
			return app.interp.numarg(b, 0) + app.interp.numarg(b, 1);
		}			
	} 
	
	/* Model Math*/
	/* function subtracting*/	
	public function functionSubtracting(b:*):*{
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			ArduinoMathNum++;
			app.interp.numarg(b, 0);
			ArduinoMathNum--;
			if(ArduinoReadFlag == true)
			{
				ArduinoMathStr[ArduinoMathNum] = "(" + "(" + ArduinoReadStr[0] + ") - (";
				ArduinoReadFlag = false;
			}
			else
			{
				if(ArduinoMathFlag == true)
				{
					ArduinoMathStr[ArduinoMathNum] = "(" + "(" + ArduinoMathStr[ArduinoMathNum+1] + ") - (";
					ArduinoMathFlag = false;
				}
				else
				{
					if(ArduinoValueFlag == true)
					{
						ArduinoMathStr[ArduinoMathNum] = "(" + "(" + ArduinoValueStr + ") - (";
						ArduinoValueFlag = false;
					}
					else
					{
						ArduinoMathStr[ArduinoMathNum] = "(" + "(" + app.interp.numarg(b, 0) + ") - (";
					}
				}
			}				
			ArduinoMathNum ++;
			app.interp.numarg(b, 1);
			ArduinoMathNum --;
			if(ArduinoReadFlag == true)
			{
				ArduinoMathStr[ArduinoMathNum] += ArduinoReadStr[0] + "))";
				ArduinoReadFlag = false;
			}
			else
			{
				if(ArduinoMathFlag == true)
				{
					ArduinoMathStr[ArduinoMathNum] += ArduinoMathStr[ArduinoMathNum+1] + "))";
					ArduinoMathFlag = false;
				}
				else
				{
					if(ArduinoValueFlag == true)
					{
						ArduinoMathStr[ArduinoMathNum] += ArduinoValueStr + "))";
						ArduinoValueFlag = false;
					}
					else
					{
						ArduinoMathStr[ArduinoMathNum] += app.interp.numarg(b, 1) + "))";
					}	
				}		
				ArduinoMathFlag = true;
			}
				
		}
		else
			return app.interp.numarg(b, 0) - app.interp.numarg(b, 1);
	}

	/* Model Math*/
	/* function multiply*/	
	public function functionMultiply(b:*):*{
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			ArduinoMathNum++;
			app.interp.numarg(b, 0);
			ArduinoMathNum--;
			if(ArduinoReadFlag == true)
			{
				ArduinoMathStr[ArduinoMathNum] = "(" + "(" + ArduinoReadStr[0] + ") * (";
				ArduinoReadFlag = false;
			}
			else
				if(ArduinoMathFlag == true)
				{
					ArduinoMathStr[ArduinoMathNum] = "(" + "(" + ArduinoMathStr[ArduinoMathNum+1] + ") * (";
					ArduinoMathFlag = false;
				}
				else
				{
					if(ArduinoValueFlag == true)
					{
						ArduinoMathStr[ArduinoMathNum] = "(" + "(" + ArduinoValueStr + ") * (";
						ArduinoValueFlag = false;
					}
					else{
						ArduinoMathStr[ArduinoMathNum] = "(" + "(" + app.interp.numarg(b, 0) + ") * (";
					}	
				}
			ArduinoMathNum++;
			app.interp.numarg(b, 1);
			ArduinoMathNum--;
			if(ArduinoReadFlag == true)
			{
				ArduinoMathStr[ArduinoMathNum] += ArduinoReadStr[0] + "))";
				ArduinoReadFlag = false;
			}
			else
			{
				if(ArduinoMathFlag == true)
				{
					ArduinoMathStr[ArduinoMathNum] += ArduinoMathStr[ArduinoMathNum+1] + "))";
					ArduinoMathFlag = false;
				}
				else
				{
					if(ArduinoValueFlag == true)
					{
						ArduinoMathStr[ArduinoMathNum] += ArduinoValueStr + "))";
						ArduinoValueFlag = false;
					}
					else
					{
						ArduinoMathStr[ArduinoMathNum] += app.interp.numarg(b, 1) + "))";
					}	
					ArduinoMathFlag = true;
				}	
			}
		}
		else{
			return app.interp.numarg(b, 0) * app.interp.numarg(b, 1);
		}
	}

	/* Model Math*/
	/* function division*/	
	public function functionDivision(b:*):*{
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			ArduinoMathNum++;
			app.interp.numarg(b, 0);
			ArduinoMathNum--;
			if(ArduinoReadFlag == true)
			{
				ArduinoMathStr[ArduinoMathNum] = "(" + "(" + ArduinoReadStr[0] + ") / (";
				ArduinoReadFlag = false;
			}
			else
				if(ArduinoMathFlag == true)
				{
					ArduinoMathStr[ArduinoMathNum] = "(" + "(" + ArduinoMathStr[ArduinoMathNum+1] + ") / (";
					ArduinoMathFlag = false;
				}
				else
					if(ArduinoValueFlag == true)
					{
						ArduinoMathStr[ArduinoMathNum] = "(" + "(" + ArduinoValueStr + ") / (";
						ArduinoValueFlag = false;
					}
					else
						ArduinoMathStr[ArduinoMathNum] = "(" + "(" + app.interp.numarg(b, 0) + ") / (";
			ArduinoMathNum++;
			app.interp.numarg(b, 1);
			ArduinoMathNum--;
			if(ArduinoReadFlag == true)
			{
				ArduinoMathStr[ArduinoMathNum] += ArduinoReadStr[0] + "))";
				ArduinoReadFlag = false;
			}
			else
				if(ArduinoMathFlag == true)
				{
					ArduinoMathStr[ArduinoMathNum] += ArduinoMathStr[ArduinoMathNum+1] + "))";
					ArduinoMathFlag = false;
				}
				else
					if(ArduinoValueFlag == true)
					{
						ArduinoMathStr[ArduinoMathNum] += ArduinoValueStr + "))";
						ArduinoValueFlag = false;
					}
					else
						ArduinoMathStr[ArduinoMathNum] += app.interp.numarg(b, 1) + "))";
			ArduinoMathFlag = true;
		}
		else
			return app.interp.numarg(b, 0) / app.interp.numarg(b, 1);
	}
	
	/*Model Operator*/
	/*function randomFrom:to:*/
	public function function_randomFromTo(b:*):*{
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			ArduinoMathNum++;
			app.interp.numarg(b, 0);
			ArduinoMathNum--;
			if(ArduinoReadFlag == true)
			{
				ArduinoMathStr[ArduinoMathNum] = "random(" + ArduinoReadStr[0] + ",";
				ArduinoReadFlag = false;
			}
			else
				if(ArduinoMathFlag == true)
				{
					ArduinoMathStr[ArduinoMathNum] = "random(" + ArduinoMathStr[ArduinoMathNum+1] + ",";
					ArduinoMathFlag = false;
				}
				else
					if(ArduinoValueFlag == true)
					{
						ArduinoMathStr[ArduinoMathNum] = "random(" + ArduinoValueStr + ",";
						ArduinoValueFlag = false;
					}
					else
						ArduinoMathStr[ArduinoMathNum] = "random(" + app.interp.numarg(b, 0) + ",";
			ArduinoMathNum++;
			app.interp.numarg(b, 1);
			ArduinoMathNum--;
			if(ArduinoReadFlag == true)
			{
				ArduinoMathStr[ArduinoMathNum] += ArduinoReadStr[0] + ")";
				ArduinoReadFlag = false;
			}
			else
				if(ArduinoMathFlag == true)
				{
					ArduinoMathStr[ArduinoMathNum] += ArduinoMathStr[ArduinoMathNum+1] + ")";
					ArduinoMathFlag = false;
				}
				else
					if(ArduinoValueFlag == true)
					{
						ArduinoMathStr[ArduinoMathNum] += ArduinoValueStr + ")";
						ArduinoValueFlag = false;
					}
					else
						ArduinoMathStr[ArduinoMathNum] += app.interp.numarg(b, 1) + ")";
			ArduinoMathFlag = true;
		}
		else
			return app.primitive.primRandom(b);
	}	
	
	
	/*Model Operator*/
	/*function "="  function_equal*/
	public function function_equal(b:*):*{
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			ArduinoMathNum++;
			app.interp.arg(b, 0);
			ArduinoMathNum--;
			if(ArduinoReadFlag == true)
			{
				ArduinoMathStr[ArduinoMathNum] = "(" + "(" + ArduinoReadStr[0] + ") == (";
				ArduinoReadFlag = false;
			}
			else{
				if(ArduinoMathFlag == true)
				{
					ArduinoMathStr[ArduinoMathNum] = "(" + "(" + ArduinoMathStr[ArduinoMathNum+1] + ") == (";
					ArduinoMathFlag = false;
				}
				else{
					if(ArduinoValueFlag == true)
					{
						ArduinoMathStr[ArduinoMathNum] = "(" + "(" + ArduinoValueStr + ") == (";
						ArduinoValueFlag = false;
					}
					else{
						ArduinoMathStr[ArduinoMathNum] = "(" + "(" + app.interp.numarg(b, 0) + ") == (";
					}
				}
			}
			ArduinoMathNum++;
			app.interp.arg(b, 1);
			ArduinoMathNum--;
			if(ArduinoReadFlag == true)
			{
				ArduinoMathStr[ArduinoMathNum] += ArduinoReadStr[0] + "))";
				ArduinoReadFlag = false;
			}
			else{
				if(ArduinoMathFlag == true)
				{
					ArduinoMathStr[ArduinoMathNum] += ArduinoMathStr[ArduinoMathNum+1] + "))";
					ArduinoMathFlag = false;
				}
				else{
					if(ArduinoValueFlag == true)
					{
						ArduinoMathStr[ArduinoMathNum] += ArduinoValueStr + "))";
						ArduinoValueFlag = false;
					}
					else{
						ArduinoMathStr[ArduinoMathNum] += app.interp.numarg(b, 1) + "))";
					}
				}
			}
			ArduinoMathFlag = true;
		}
		else
		{
			return (Primitives.compare(app.interp.arg(b, 0), app.interp.arg(b, 1)) == 0);
		}
	}
	
	/*Model Operator*/
	/*function "<" lessthan*/
	public function funtionLessThan(b:*):* {
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			ArduinoMathNum++;
			app.interp.arg(b, 0);
			ArduinoMathNum--;
			if(ArduinoReadFlag == true){
				ArduinoMathStr[ArduinoMathNum] = "(" + "(" + ArduinoReadStr[0] + ") < (";
				ArduinoReadFlag = false;
			}
			else{
				if(ArduinoMathFlag == true)
				{
					ArduinoMathStr[app.arduinoLib.ArduinoMathNum] = "(" + "(" + app.arduinoLib.ArduinoMathStr[app.arduinoLib.ArduinoMathNum+1] + ") < (";
					ArduinoMathFlag = false;
				}
				else
				{
					if(ArduinoValueFlag == true)
					{
						ArduinoMathStr[ArduinoMathNum] = "(" + "(" + ArduinoValueStr + ") < (";
						ArduinoValueFlag = false;
					}
					else
						ArduinoMathStr[ArduinoMathNum] = "(" + "(" + app.interp.numarg(b, 0) + ") < (";
				}		
			}
				
			ArduinoMathNum++;
			app.interp.arg(b, 1);
			ArduinoMathNum--;
			if(ArduinoReadFlag == true)
			{
				ArduinoMathStr[app.arduinoLib.ArduinoMathNum] += app.arduinoLib.ArduinoReadStr[0] + "))";
				ArduinoReadFlag = false;
			}
			else{
				if(ArduinoMathFlag == true)
				{
					ArduinoMathStr[app.arduinoLib.ArduinoMathNum] += app.arduinoLib.ArduinoMathStr[app.arduinoLib.ArduinoMathNum+1] + "))";
					ArduinoMathFlag = false;
				}
				else
				{
					if(ArduinoValueFlag == true)
					{
						ArduinoMathStr[app.arduinoLib.ArduinoMathNum] += app.arduinoLib.ArduinoValueStr + "))";
						ArduinoValueFlag = false;
					}
					else{
						app.arduinoLib.ArduinoMathStr[app.arduinoLib.ArduinoMathNum] += app.interp.numarg(b, 1) + "))";
					}	
				}	
			}
				
			ArduinoMathFlag = true;
		}
		else{
			return Primitives.compare(app.interp.arg(b, 0), app.interp.arg(b, 1)) < 0
		}
	}
	
	
	/*Model Operator*/
	/*function ">" morethan*/
	public function funtion_MoreThan(b:*):* {
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			ArduinoMathNum++;
			app.interp.arg(b, 0);
			ArduinoMathNum--;
			if(ArduinoReadFlag == true)
			{
				ArduinoMathStr[ArduinoMathNum] = "(" + "(" + ArduinoReadStr[0] + ") > (";
				ArduinoReadFlag = false;
			}
			else{
				if(ArduinoMathFlag == true)
				{
					ArduinoMathStr[ArduinoMathNum] = "(" + "(" + ArduinoMathStr[ArduinoMathNum+1] + ") > (";
					ArduinoMathFlag = false;
				}
				else{
					if(ArduinoValueFlag == true)
					{
						ArduinoMathStr[ArduinoMathNum] = "(" + "(" + ArduinoValueStr + ") > (";
						ArduinoValueFlag = false;
					}
					else{
						ArduinoMathStr[ArduinoMathNum] = "(" + "(" + app.interp.numarg(b, 0) + ") > (";
					}
				}
			}
			ArduinoMathNum++;
			app.interp.arg(b, 1);
			ArduinoMathNum--;
			if(ArduinoReadFlag == true)
			{
				ArduinoMathStr[ArduinoMathNum] += ArduinoReadStr[0] + "))";
				ArduinoReadFlag = false;
			}
			else{
				if(ArduinoMathFlag == true)
				{
					ArduinoMathStr[ArduinoMathNum] += ArduinoMathStr[ArduinoMathNum+1] + "))";
					ArduinoMathFlag = false;
				}
				else{
					if(ArduinoValueFlag == true)
					{
						ArduinoMathStr[ArduinoMathNum] += ArduinoValueStr + "))";
						ArduinoValueFlag = false;
					}
					else{
						ArduinoMathStr[ArduinoMathNum] += app.interp.numarg(b, 1) + "))";
					}
				}
			}
			ArduinoMathFlag = true;
		}
		else{
			return Primitives.compare(app.interp.arg(b, 0), app.interp.arg(b, 1)) > 0
		}
	}
	
	/*Model Operator*/
	/*function "&" And*/
	public function funtion_And(b:*):* {
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			ArduinoMathNum++;
			app.interp.arg(b, 0);
			ArduinoMathNum--;
			if(ArduinoReadFlag == true)
			{
				ArduinoMathStr[ArduinoMathNum] = "(" + "(" + ArduinoReadStr[0] + ") && (";
				ArduinoReadFlag = false;
			}
			else{
				if(ArduinoMathFlag == true)
				{
					ArduinoMathStr[ArduinoMathNum] = "(" + "(" + ArduinoMathStr[ArduinoMathNum+1] + ") && (";
					ArduinoMathFlag = false;
				}
			}
			ArduinoMathNum++;
			app.interp.arg(b, 1);
			ArduinoMathNum--;
			if(ArduinoReadFlag == true)
			{
				ArduinoMathStr[ArduinoMathNum] += ArduinoReadStr[0] + "))";
				ArduinoReadFlag = false;
			}
			else
			{
				if(ArduinoMathFlag == true)
				{
					ArduinoMathStr[ArduinoMathNum] += ArduinoMathStr[ArduinoMathNum+1] + "))";
					ArduinoMathFlag = false;
				}
			}	
			ArduinoMathFlag = true;
		}
		else{
			return (app.interp.arg(b, 0) && app.interp.arg(b, 1));
		}
	}
	
	/*Model Operator*/
	/*function "|" Or*/
	public function funtion_Or(b:*):* {
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			ArduinoMathNum++;
			app.interp.arg(b, 0);
			ArduinoMathNum--;
			if(ArduinoReadFlag == true)
			{
				ArduinoMathStr[ArduinoMathNum] = "(" + "(" + ArduinoReadStr[0] + ") || (";
				ArduinoReadFlag = false;
			}
			else
			{
				if(ArduinoMathFlag == true)
				{
					ArduinoMathStr[ArduinoMathNum] = "(" + "(" + ArduinoMathStr[ArduinoMathNum+1] + ") || (";
					ArduinoMathFlag = false;
				}
			}
			ArduinoMathNum++;
			app.interp.arg(b, 1);
			ArduinoMathNum--;
			if(ArduinoReadFlag == true)
			{
				ArduinoMathStr[ArduinoMathNum] += ArduinoReadStr[0] + "))";
				ArduinoReadFlag = false;
			}
			else
			{
				if(ArduinoMathFlag == true)
				{
					ArduinoMathStr[ArduinoMathNum] += ArduinoMathStr[ArduinoMathNum+1] + "))";
					ArduinoMathFlag = false;
				}
			}
			ArduinoMathFlag = true;
		}
		else
		{
			return (app.interp.arg(b, 0) || app.interp.arg(b, 1));
		}
	}
	
	/*Model Operator*/
	/*function "~" NOT*/
	public function funtion_Not(b:*):* {
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			ArduinoMathNum++;
			app.interp.arg(b, 0);
			ArduinoMathNum--;
			if(ArduinoReadFlag == true)
			{
				ArduinoMathStr[ArduinoMathNum] = "!(" + ArduinoReadStr[0] + ")";
				ArduinoReadFlag = false;
			}
			else
			{
				if(ArduinoMathFlag == true)
				{
					ArduinoMathStr[ArduinoMathNum] = "!(" + ArduinoMathStr[ArduinoMathNum+1] + ")";
					ArduinoMathFlag = false;
				}
			}
			ArduinoMathFlag = true;
		}
		else
		{
			return (!app.interp.arg(b, 0));
		}	
	}
	
	/*Model Operator*/
	/*function "concatenate:with:" */
	public function funtion_concatenate_with(b:*):* {
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			DialogBox.warnconfirm(Translator.map("can't support this block,please remove it"),Translator.map("jion ... ..."), null, app.stage);//软件界面中部显示提示框_wh
		}
		else
		{
			return (("" + app.interp.arg(b, 0) + app.interp.arg(b, 1)).substr(0, 10240));
		}
	}
	
	/*Model Operator*/
	/*function "primLetterOf" */
	public function function_primLetterOf(b:*):*{
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			DialogBox.warnconfirm(Translator.map("can't support this block,please remove it"),Translator.map("letter ...of ..."), null, app.stage);//软件界面中部显示提示框_wh
		}
		else
		{
			return app.primitive.primLetterOf(b);
		}
	}
	
	/*Model Operator*/
	/*function "stringLength" */
	public function function_StringLength(b:*):*{
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			DialogBox.warnconfirm(Translator.map("can't support this block,please remove it"),Translator.map("length of ..."), null, app.stage);//软件界面中部显示提示框_wh
		}
		else
		{
			return (String(app.interp.arg(b, 0)).length);
		}
	}
	
	
	/*Model Operator*/
	/*function "%"   remainder */
	public function function_Remainder(b:*):*{
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			ArduinoMathNum++;
			app.interp.numarg(b, 0);
			ArduinoMathNum--;
			if(ArduinoReadFlag == true)
			{
				ArduinoMathStr[ArduinoMathNum] = "(" + "(" + ArduinoReadStr[0] + ") % (";
				ArduinoReadFlag = false;
			}
			else
			{
				if(ArduinoMathFlag == true)
				{
					ArduinoMathStr[ArduinoMathNum] = "(" + "(" + ArduinoMathStr[ArduinoMathNum+1] + ") % (";
					ArduinoMathFlag = false;
				}
				else
				{
					if(ArduinoValueFlag == true)
					{
						ArduinoMathStr[ArduinoMathNum] = "(" + "(" + ArduinoValueStr + ") % (";
						ArduinoValueFlag = false;
					}
					else
					{
						ArduinoMathStr[ArduinoMathNum] = "(" + "(" + app.interp.numarg(b, 0) + ") % (";
					}
				}
			}
			ArduinoMathNum++;
			app.interp.numarg(b, 1);
			ArduinoMathNum--;
			if(ArduinoReadFlag == true)
			{
				ArduinoMathStr[ArduinoMathNum] += ArduinoReadStr[0] + "))";
				ArduinoReadFlag = false;
			}
			else
			{
				if(ArduinoMathFlag == true)
				{
					ArduinoMathStr[ArduinoMathNum] += ArduinoMathStr[ArduinoMathNum+1] + "))";
					ArduinoMathFlag = false;
				}
				else
				{
					if(ArduinoValueFlag == true)
					{
						ArduinoMathStr[ArduinoMathNum] += ArduinoValueStr + "))";
						ArduinoValueFlag = false;
					}
					else
					{
						ArduinoMathStr[ArduinoMathNum] += app.interp.numarg(b, 1) + "))";
					}
				}
			}
			ArduinoMathFlag = true;
		}
		else
		{
			return app.primitive.primModulo(b);
		}
	}
	
	
	
	/*Model Operator*/
	/*function "rounded"   rounded */
	public function function_Rounded(b:*):*{
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			ArduinoMathNum++;
			app.interp.numarg(b, 0);
			ArduinoMathNum--;
			if(ArduinoReadFlag == true)
			{
				ArduinoMathStr[ArduinoMathNum] = "round(" + ArduinoReadStr[0] + ")";
				ArduinoReadFlag = false;
			}
			else
			{
				if(ArduinoMathFlag == true)
				{
					ArduinoMathStr[ArduinoMathNum] = "round(" + ArduinoMathStr[ArduinoMathNum+1] + ")";
					ArduinoMathFlag = false;
				}
				else
				{
					if(ArduinoValueFlag == true)
					{
						ArduinoMathStr[ArduinoMathNum] = "round(" + ArduinoValueStr + ")";
						ArduinoValueFlag = false;
					}
					else
					{
						ArduinoMathStr[ArduinoMathNum] = "round(" + app.interp.numarg(b, 0) + ")";
					}
				}
			}
			ArduinoMathFlag = true;
		}
		else
		{
			return Math.round(app.interp.numarg(b, 0));
		}
	}
	

	/*Model Operator*/
	/*function "createCloneOf"   createCloneOf */
	public function function_CreateCloneOf(b:*):*{
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			DialogBox.warnconfirm(Translator.map("can't support this block,please remove it"),Translator.map("create clone ..."), null, app.stage);//软件界面中部显示提示框_wh
		}
		else
		{
			app.primitive.primCreateCloneOf(b);
		}
	}
	
	
	/*Model Operator*/
	/*function "deleteClone"   deleteClone */
	public function function_DeleteClone(b:*):*{
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			DialogBox.warnconfirm(Translator.map("can't support this block,please remove it"),Translator.map("delete clone"), null, app.stage);//软件界面中部显示提示框_wh
		}
		else
			app.primitive.primDeleteClone(b);	
	}
	
	/*Model Operator*/
	/*function "abs"   abs */
	public function function_Abs(n:Number):*{
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			if(ArduinoReadFlag == true)
			{
				ArduinoMathStr[ArduinoMathNum] = "abs(" + ArduinoReadStr[0] + ")";
				ArduinoReadFlag = false;
			}
			else
			{
				if(ArduinoMathFlag == true)
				{
					ArduinoMathStr[ArduinoMathNum] = "abs(" + ArduinoMathStr[ArduinoMathNum+1] + ")";
					ArduinoMathFlag = false;
				}
				else
				{
					if(ArduinoValueFlag == true)
					{
						ArduinoMathStr[ArduinoMathNum] = "abs(" + ArduinoValueStr + ")";
						ArduinoValueFlag = false;
					}
					else
					{
						ArduinoMathStr[ArduinoMathNum] = "abs(" + n + ")";
					}
				}
			}
			ArduinoMathFlag = true; 
		}
		else{
			return Math.abs(n);
		}
	}
	
	/*Model Operator*/
	/*function "floor"   floor */
	public function function_Floor(n:Number):*{
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			if(ArduinoReadFlag == true)
			{
				ArduinoMathStr[ArduinoMathNum] = "floor(" + ArduinoReadStr[0] + ")";
				ArduinoReadFlag = false;
			}
			else
			{
				if(ArduinoMathFlag == true)
				{
					ArduinoMathStr[ArduinoMathNum] = "floor(" + ArduinoMathStr[ArduinoMathNum+1] + ")";
					ArduinoMathFlag = false;
				}
				else
				{
					if(ArduinoValueFlag == true)
					{
						ArduinoMathStr[ArduinoMathNum] = "floor(" + ArduinoValueStr + ")";
						ArduinoValueFlag = false;
					}
					else
					{
						ArduinoMathStr[ArduinoMathNum] = "floor(" + n + ")";
					}
				}
			}
			ArduinoMathFlag = true; 
		}
		else
		{
			return Math.floor(n);
		}
	}
	
	
	/*Model Operator*/
	/*function "ceiling"   ceiling */
	public function function_Ceiling(n:Number):*{
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			if(ArduinoReadFlag == true)
			{
				ArduinoMathStr[ArduinoMathNum] = "ceil(" + ArduinoReadStr[0] + ")";
				ArduinoReadFlag = false;
			}
			else
			{
				if(ArduinoMathFlag == true)
				{
					ArduinoMathStr[ArduinoMathNum] = "ceil(" + ArduinoMathStr[ArduinoMathNum+1] + ")";
					ArduinoMathFlag = false;
				}
				else
				{
					if(ArduinoValueFlag == true)
					{
						ArduinoMathStr[ArduinoMathNum] = "ceil(" + ArduinoValueStr + ")";
						ArduinoValueFlag = false;
					}
					else
					{
						ArduinoMathStr[ArduinoMathNum] = "ceil(" + n + ")";
					}
				}
			}
			ArduinoMathFlag = true; 
		}
		else
			return Math.ceil(n);
	}
	
	/*Model Operator*/
	/*function "sqrt"   sqrt */
	
	
	public function function_Sqrt(n:Number):*{
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			if(ArduinoReadFlag == true)
			{
				ArduinoMathStr[ArduinoMathNum] = "sqrt(" + ArduinoReadStr[0] + ")";
				ArduinoReadFlag = false;
			}
			else
			{
				if(ArduinoMathFlag == true)
				{
					ArduinoMathStr[ArduinoMathNum] = "sqrt(" + ArduinoMathStr[ArduinoMathNum+1] + ")";
					ArduinoMathFlag = false;
				}
				else
				{
					if(ArduinoValueFlag == true)
					{
						ArduinoMathStr[ArduinoMathNum] = "sqrt(" + ArduinoValueStr + ")";
						ArduinoValueFlag = false;
					}
					else
					{
						ArduinoMathStr[ArduinoMathNum] = "sqrt(" + n + ")";
					}
				}
			}
			ArduinoMathFlag = true; 
		}
		else
		{
			return Math.sqrt(n);
		}
	}
	/**************************************************************************************************/
	/**************************************************************************************************/
	/* Model Control*/
	/* function doIF*/
	public function functionDoIf(b:*):*{
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			ArduinoMathNum = 0;
			app.interp.arg(b, 0);
			if(ArduinoReadFlag == true)
			{
				if(ArduinoLoopFlag == true)
				{
					ArduinoLoopFs.writeUTFBytes("if(" + ArduinoReadStr[0] + ")" + " {" + '\n');
					ArduinoReadFlag = false;
				}
				else
				{
					ArduinoDoFs.writeUTFBytes("if(" + ArduinoReadStr[0] + ")" + " {" + '\n');
					ArduinoReadFlag = false;
				}
			}
			else
			{
				if(ArduinoMathFlag == true)
				{
					if(ArduinoLoopFlag == true)
					{
						ArduinoLoopFs.writeUTFBytes("if(" + ArduinoMathStr[0] + ")" + " {" + '\n');
						ArduinoMathFlag = false;
					}
					else
					{
						ArduinoDoFs.writeUTFBytes("if(" + ArduinoMathStr[0] + ")" + " {" + '\n');
						ArduinoMathFlag = false;
					}
				}
			}
			app.interp.startCmdList(b.subStack1);
			ArduinoBracketFlag ++;
		}
		else
		{
			var BF:Boolean = app.interp.arg(b, 0);
			if(app.interp.activeThread.ArduinoNA)//加有效性判断_wh
			{
				app.interp.activeThread.ArduinoNA = false;
				return;
			}
			if(BF)
				app.interp.startCmdList(b.subStack1);
		}
	}

	/* Model Control*/
	/* function wait:wait:elapsed:from:*/
	public function primWait(b:*):* {
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			ArduinoMathNum = 0;
			app.interp.numarg(b, 0);
			if(ArduinoValueFlag == true)
			{
				if(ArduinoLoopFlag == true)
					ArduinoLoopFs.writeUTFBytes("delay(" + "1000*" + ArduinoValueStr + ");" + '\n');
				else
					ArduinoDoFs.writeUTFBytes("delay(" + "1000*" + ArduinoValueStr + ");" + '\n');
				ArduinoValueFlag = false;
			}
			else
			{
				if(ArduinoMathFlag == true)
				{
					if(ArduinoLoopFlag == true)
						ArduinoLoopFs.writeUTFBytes("delay(" + "1000*" + ArduinoMathStr[0] + ");" + '\n');
					else
						ArduinoDoFs.writeUTFBytes("delay(" + "1000*" + ArduinoMathStr[0] + ");" + '\n');
					ArduinoMathFlag = false;
				}
				else
				{
					if(ArduinoReadFlag == true)
					{
						if(ArduinoLoopFlag == true)
							ArduinoLoopFs.writeUTFBytes("delay(" + "1000*" + ArduinoReadStr[0] + ");" + '\n');
						else
							ArduinoDoFs.writeUTFBytes("delay(" + "1000*" + ArduinoReadStr[0] + ");" + '\n');
						ArduinoReadFlag = false;
					}
					else
					{
						if(ArduinoLoopFlag == true)
							ArduinoLoopFs.writeUTFBytes("delay(" + "1000*" + app.interp.numarg(b, 0) + ");" + '\n');
						else
							ArduinoDoFs.writeUTFBytes("delay(" + "1000*" + app.interp.numarg(b, 0) + ");" + '\n');
					}
				}
			}
		}
		else
		{
			if (app.interp.activeThread.firstTime) {
				app.interp.startTimer(app.interp.numarg(b, 0));
				app.interp.redraw();
			} 
			else 
			{
				app.interp.checkTimer();
			}
		}
	}
	
	/* Model Control*/
	/* function doIfElse*/
	public function function_doIfElse(b:*):*{
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			ArduinoMathNum = 0;
			app.interp.arg(b, 0);
			if(ArduinoReadFlag == true)
			{
				if(ArduinoLoopFlag == true)
				{
					ArduinoLoopFs.writeUTFBytes("if(" + ArduinoReadStr[0] + ")" + " {" + '\n');
					ArduinoReadFlag = false;
				}
				else
				{
					ArduinoDoFs.writeUTFBytes("if(" + ArduinoReadStr[0] + ")" + " {" + '\n');
					ArduinoReadFlag = false;
				}
			}
			else
			{
				if(ArduinoMathFlag == true)
				{
					if(ArduinoLoopFlag == true)
					{
						ArduinoLoopFs.writeUTFBytes("if(" + ArduinoMathStr[0] + ")" + " {" + '\n');
						ArduinoMathFlag = false;
					}
					else
					{
						ArduinoDoFs.writeUTFBytes("if(" + ArduinoMathStr[0] + ")" + " {" + '\n');
						ArduinoMathFlag = false;
					}
				}
			}
			ArduinoMathNum = 0;
			ArduinoIEFlagAll ++;
			app.interp.startCmdList(b.subStack1);
			if(ArduinoIEFlagAll > (ArduinoIEFlag2+1))
				ArduinoIEFlagIE = true;
			ArduinoIfElseB[ArduinoIEFlag ++] = b.subStack2;//在stepActiveThread中处理_wh
			ArduinoIEFlag2 ++;
		}
		else
		{
			var BF:Boolean = app.interp.arg(b, 0);
			if(app.interp.activeThread.ArduinoNA)//加有效性判断_wh
			{
				app.interp.activeThread.ArduinoNA = false;
				return;
			}
			if(BF)
				app.interp.startCmdList(b.subStack1);
			else
				app.interp.startCmdList(b.subStack2);
		}
	}
	
	/* Model Control*/
	/* function doWaitUntil*/
	public function function_doWaitUntil(b:*):*{
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			ArduinoMathNum = 0;
			app.interp.arg(b, 0);
			if(ArduinoReadFlag == true)
			{
				if(ArduinoLoopFlag == true)
				{
					ArduinoLoopFs.writeUTFBytes("while(!" + ArduinoReadStr[0] + ");" + '\n');
				}
				else
				{
					ArduinoDoFs.writeUTFBytes("while(!" + ArduinoReadStr[0] + ");" + '\n');
				}
				ArduinoReadFlag = false;
			}
			else
			{
				if(ArduinoMathFlag == true)
				{
					if(ArduinoLoopFlag == true)
					{
						ArduinoLoopFs.writeUTFBytes("while(!" + ArduinoMathStr[0] + ");" + '\n');
					}
					else
					{
						ArduinoDoFs.writeUTFBytes("while(!" + ArduinoMathStr[0] + ");" + '\n');
					}
					ArduinoMathFlag = false;
				}
			}
		}
		else
		{
			var BF:Boolean = !app.interp.arg(b, 0);
			if(app.interp.activeThread.ArduinoNA)//加有效性判断_wh
			{
				app.interp.activeThread.ArduinoNA = false;
				return;
			}
			if(BF)
				app.interp.yield = true;
		}
	}
	
	
	/* Model Control*/
	/* function doUntil*/
	public function function_doUntil(b:*):*{
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			ArduinoMathNum = 0;
			app.interp.arg(b, 0);
			if(ArduinoReadFlag == true)
			{
				if(ArduinoLoopFlag == true)
				{
					ArduinoLoopFs.writeUTFBytes("while(!" + ArduinoReadStr[0] + ")" + " {" + '\n');
					ArduinoReadFlag = false;
				}
				else
				{
					ArduinoDoFs.writeUTFBytes("while(!" + ArduinoReadStr[0] + ")" + " {" + '\n');
					ArduinoReadFlag = false;
				}
			}
			else
			{
				if(ArduinoMathFlag == true)
				{
					if(ArduinoLoopFlag == true)
					{
						ArduinoLoopFs.writeUTFBytes("while(!" + ArduinoMathStr[0] + ")" + " {" + '\n');
						ArduinoMathFlag = false;
					}
					else
					{
						ArduinoDoFs.writeUTFBytes("while(!" + ArduinoMathStr[0] + ")" + " {" + '\n');
						ArduinoMathFlag = false;
					}
				}
			}
			app.interp.startCmdList(b.subStack1);
			ArduinoBracketFlag ++;
		}
		else
		{
			var BF:Boolean = !app.interp.arg(b, 0);
			if(app.interp.activeThread.ArduinoNA)//加有效性判断_wh
			{
				app.interp.activeThread.ArduinoNA = false;
				return;
			}
			if(BF)
				app.interp.startCmdList(b.subStack1, true);
		}
	}
	
	
	/* Model Control*/
	/* function stopAll*/
	public function  function_stopAll(b:*):*{
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			DialogBox.warnconfirm(Translator.map("can't support this block,please remove it"),Translator.map("stop all"), null, app.stage);//软件界面中部显示提示框_wh
		}
		else
		{
			app.runtime.stopAll(); app.interp.yield = true;
		}
	}
	
	/* Model Control*/
	/* function stopScripts*/
	public function  function_stopScripts(b:*):*{
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			DialogBox.warnconfirm(Translator.map("can't support this block,please remove it"),Translator.map("stop ..."), null, app.stage);//软件界面中部显示提示框_wh
		}
		else
			app.interp.primStop(b);
	}
	
		
	/* Model Control*/
	/* function doForever*/
	public function  function_doForever(b:*):*{
		if(ArduinoFlag == true)
		{
			ArduinoLoopFlag = true;
			app.interp.startCmdList(b.subStack1); 
		}
		else
		{
			app.interp.startCmdList(b.subStack1, true); 
		}
	}
	
	/* Model Control*/
	/* function doRepeat*/
	public function  function_doRepeat(b:*):*{
		if(ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			ArduinoMathNum = 0;
			var num:Number = app.interp.numarg(b, 0);
			if(ArduinoValueFlag == true)
			{
				if(ArduinoLoopFlag == true)
					ArduinoLoopFs.writeUTFBytes("for(int i=0;i<" + ArduinoValueStr + ";i++)" + "{" + '\n');
				else
					ArduinoDoFs.writeUTFBytes("for(int i=0;i<" + ArduinoValueStr + ";i++)" + "{" + '\n');
				ArduinoValueFlag = false;
			}
			else
			{
				if(ArduinoReadFlag == true)
				{
					if(ArduinoLoopFlag == true)
						ArduinoLoopFs.writeUTFBytes("for(int i=0;i<" + ArduinoReadStr[0] + ";i++)" + "{" + '\n');
					else
						ArduinoDoFs.writeUTFBytes("for(int i=0;i<" + ArduinoReadStr[0] + ";i++)" + "{" + '\n');
					ArduinoReadFlag = false;
				}
				else
				{
					if(ArduinoMathFlag == true)
					{
						if(ArduinoLoopFlag == true)
							ArduinoLoopFs.writeUTFBytes("for(int i=0;i<" + ArduinoMathStr[0] + ";i++)" + "{" + '\n');
						else
							ArduinoDoFs.writeUTFBytes("for(int i=0;i<" + ArduinoMathStr[0] + ";i++)" + "{" + '\n');
						ArduinoMathFlag = false;
					}
					else
					{
						if(ArduinoLoopFlag == true)
							ArduinoLoopFs.writeUTFBytes("for(int i=0;i<" + num + ";i++)" + "{" + '\n');
						else
							ArduinoDoFs.writeUTFBytes("for(int i=0;i<" + num + ";i++)" + "{" + '\n');
				}
				}
			}
			app.interp.startCmdList(b.subStack1);//代码块_wh
			ArduinoBracketFlag ++;
		}
		else
		{
			app.interp.primRepeat(b);
		}
	}
	
	
	
}}
