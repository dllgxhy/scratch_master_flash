package arduino
{

import flash.display.Sprite;	
import flash.utils.Timer;
import flash.events.TimerEvent;
import flash.utils.*;

	public class ArduinoUartConnectManual extends Sprite
	{
		public var app:Scratch;
		public var showCOMFlag:Boolean = false;	//COM口正在连接_wh

		
		public function ArduinoUartConnectManual(app:Scratch)
		{
			this.app = app;
		}
		
		public function comOpen1():void {
			app.arduinoUart.uartOpenTrue = true;//COM口开启标志量赋值
			app.arduinoUart.scratchComID = 1;
			app.arduinoUart.arduinoUartOpen(app.arduinoUart.scratchComID);
			app.uartConnectCirSet(1);
		}
		public function comOpen2():void {
			app.arduinoUart.uartOpenTrue = true;//COM口开启标志量赋值
			app.arduinoUart.scratchComID = 2;
			app.arduinoUart.arduinoUartOpen(app.arduinoUart.scratchComID);
			app.uartConnectCirSet(1);
		}
		public function comOpen3():void {
			app.arduinoUart.uartOpenTrue = true;//COM口开启标志量赋值
			app.arduinoUart.scratchComID = 3;
			app.arduinoUart.arduinoUartOpen(app.arduinoUart.scratchComID);
			app.uartConnectCirSet(1);
		}
		public function comOpen4():void {
			app.arduinoUart.uartOpenTrue = true;//COM口开启标志量赋值
			app.arduinoUart.scratchComID = 4;
			app.arduinoUart.arduinoUartOpen(app.arduinoUart.scratchComID);
			app.uartConnectCirSet(1);
		}
		public function comOpen5():void {
			app.arduinoUart.uartOpenTrue = true;//COM口开启标志量赋值
			app.arduinoUart.scratchComID = 5;
			app.arduinoUart.arduinoUartOpen(app.arduinoUart.scratchComID);
			app.uartConnectCirSet(1);
		}
		public function comOpen6():void {
			app.arduinoUart.uartOpenTrue = true;//COM口开启标志量赋值
			app.arduinoUart.scratchComID = 6;
			app.arduinoUart.arduinoUartOpen(app.arduinoUart.scratchComID);
			app.uartConnectCirSet(1);
		}
		public function comOpen7():void {
			app.arduinoUart.uartOpenTrue = true;//COM口开启标志量赋值
			app.arduinoUart.scratchComID = 7;
			app.arduinoUart.arduinoUartOpen(app.arduinoUart.scratchComID);
			app.uartConnectCirSet(1);
		}
		public function comOpen8():void {
			app.arduinoUart.uartOpenTrue = true;//COM口开启标志量赋值
			app.arduinoUart.scratchComID = 8;
			app.arduinoUart.arduinoUartOpen(app.arduinoUart.scratchComID);
			app.uartConnectCirSet(1);
		}
		public function comOpen9():void {
			app.arduinoUart.uartOpenTrue = true;//COM口开启标志量赋值
			app.arduinoUart.scratchComID = 9;
			app.arduinoUart.arduinoUartOpen(app.arduinoUart.scratchComID);
			app.uartConnectCirSet(1);
		}
		public function comOpen10():void {
			app.arduinoUart.uartOpenTrue = true;//COM口开启标志量赋值
			app.arduinoUart.scratchComID = 10;
			app.arduinoUart.arduinoUartOpen(app.arduinoUart.scratchComID);
			app.uartConnectCirSet(1);
		}
		public function comOpen11():void {
			app.arduinoUart.uartOpenTrue = true;//COM口开启标志量赋值
			app.arduinoUart.scratchComID = 11;
			app.arduinoUart.arduinoUartOpen(app.arduinoUart.scratchComID);
			app.uartConnectCirSet(1);
		}
		public function comOpen12():void {
			app.arduinoUart.uartOpenTrue = true;//COM口开启标志量赋值
			app.arduinoUart.scratchComID = 12;
			app.arduinoUart.arduinoUartOpen(app.arduinoUart.scratchComID);
			app.uartConnectCirSet(1);
		}
		public function comOpen13():void {
			app.arduinoUart.uartOpenTrue = true;//COM口开启标志量赋值
			app.arduinoUart.scratchComID = 13;
			app.arduinoUart.arduinoUartOpen(app.arduinoUart.scratchComID);
			app.uartConnectCirSet(1);
		}
		public function comOpen14():void {
			app.arduinoUart.uartOpenTrue = true;//COM口开启标志量赋值
			app.arduinoUart.scratchComID = 14;
			app.arduinoUart.arduinoUartOpen(app.arduinoUart.scratchComID);
			app.uartConnectCirSet(1);
		}
		public function comOpen15():void {
			app.arduinoUart.uartOpenTrue = true;//COM口开启标志量赋值
			app.arduinoUart.scratchComID = 15;
			app.arduinoUart.arduinoUartOpen(app.arduinoUart.scratchComID);
			app.uartConnectCirSet(1);
		}
		public function comOpen16():void {
			app.arduinoUart.uartOpenTrue = true;//COM口开启标志量赋值
			app.arduinoUart.scratchComID = 16;
			app.arduinoUart.arduinoUartOpen(app.arduinoUart.scratchComID);
			app.uartConnectCirSet(1);
		}	
		public function comOpen17():void {
			app.arduinoUart.uartOpenTrue = true;//COM口开启标志量赋值
			app.arduinoUart.scratchComID = 17;
			app.arduinoUart.arduinoUartOpen(app.arduinoUart.scratchComID);
			app.uartConnectCirSet(1);
		}
		public function comOpen18():void {
			app.arduinoUart.uartOpenTrue = true;//COM口开启标志量赋值
			app.arduinoUart.scratchComID = 18;
			app.arduinoUart.arduinoUartOpen(app.arduinoUart.scratchComID);
			app.uartConnectCirSet(1);
		}
		public function comOpen19():void {
			app.arduinoUart.uartOpenTrue = true;//COM口开启标志量赋值
			app.arduinoUart.scratchComID = 19;
			app.arduinoUart.arduinoUartOpen(app.arduinoUart.scratchComID);
			app.uartConnectCirSet(1);
		}
		public function comOpen20():void {
			app.arduinoUart.uartOpenTrue = true;//COM口开启标志量赋值
			app.arduinoUart.scratchComID = 20;
			app.arduinoUart.arduinoUartOpen(app.arduinoUart.scratchComID);
			app.uartConnectCirSet(1);
		}
		public function comOpen21():void {
			app.arduinoUart.uartOpenTrue = true;//COM口开启标志量赋值
			app.arduinoUart.scratchComID = 21;
			app.arduinoUart.arduinoUartOpen(app.arduinoUart.scratchComID);
			app.uartConnectCirSet(1);
		}
		public function comOpen22():void {
			app.arduinoUart.uartOpenTrue = true;//COM口开启标志量赋值
			app.arduinoUart.scratchComID = 22;
			app.arduinoUart.arduinoUartOpen(app.arduinoUart.scratchComID);
			app.uartConnectCirSet(1);
		}
		
		/************************************************************
		如果USB接口断开,则LED灯显示红灯,该部分代码暂时屏蔽
		************************************************************/
		private var CheckManualUartConnectStatusTimerID:int          = 0x00;
		public function CreateCheckManualUartConnectStatusTimer():void
		{
			var intervalDuration:Number = 1000; 
			CheckManualUartConnectStatusTimerID = setInterval(On_tickCheckManualUartConnectStatus, intervalDuration);
		}
		
		//此处连续对串口进行关闭连接操作，对软件整体性能产生
		private function On_tickCheckManualUartConnectStatus():void{			
			app.arduinoUart.arduinoUartClose();
			if(app.arduinoUart.arduinoUartOpen(app.arduinoUart.scratchComID) == false){
				app.xuhy_test_log("On_tickCheckManualUartConnectStatus false");
				app.uartConnectCirSet(0);
				clearInterval(CheckManualUartConnectStatusTimerID);
			}
			else{
				app.xuhy_test_log("On_tickCheckManualUartConnectStatus true");
				
			}
		}
	}
}