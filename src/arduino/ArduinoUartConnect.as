package arduino{

import flash.display.Sprite;
import flash.filesystem.FileMode;
import flash.filesystem.File;
import flash.filesystem.FileStream;

import flash.events.TimerEvent;

import flash.utils.getTimer;
import flash.utils.Timer;
import flash.utils.*;

public class ArduinoUartConnect extends Sprite{

	public  var ArduinoUartIDFileIni:File; // arduino 串口初始化设置
	public  var ArduinoUartIDFileIniFs:FileStream;
	public  var app:Scratch;
	
	
	private var checkDetectOKComHeartPackageTimer:Timer               = new Timer(4000,1);	 //留有5S钟的时间，在该时间内，检测默认的串口号是否可以接收到心跳包
	
	public var availComInComputer:Array                               = new Array();
	public var availComInComputerSoftWareStart:Array                  = new Array();
	
	/*串口在线计时器
	 * 在串口监测定时器结束前，设置这两个参数，如果串口接收到数据，则重新置 uartDetectStatustimerStop 的值，
	 * 如果uartDetectStatustimerStart 和 uartDetectStatustimerStop 两个值不等，说明串口接收到过数据，证明串口在线
	 * uartOnTickTimer: 串口在线定时器
	 */
	public var uartDetectStatustimerStart:Number                     = 0x00;
	public var uartDetectStatustimerStop:Number                      = 0x00;
	
	public var IntervalID:uint       								 = 0x00; //查询UART是否工作正常定时器的ID号，可以用于清除定时器。
	
	public function ArduinoUartConnect(app:Scratch):void{
		this.app = app;
		ArduinoUartIDFileIni = new File(File.userDirectory.resolvePath("AS-Block/ArduinoBuilder/ArduinoUartIDFile.ini").nativePath);
		ArduinoUartIDFileIniFs = new FileStream();
	}
	
	/*从默认的文件中获得上一次正常使用的COM口，该函数只有在软件启动时使用一次
	如果默认位置没有该文件，则创建该文件，并将程序中默认的串口号放置在该文件中
	*/
	public function readDefaultComIDFromFile():int{
		ArduinoUartIDFileIniFs.open(ArduinoUartIDFileIni,FileMode.UPDATE); //
		ArduinoUartIDFileIniFs.position = 0;
		
		try
		{
			app.arduinoUart.scratchComID = ArduinoUartIDFileIniFs.readInt();
		}

		catch (EOFError){
			ArduinoUartIDFileIniFs.writeInt(app.arduinoUart.scratchComID);	//如果默认地址没有该文件，则生成该文件，并在该文件中写入默认的串口ID号
			return app.arduinoUart.scratchComID;
		}	
		return app.arduinoUart.scratchComID;
	}
	
	/*
	将此次找到的可以正常使用的COM端口存储到文件当中
	*/
	public function writeComIDToFile():void{
		ArduinoUartIDFileIniFs.open(ArduinoUartIDFileIni,FileMode.UPDATE);
		ArduinoUartIDFileIniFs.writeInt(app.arduinoUart.scratchComID);
		ArduinoUartIDFileIniFs.close();
	}
	
	/************************************************************
	串口LED灯显示功能
	开启一个0.5s间隔的定时器，用于LED灯显示
	************************************************************/
	public  var uartStateLightTimer:Timer = new Timer(500,0);    //串口状态显示灯，0.5S钟动一次，直到检测到可用串口或关闭串口
	private var UartStateLightCount:int   = 0x00;	
	
	public function setuartStateLightTimer():void{							//Timer 设置
		uartStateLightTimer.addEventListener(TimerEvent.TIMER,onTickUartStateLightTimer);
		uartStateLightTimer.start();
	}
	
	private function onTickUartStateLightTimer(event:TimerEvent):void{		//流水灯显示
		app.uartConnectCirSetFlow(UartStateLightCount%3);
		UartStateLightCount ++;	
	}
	
	public function resetUartStateLightState():void{						//串口LED灯时钟停止
		uartStateLightTimer.stop();
		UartStateLightCount = 0x00;
		app.xuhy_test_log(" resetUartStateLightState ");
	}
	
	/*
	功能描述：软件开启时读取了一次可用串口，点击auto connect后读取了一次可用串口
	该函数用于判定两次读取的串口号的区别，不同的串口号为可用串口
	*/
	public function findComIDArrayChange(availComInmanualChooseComIDNewComputer:Array,availComInComputerSoftWareStart:Array):int{
		var i:int = 0x00;
		if(availComInComputer.length != availComInComputerSoftWareStart.length)			//串口有变化
		{		
			for(i;i<= availComInComputer.length;i++)
			{
				if(availComInComputer[i] != availComInComputerSoftWareStart[i])
				{
					app.arduinoUart.scratchComID = availComInComputer[i];
					return app.arduinoUart.scratchComID;
				}
			}	
		}
		return 0x00;
	}
	
	/*	
	串口检测，输出扫描到的所有有效串口号
	有效串口号可能有几个，比如在电脑上插入了串口调试助手等，所以还需要检测是否通讯成功。
	*/	
	public function checkUartAvail(scratchComID:int):Boolean
	{	
		if(app.arduinoUart.arduinoUartOpen(scratchComID)){
			app.arduinoUart.arduinoUart.addEventListener("socketData", app.arduinoUart.fncArduinoData);		
			return true;
		}
		else
		{
			return false;
		}
	}
	
	/*
	*状态栏中按钮和灯的显示状态
	*/
	public function ShowUartStatusFlag(flag:Boolean):void{
		if(flag){											//串口已正常连接
			writeComIDToFile();								//将检测到的串口号写入文件
			resetUartStateLightState();						//关闭LED灯的时钟
			app.uartConnectCirSet(1);						//串口LED灯为绿
			app.uartAutoConnectButton.setLabel("ShowUartStatusFlag COM:" + app.arduinoUart.scratchComID);
			comStatus = 0x00;
		}
		else{
			app.arduinoUart.arduinoUartClose();					//串口关闭
			app.uartConnectCirSet(0);							//串口还没有连上
			app.uartAutoConnectButton.setLabel("Auto Connect"); //TopBar的按键变为Auto Connect
		}
	}
	
	/*
	 * 串口状态轮询时钟，每1S轮询一次
	*/
	public function setAutoConnect():uint
	{
		var intervalDuration:Number = 1000;    
		IntervalID = setInterval(onTick_searchAndCheckUart, intervalDuration);
		uartDetectStatustimerStop = uartDetectStatustimerStart = 0x00;
		app.xuhy_test_log("setAutoConnect COM：" + app.arduinoUart.scratchComID);
		return IntervalID;
	}
	
	/*
	//检查心跳包 用来判定串口在正常工作
	*/
	public  var  comStatus:int              = 0x03;  					//com口的工作状态 0x00:连接正常 0x01:意外断开 0x02断开com口
	private var  notConnectArduinoCount:int = 0x00;
	public function onTick_searchAndCheckUart():void					//检测心跳包
	{	
		if (uartDetectStatustimerStop != uartDetectStatustimerStart)
		{
			comStatus = 0x00;
			notConnectArduinoCount = 0x00;
			app.arduinoUart.uartBusyStatus = app.arduinoUart.free;
			setFindAvailComIDForArduinoSuccess();
			app.xuhy_test_log("onTick_searchAndCheckUart com is --OK--");
		}
		else
		{
			notConnectArduinoCount ++ ;
			if(notConnectArduinoCount >= 5)
			{	
				comStatus = 0x01;
				app.xuhy_test_log("uart disconnect unexpected comStatus = " + comStatus);
				
				AutofindAvailComIDForArduinoFailed();
				setUartDisconnect();
			}
		}
		uartDetectStatustimerStop = uartDetectStatustimerStart = getTimer();
	}
	
	/*
	 * 断开UART连接
	 * */
	public function setUartDisconnect():void
	{		
		app.arduinoUart.arduinoUartClose();
		comStatus = 0x02;   
		notConnectArduinoCount = 0x00;
		clearInterval(IntervalID);
		app.xuhy_test_log("Uart Disconnect");
		ShowUartStatusFlag(false);
	}
	
	


	/*
	 *检查电脑中所有存在的UART接口 
	  返回UART接口的数组
	*/
	public  var comStatusTrueArray:Array = new Array();
	public function findComStatusTrue():Array
	{
		comStatusTrueArray.splice(0);
		for (var i:int = 1; i <= 32;i++)//暂时设定只有32个com口，为com1 到 com32
		{
			if (app.arduinoUart.arduinoUartOpen(i))
			{
				comStatusTrueArray.push(i);
			}
			app.arduinoUart.arduinoUartClose();
		}
		return comStatusTrueArray;
	}
	
	/********************************************************************************
	检测是否可以直接连接串口号为ComID的串口，自动检测是否有相关的串口可以得到心跳包
	*********************************************************************************/
	private var checkScratchCanGetHeartPackageFromArduinoTimer:Timer  = new Timer(4000,1);	 //留有5S钟的时间，在该时间内，检测默认的串口号是否可以接收到心跳包
	public function checkScratchCanGetHeartPackageFromArduino(ComID:int):Boolean{
		if(checkUartAvail(ComID))
		{
			setAutoConnect();										//开始计时获得串口心跳包的时钟，如果再一定时间内没有获得数据，则执行COMPLETE的程序							
			checkScratchCanGetHeartPackageFromArduinoTimer.addEventListener(TimerEvent.TIMER_COMPLETE,checkScratchCanGetHeartPackageFromArduinoTimerOver);
			checkScratchCanGetHeartPackageFromArduinoTimer.start();
			return true;
		}
		else
		{
			return false;
		}	
	}
	
	
	private function checkScratchCanGetHeartPackageFromArduinoTimerOver(event:TimerEvent):void{
		app.xuhy_test_log("checkDefaultScratchComIDCanGetHeartPackageTimer time is done");	
		clearInterval(IntervalID);									//关闭检测心跳包的Timer;
		setUartDisconnect();										//时间到了 没有侦测到可用串口，则关闭已打开的串口
		findAvailComIDForArduinoStatus ++; 							//进入下一步骤
		findAvailComIDForArduinoTimerIDOccupy = false;
	}
	
	/***************************************************************************
	可用的串口号已经找到，但是没有接收到心跳包，则说明没有固件，需要下载固件
	***************************************************************************/
	private function checkDetectOKComHeartPackageOver(event:TimerEvent):void{
		app.xuhy_test_log("得到正确的串口，但没有得到心跳包，没有固件，需要重新下载固件");
		clearInterval(IntervalID); 						//关闭串口状态轮寻时钟
		setUartDisconnect();							
		app.arduinoLib.dofirm();						//上传固件	
	}
	
	/**********************************************************
	找到专门给Arduino使用的串口
	1) 鉴定从文件中读取的COM口是否可以使用
	2) 对比软件开启时读到的电脑中所有的COM口与 点击Auto Connect按键后的COM是否一致，如果不一致则找出不一致的口作为Arduino的串口
	3) 如果2 中得到的串口
	3) 如果步骤2中的串口数和串口号一致，并且串口数<=3 ,则对各个串口下载固件，检测串口是否为Arduino串口。
	4) 如果步骤3 种的串口数 >=3,则手动选择串口
	**********************************************************/
	private var findAvailComIDForArduinoTimerID:int          = 0x00;
	public var findAvailComIDForArduinoTimerIDOccupy:Boolean = false;

	public function findAvailComIDForArduinoTimer():void{
		var intervalDuration:Number = 500; 
		setuartStateLightTimer();					//状态灯开始闪烁
		availComInComputer = findComStatusTrue();	//点击Auto Connect后 查询下现有的COM 口
		findAvailComIDForArduinoStatus = findAvailComIDForArduinoStatus_ScratchComIDFormFile; 
		findAvailComIDForArduinoTimerID = setInterval(findAvailComIDForArduino, intervalDuration);
		
	} 
	
	/*查找到 供Arduino 使用的串口，做如下清理工作*/
	/*
	
	*/
	public function setFindAvailComIDForArduinoSuccess():void{
		app.xuhy_test_log("findAvailComIDForArduino" + "找到COM口 COM"+app.arduinoUart.scratchComID+" 可用,结束查询");
		ShowUartStatusFlag(true);
		app.uartAutoConnectButton.setLabel("COM" + app.arduinoUart.scratchComID);		//3) topbarmenu 显示可用串口字符
		clearInterval(findAvailComIDForArduinoTimerID);									//4) 查询时钟关闭
		checkScratchCanGetHeartPackageFromArduinoTimer.stop();
		checkDetectOKComHeartPackageTimer.stop();
		findAvailComIDForArduinoTimerIDOccupy = false;	
		findAvailComIDForArduinoStatus = 0x00;
		app.uartDialog.cancel();
		dotCount = 0x00;
		dot = '.';
	}
	
	/*
	串口检测失败做的处理
	*/
	public function AutofindAvailComIDForArduinoFailed():void{
		clearInterval(findAvailComIDForArduinoTimerID);
		ShowUartStatusFlag(false);
		findAvailComIDForArduinoTimerIDOccupy = false;
		clearInterval(IntervalID);
		resetUartStateLightState();
		comStatus = 0x03;
		app.arduinoLib.upDialogSuccessFlag = false;
		app.xuhy_test_log("AutofindAvailComIDForArduinoFailed");
		dotCount = 0x00;
		dot = '.';
	}
	
	private var    findAvailComIDForArduinoStatus:int                                                             = 0x00;
	private const  findAvailComIDForArduinoStatus_ScratchComIDFormFile:int                                        = 0x01;
	private const  findAvailComIDForArduinoStatus_CompareComIDBetweenComIDComputerSoftWareStartAndAutoConnect:int = 0x02;
	private const  findAvailComIDForArduinoStatus_CimIDLengthSameDoFirm:int                                       = 0x03;
	private const  findAvailComIDForArduinoStatus_ManualChooseComID:int                                           = 0x04;
	
	public function findAvailComIDForArduino():void{	
		if(app.arduinoLib.upDialogSuccessFlag || (comStatus == 0x00)){				//下载固件成功，串口已经找到 或者 得到心跳包
			setFindAvailComIDForArduinoSuccess();
			return  ;			
		}
		if(findAvailComIDForArduinoTimerIDOccupy)
		{
			return ;
		}
	
		switch(findAvailComIDForArduinoStatus)
		{
			case findAvailComIDForArduinoStatus_ScratchComIDFormFile:
				findAvailComIDForArduinoTimerIDOccupy = true;		
				app.arduinoUart.scratchComID = readDefaultComIDFromFile();	//从文件中获得可以使用的串口
				app.xuhy_test_log("findAvailComIDForArduino" + " 阶段1：测试从文件中读到的串口 COM "+app.arduinoUart.scratchComID);
				if(checkScratchCanGetHeartPackageFromArduino(app.arduinoUart.scratchComID) == false)
				{
					findAvailComIDForArduinoTimerIDOccupy = false;
					findAvailComIDForArduinoStatus = findAvailComIDForArduinoStatus_CompareComIDBetweenComIDComputerSoftWareStartAndAutoConnect;
				}
				break;
			case findAvailComIDForArduinoStatus_CompareComIDBetweenComIDComputerSoftWareStartAndAutoConnect:
				app.xuhy_test_log("findAvailComIDForArduino" + "阶段2：测试两次读到的串口号是否有不一致");
				app.arduinoUart.scratchComID = findComIDArrayChange(availComInComputer,availComInComputerSoftWareStart);
				if(app.arduinoUart.scratchComID != 0x00){							//得到不一样的串口号						
					findAvailComIDForArduinoTimerIDOccupy = true;
					checkUartAvail(app.arduinoUart.scratchComID);					//连接串口取心跳包
					setAutoConnect();												
					checkDetectOKComHeartPackageTimer.addEventListener(TimerEvent.TIMER_COMPLETE,checkDetectOKComHeartPackageOver);
					checkDetectOKComHeartPackageTimer.start();	
				}
				else
				{													//两种串口一致
					if(availComInComputer.length <= 0x02){			//如果串口端口号的数量小于2，对每个串口下载固件
						findAvailComIDForArduinoStatus = findAvailComIDForArduinoStatus_CimIDLengthSameDoFirm;
					}
					else
					{
						manualChooseComID();
						
					}
					findAvailComIDForArduinoTimerIDOccupy = false;	
				}
				break;
			case findAvailComIDForArduinoStatus_CimIDLengthSameDoFirm:	//下载固件
				app.xuhy_test_log("findAvailComIDForArduino" + "阶段3：两次读到的串口一致，且串口数量小于3，则对每个串口下载固件");
				findAvailComIDForArduinoTimerIDOccupy = true;
				app.arduinoUart.scratchComID = availComInComputer[0];
				if(availComInComputer.length >= 0x01)
				{
					app.xuhy_test_log("findAvailComIDForArduino download firmware "+availComInComputer.length + " times");
					availComInComputer.shift();
					app.arduinoLib.dofirm();							//下载固件
				}
				else{
					manualChooseComID();				//自动检测串口没有得到可用串口号
					app.xuhy_test_log("findAvailComIDForArduino download firmware failed");
				}
				break;
			default:
				break;
		}
	}
	
	
	/*************************************************************
	手动连接COM口
	通过提示框显示自动连接失败
	*************************************************************/
	
	public var manualChooseComIDTimerID:int     = 0x00;
	private var manualChooseComIDOld:Array   = new Array();
	private var manualChooseComIDNew:Array       = new Array();
	public function manualChooseComID():void{
		var intervalDuration:Number = 1000; 
		manualChooseComIDTimerID = setInterval(manualChooseComIDDetect, intervalDuration);
		AutofindAvailComIDForArduinoFailed();					//串口数量大于3个，则自动检测串口流程失败
		setuartStateLightTimer();								//开启串口LED灯
		app.uartDialog.setText ("系统实时检测中 .");
		app.uartDialog.showOnStage(app.stage);
		manualChooseComIDNew = manualChooseComIDOld = availComInComputerSoftWareStart;
	}

	private var dotCount:int = 0x00;
	private var dot:String = '.';
	public function manualChooseComIDDetect():void{

		manualChooseComIDOld = manualChooseComIDNew.slice(0);
		manualChooseComIDNew = findComStatusTrue().slice(0);
		dotCount++;
		dot = dot + '.';
		if(dotCount > 0x0a)
		{
			dotCount = 0x00;
			dot = '.';
		}
		app.uartDialog.setText ("系统实时检测中 ."+dot);
		app.uartDialog.showOnStage(app.stage);
		
		if(manualChooseComIDNew.length > manualChooseComIDOld.length)
		{
			app.arduinoUart.scratchComID = findComIDArrayChange(manualChooseComIDNew,manualChooseComIDOld);
			if(app.arduinoUart.scratchComID != 0x00) 				//找到了不同的COM 口
			{
				app.xuhy_test_log("manualChooseComIDDetect find avail COM:"+ app.arduinoUart.scratchComID);
				app.uartDialog.setText ("检测到可用串口 COM"+app.arduinoUart.scratchComID);
				app.uartDialog.showOnStage(app.stage);
				clearInterval(manualChooseComIDTimerID);            			//关闭时钟
				checkUartAvail(app.arduinoUart.scratchComID);					//连接串口取心跳包
				setAutoConnect();												
				checkDetectOKComHeartPackageTimer.addEventListener(TimerEvent.TIMER_COMPLETE,checkDetectOKComHeartPackageOver);
				checkDetectOKComHeartPackageTimer.start();
			}
		}
		else
		{
			
		}
	}
	
}}