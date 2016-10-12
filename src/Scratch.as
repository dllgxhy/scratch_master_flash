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

// Scratch.as
// John Maloney, September 2009
//
// This is the top-level application.

package {
import com.adobe.utils.StringUtil;

import flash.desktop.NativeApplication;
import flash.desktop.NativeProcess;
import flash.desktop.NativeProcessStartupInfo;
import flash.display.DisplayObject;
import flash.display.Graphics;
import flash.display.Shape;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageDisplayState;
import flash.display.StageScaleMode;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.SecurityErrorEvent;
import flash.events.UncaughtErrorEvent;
import flash.external.ExternalInterface;
import flash.filesystem.File;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.net.FileFilter;
import flash.net.FileReference;
import flash.net.FileReferenceList;
import flash.net.LocalConnection;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.system.Capabilities;
import flash.system.System;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.utils.ByteArray;
import flash.utils.getTimer;
import flash.utils.setInterval;
import flash.utils.*;

import flash.filesystem.FileMode;

import mx.utils.URLUtil;

import arduino.ArduinoLibrary;
import arduino.ArduinoUart;

import blocks.Block;

import extensions.ExtensionManager;

import interpreter.Interpreter;

import logging.Log;
import logging.LogEntry;
import logging.LogLevel;

import render3d.DisplayObjectContainerIn3D;

import scratch.BlockMenus;
import scratch.PaletteBuilder;
import scratch.ReadyLabel;
import scratch.ScratchCostume;
import scratch.ScratchObj;
import scratch.ScratchRuntime;
import scratch.ScratchSound;
import scratch.ScratchSprite;
import scratch.ScratchStage;

import svgeditor.tools.SVGTool;

import translation.Translator;

import ui.BlockPalette;
import ui.CameraDialog;
import ui.LoadProgress;
import ui.media.MediaInfo;
import ui.media.MediaLibrary;
import ui.media.MediaPane;
import ui.parts.ImagesPart;
import ui.parts.LibraryPart;
import ui.parts.ScriptsPart;
import ui.parts.SoundsPart;
import ui.parts.StagePart;
import ui.parts.TabsPart;
import ui.parts.TopBarPart;

import uiwidgets.BlockColorEditor;
import uiwidgets.CursorTool;
import uiwidgets.DialogBox;
import uiwidgets.IconButton;
import uiwidgets.Menu;
import uiwidgets.ScriptsPane;

import util.Base64Encoder;
import util.GestureHandler;
import util.ProjectIO;
import util.Server;
import util.Transition;

import watchers.ListWatcher;
import uiwidgets.Button;
import primitives.Primitives;

import arduino.ArduinoUartConnect;

public class Scratch extends Sprite {
	// Version
	public static const versionString:String = 'v446';
	public static var app:Scratch; // static reference to the app, used for debugging

	// Display modes
	public var hostProtocol:String = 'http';
	public var editMode:Boolean; // true when project editor showing, false when only the player is showing
	public var isOffline:Boolean; // true when running as an offline (i.e. stand-alone) app
	public var isSmallPlayer:Boolean; // true when displaying as a scaled-down player (e.g. in search results)
	public var stageIsContracted:Boolean; // true when the stage is half size to give more space on small screens
	public var isIn3D:Boolean;
	public var render3D:DisplayObjectContainerIn3D;
	public var isArmCPU:Boolean;
	public var jsEnabled:Boolean = false; // true when the SWF can talk to the webpage
	public var ignoreResize:Boolean = false; // If true, temporarily ignore resize events.
	public var isExtensionDevMode:Boolean = false; // If true, run in extension development mode (as on ScratchX)
	public var isMicroworld:Boolean = false;

	public var presentationScale:Number;
	
	// Runtime
	public var runtime:ScratchRuntime;
	public var interp:Interpreter;
	public var extensionManager:ExtensionManager;
	public var server:Server;
	public var gh:GestureHandler;
	public var projectID:String = '';
	public var projectOwner:String = '';
	public var projectIsPrivate:Boolean;
	public var oldWebsiteURL:String = '';
	public var loadInProgress:Boolean;
	public var debugOps:Boolean = false;
	public var debugOpCmd:String = '';

	protected var autostart:Boolean;
	private var viewedObject:ScratchObj;
	private var lastTab:String = 'scripts';
	protected var wasEdited:Boolean; // true if the project was edited and autosaved
	private var _usesUserNameBlock:Boolean = false;
	protected var languageChanged:Boolean; // set when language changed

	// UI Elements
	public var playerBG:Shape;
	public var palette:BlockPalette;
	public var scriptsPane:ScriptsPane;
	public var stagePane:ScratchStage;
	public var mediaLibrary:MediaLibrary;
	public var lp:LoadProgress;
	public var cameraDialog:CameraDialog;
	
	public var ComWorkID_Text:TextField = new TextField();
	public var ComWorkID_TextType:TextFormat = new TextFormat();

	// UI Parts
	public var libraryPart:LibraryPart;
	protected var topBarPart:TopBarPart;
	protected var stagePart:StagePart;
	private var tabsPart:TabsPart;
	protected var scriptsPart:ScriptsPart;
	public var imagesPart:ImagesPart;
	public var soundsPart:SoundsPart;
	public const tipsBarClosedWidth:int = 17;
	

	public var logger:Log = new Log(16);
	
	//UART Part
	public var arduinoUart:ArduinoUart                   = new ArduinoUart(this);
	public var arduinoLib:ArduinoLibrary                 = new ArduinoLibrary(this);
	public var arduinoUartConnect:ArduinoUartConnect     = new ArduinoUartConnect(this);
	public var showCOMFlag:Boolean                       = false;
	public var uartDialog:DialogBox                      = new DialogBox();
	public var uartConnectCir:Shape                      = new Shape();			//通信标志圆
	public var uartAutoConnectButton:Button              = new Button(Translator.map("Auto Connect"),uartAutoConnectButtonDown);
	
	public var OS:String                    = new String;
	public var closeOK:Boolean              = false;//是否可以关闭软件_wh
	public var closeWait:Boolean            = false;//等待文件保存完成情况_wh
	public var ArduinoWarnFlag:Boolean      = false;
	public var blueFlag:Boolean             = false;
	
	public var primitive:Primitives = new Primitives(this,interp);		//新生成primitive的对象_xuhy
	
	
	
	public function Scratch() {
		SVGTool.setStage(stage);
		loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, uncaughtErrorHandler);
		app = this;
		
		// This one must finish before most other queries can start, so do it separately
		determineJSAccess();
		initialDll();
		showComStatusDialog();
		arduinoUartConnect.availComInComputerSoftWareStart = app.arduinoUartConnect.findComStatusTrue().slice(0);	//开机检测目前电脑中所有的COM口
		xuhy_test_log("availComInComputerSoftWareStart COM:" + arduinoUartConnect.availComInComputerSoftWareStart);
	}
	/*编写代码过程中的调试log，因trace占用时间较多，后续可直接对其关闭*/
	public function xuhy_test_log(s:String):void
	{
		trace("xuhy test log :" + s);
	}
	
	public var dllOk:Number = 10;
	private function initialDll():void {
		//将dll文件放在系统目录下_wh
		var OS32:Boolean = Capabilities.supports32BitProcesses;//是否支持64位机_wh
		var OS64:Boolean = Capabilities.supports64BitProcesses;//是否为64位机_wh
		OS = Capabilities.os;//操作系统_wh
		var OS32str:String = "C:/Windows/System32/";
		var OS64str:String = "C:/Windows/SysWOW64/";
		var file2:File;
		var file3:File;
		try
		{
			file3= new File(File.applicationDirectory.resolvePath("avrtool/pthreadVC2.dll").nativePath);//_wh
			if(OS64)
				file2= new File(File.applicationDirectory.resolvePath(OS64str+"pthreadVC2.dll").nativePath);//_wh
			else
				file2= new File(File.applicationDirectory.resolvePath(OS32str+"pthreadVC2.dll").nativePath);//_wh
			if(file2.exists)
			{
				dllOk ++;
				file3.copyTo(file2,true);
			}
			else
			{
				file3.copyTo(file2,true);
				dllOk ++;
			}
		}
		catch(Error)
		{
			;
		}
		try
		{
			file3= new File(File.applicationDirectory.resolvePath("avrtool/msvcr100d.dll").nativePath);//_wh
			if(OS64)
				file2= new File(File.applicationDirectory.resolvePath(OS64str+"msvcr100d.dll").nativePath);//_wh
			else
				file2= new File(File.applicationDirectory.resolvePath(OS32str+"msvcr100d.dll").nativePath);//_wh
			if(file2.exists)
			{
				dllOk ++;
				file3.copyTo(file2,true);
			}
			else
			{
				file3.copyTo(file2,true);
				dllOk ++;
			}
		}
		catch(Error)
		{
			;
		}
	}
	

	
	protected function determineJSAccess():void {
		if (externalInterfaceAvailable()) {
			try {
				externalCall('function(){return true;}', jsAccessDetermined);
				return; // wait for callback
			}
			catch (e:Error) {
			}
		}
		jsAccessDetermined(false);
	}

	private function jsAccessDetermined(result:Boolean):void {
		jsEnabled = result;
		initialize();
	}
	
	public function comWorkIDShowInTopBar(comID:int):void
	{
		ComWorkID_Text.text = "COM" + comID;
	}
	
	public function comWorkIDTextTypeSet():void
	{
		ComWorkID_TextType.font = "黑体";
		ComWorkID_Text.textColor = 0xffffff;
		ComWorkID_Text.width = 200;
		ComWorkID_Text.height = 50;
		ComWorkID_Text.x = 370;
		ComWorkID_Text.y = 5;
		addChild(ComWorkID_Text);
	}
	

	protected function initialize():void {
		isOffline = !URLUtil.isHttpURL(loaderInfo.url);
		hostProtocol = URLUtil.getProtocol(loaderInfo.url);

//		isExtensionDevMode = (loaderInfo.parameters['extensionDevMode'] == 'true');
//		isMicroworld = (loaderInfo.parameters['microworldMode'] == 'true');

		checkFlashVersion();
		initServer();

		stage.align = StageAlign.TOP_LEFT;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.frameRate = 30;
		stage.stageWidth = 1100;//增加软件窗口初始化设置
		stage.stageHeight = 640;//增加软件窗口初始化设置

		if (stage.hasOwnProperty('color')) {
			// Stage doesn't have a color property on Air 2.6, and Linux throws if you try to set it anyway.
			stage['color'] = CSS.backgroundColor();
		}

		Block.setFonts(10, 9, true, 0); // default font sizes
		Block.MenuHandlerFunction = BlockMenus.BlockMenuHandler;
		CursorTool.init(this);
		app = this;

		stagePane = getScratchStage();
		gh = new GestureHandler(this, (loaderInfo.parameters['inIE'] == 'true'));
		initInterpreter();
		initRuntime();
		initExtensionManager();
		Translator.initializeLanguageList();

		playerBG = new Shape(); // create, but don't add
		addParts();
		
		libraryPart.initSprite(0);//add by xuhy,此处为后加，增加了调取图库的内容

		server.getSelectedLang(Translator.setLanguageValue);


		stage.addEventListener(MouseEvent.MOUSE_DOWN, gh.mouseDown);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, gh.mouseMove);
		stage.addEventListener(MouseEvent.MOUSE_UP, gh.mouseUp);
		stage.addEventListener(MouseEvent.MOUSE_WHEEL, gh.mouseWheel);
		stage.addEventListener('rightClick', gh.rightMouseClick);

		stage.addEventListener(KeyboardEvent.KEY_UP, runtime.keyUp);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown); // to handle escape key
		stage.addEventListener(Event.ENTER_FRAME, step);
		stage.addEventListener(Event.RESIZE, onResize);

		stage.nativeWindow.addEventListener(Event.CLOSING,closingHandler);//关闭按钮触发事件
		
		setEditMode(startInEditMode());

		// install project before calling fixLayout()
		if (editMode) runtime.installNewProject();
		else runtime.installEmptyProject();

		fixLayout();
		//Analyze.collectAssets(0, 119110);
		//Analyze.checkProjects(56086, 64220);
		//Analyze.countMissingAssets();
		uartConnectCirSet(0);
		AdduartAutoConnectButton();
		handleStartupParameters();
	}
	
	protected function handleStartupParameters():void {
		setupExternalInterface(false);
		jsEditorReady();
	}

	protected function setupExternalInterface(oldWebsitePlayer:Boolean):void {
		if (!jsEnabled) return;

		addExternalCallback('ASloadExtension', extensionManager.loadRawExtension);
		addExternalCallback('ASextensionCallDone', extensionManager.callCompleted);
		addExternalCallback('ASextensionReporterDone', extensionManager.reporterCompleted);
		addExternalCallback('AScreateNewProject', createNewProjectScratchX);

		if (isExtensionDevMode) {
			addExternalCallback('ASloadGithubURL', loadGithubURL);
			addExternalCallback('ASloadBase64SBX', loadBase64SBX);
			addExternalCallback('ASsetModalOverlay', setModalOverlay);
		}
	}
	
	//增加模块帮助的对话框
	public function showTip(tipName:String):void {
		switch(tipName)
		{
			case "readtrack:":DialogBox.blockhelp("read track sensor",Translator.map("Pin ") + "A1/A2", null, app.stage);break;
			case "readavoid:":DialogBox.blockhelp("read avoid obstacle sensor",Translator.map("Pin ") + "12/13", null, app.stage);break;
			case "readpower:":DialogBox.blockhelp("read power sensor",Translator.map("Pin ") + "A5", null, app.stage);break;
			case "setforward:":DialogBox.blockhelp("set forward speed as %n",Translator.map("Pin ") + "5/7/6/8", null, app.stage);break;
			case "setback:":DialogBox.blockhelp("set back speed as %n",Translator.map("Pin ") + "5/7/6/8", null, app.stage);break;
			case "setleft:":DialogBox.blockhelp("set left speed as %n",Translator.map("Pin ") + "5/7/6/8", null, app.stage);break;
			case "setright:":DialogBox.blockhelp("set right speed as %n",Translator.map("Pin ") + "5/7/6/8", null, app.stage);break;
			case "setarm:":DialogBox.blockhelp("set arm %m.arm angle as %n",Translator.map("Pin ") + "9/10", null, app.stage);break;
			case "readcksound":DialogBox.blockhelp("sound",Translator.map("Pin ") + "A3\n" + Translator.map("Range ") + "0-100", null, app.stage);break;
			case "readckslide":DialogBox.blockhelp("slide",Translator.map("Pin ") + "A4\n" + Translator.map("Range ") + "0-100", null, app.stage);break;
			case "readcklight":DialogBox.blockhelp("light",Translator.map("Pin ") + "A5\n" + Translator.map("Range ") + "0-100", null, app.stage);break;
			case "readckkey1":DialogBox.blockhelp("red key",Translator.map("Pin ") + "2", null, app.stage);break;
			case "readckkey2":DialogBox.blockhelp("green key",Translator.map("Pin ") + "3", null, app.stage);break;
			case "readckjoyx":DialogBox.blockhelp("joystick X",Translator.map("Pin ") + "A1\n" + Translator.map("Range ") + "-100-100", null, app.stage);break;
			case "readckjoyy":DialogBox.blockhelp("joystick Y",Translator.map("Pin ") + "A2\n" + Translator.map("Range ") + "-100-100", null, app.stage);break;
			case "setckled:":DialogBox.blockhelp("set LED as %m.onoff",Translator.map("Pin ") + "13", null, app.stage);break;
			case "setrgb:":DialogBox.blockhelp("set colors LED as R %n G %n B %n",Translator.map("Pin ") + "9/10/11", null, app.stage);break;
//			case "setlcd1602string:":DialogBox.blockhelp("set lcd1602 as %s,Translator.map("Pin ") + "9/10/11", null, app.stage);break;
			default:break;
		}
	}
	

	protected function jsEditorReady():void {
		if (jsEnabled) {
			externalCall('JSeditorReady', function (success:Boolean):void {
				if (!success) jsThrowError('Calling JSeditorReady() failed.');
			});
		}
	}

	private function loadSingleGithubURL(url:String):void {
		url = StringUtil.trim(unescape(url));

		function handleComplete(e:Event):void {
			runtime.installProjectFromData(sbxLoader.data);
			if (StringUtil.trim(projectName()).length == 0) {
				var newProjectName:String = url;
				var index:int = newProjectName.indexOf('?');
				if (index > 0) newProjectName = newProjectName.slice(0, index);
				index = newProjectName.lastIndexOf('/');
				if (index > 0) newProjectName = newProjectName.substr(index + 1);
				index = newProjectName.lastIndexOf('.sbx');
				if (index > 0) newProjectName = newProjectName.slice(0, index);
				setProjectName(newProjectName);
			}
		}

		function handleError(e:ErrorEvent):void {
			jsThrowError('Failed to load SBX: ' + e.toString());
		}

		var fileExtension:String = url.substr(url.lastIndexOf('.')).toLowerCase();
		if (fileExtension == '.js') {
			externalCall('ScratchExtensions.loadExternalJS', null, url);
			return;
		}

		// Otherwise assume it's a project (SB2, SBX, etc.)
		loadInProgress = true;
		var request:URLRequest = new URLRequest(url);
		var sbxLoader:URLLoader = new URLLoader(request);
		sbxLoader.dataFormat = URLLoaderDataFormat.BINARY;
		sbxLoader.addEventListener(Event.COMPLETE, handleComplete);
		sbxLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleError);
		sbxLoader.addEventListener(IOErrorEvent.IO_ERROR, handleError);
		sbxLoader.load(request);
	}

	private var pendingExtensionURLs:Array;
	private function loadGithubURL(urlOrArray:*):void {
		if (!isExtensionDevMode) return;

		var url:String;
		var urlArray:Array = urlOrArray as Array;
		if (urlArray) {
			var urlCount:int = urlArray.length;
			var extensionURLs:Array = [];
			var projectURL:String;
			var index:int;

			// Filter URLs: allow at most one project file, and wait until it loads before loading extensions.
			for (index = 0; index < urlCount; ++index) {
				url = StringUtil.trim(unescape(urlArray[index]));
				if (StringUtil.endsWith(url.toLowerCase(), '.js')) {
					extensionURLs.push(url);
				}
				else if (url.length > 0) {
					if (projectURL) {
						jsThrowError("Ignoring extra project URL: " + projectURL);
					}
					projectURL = StringUtil.trim(url);
				}
			}
			if (projectURL) {
				pendingExtensionURLs = extensionURLs;
				loadSingleGithubURL(projectURL);
				// warning will be shown later
			}
			else {
				urlCount = extensionURLs.length;
				for (index = 0; index < urlCount; ++index) {
					loadSingleGithubURL(extensionURLs[index]);
				}
				externalCall('JSshowWarning');
			}
		}
		else {
			url = urlOrArray as String;
			loadSingleGithubURL(url);
			externalCall('JSshowWarning');
		}
	}

	private function loadBase64SBX(base64:String):void {
		var sbxData:ByteArray = Base64Encoder.decode(base64);
		app.setProjectName('');
		runtime.installProjectFromData(sbxData);
	}

	
	
	//关闭按钮触发事件处理函数_wh
	protected function closingHandler(e:Event):void
	{
		var winClosingEvent:Event; 
		winClosingEvent = new Event(Event.CLOSING,false,true); 
		NativeApplication.nativeApplication.dispatchEvent(winClosingEvent); 
		e.preventDefault();//终止关闭进程，需要先提示保存工程_wh
		
		DialogBox.saveconfirm(Translator.map("Save project?"), app.stage, savePro, nosavePro);//软件界面中部显示提示框_wh
	}
	
	//保存工程
	protected function savePro():void
	{
		exportProjectToFile();
		closeWait = true;
	}
	
	//不保存工程
	protected function nosavePro():void
	{
		closeOK = true;
	}
	

	
	
	protected function initTopBarPart():void {
		topBarPart = new TopBarPart(this);
	}

	protected function initScriptsPart():void {
		scriptsPart = new ScriptsPart(this);
	}

	protected function initImagesPart():void {
		imagesPart = new ImagesPart(this);
	}

	protected function initInterpreter():void {
		interp = new Interpreter(this);
	}

	protected function initRuntime():void {
		runtime = new ScratchRuntime(this, interp);
	}

	protected function initExtensionManager():void {
//		if (isExtensionDevMode) {
//			extensionManager = new ExtensionDevManager(this);
//		}
//		else {
			extensionManager = new ExtensionManager(this);
//		}
	}

	protected function initServer():void {
		server = new Server();
	}

	public function closeTips():void {
	}

	public function reopenTips():void {
	}

	public function tipsWidth():int {
		return 0;
	}

	protected function startInEditMode():Boolean {
		return isOffline || isExtensionDevMode;
	}

	public function getMediaLibrary(type:String, whenDone:Function):MediaLibrary {
		return new MediaLibrary(this, type, whenDone);
	}

	public function getMediaPane(app:Scratch, type:String):MediaPane {
		return new MediaPane(app, type);
	}

	public function getScratchStage():ScratchStage {
		return new ScratchStage();
	}

	public function getPaletteBuilder():PaletteBuilder {
		return new PaletteBuilder(this);
	}

	private function uncaughtErrorHandler(event:UncaughtErrorEvent):void {
		if (event.error is Error) {
			var error:Error = event.error as Error;
			logException(error);
		}
		else if (event.error is ErrorEvent) {
			var errorEvent:ErrorEvent = event.error as ErrorEvent;
			log(LogLevel.ERROR, errorEvent.toString());
		}
	}

	// All other log...() methods funnel to this one
	public function log(severity:String, messageKey:String, extraData:Object = null):LogEntry {
		return logger.log(severity, messageKey, extraData);
	}

	// Log an Error object generated by an exception
	public function logException(e:Error):void {
		log(LogLevel.ERROR, e.toString());
	}

	// Shorthand for log(LogLevel.ERROR, ...)
	public function logMessage(msg:String, extra_data:Object = null):void {
		log(LogLevel.ERROR, msg, extra_data);
	}

	public function loadProjectFailed():void {
		loadInProgress = false;
	}

	public function jsThrowError(s:String):void {
		// Throw the given string as an error in the browser. Errors on the production site are logged.
		var errorString:String = 'SWF Error: ' + s;
		log(LogLevel.WARNING, errorString);
		if (jsEnabled) {
			externalCall('JSthrowError', null, errorString);
		}
	}

	protected function checkFlashVersion():void {
		/*SCRATCH::allow3d */{
			if (Capabilities.playerType != "Desktop" || Capabilities.version.indexOf('IOS') === 0) {
				var versionString:String = Capabilities.version.substr(Capabilities.version.indexOf(' ') + 1);
				var versionParts:Array = versionString.split(',');
				var majorVersion:int = parseInt(versionParts[0]);
				var minorVersion:int = parseInt(versionParts[1]);
				if ((majorVersion > 11 || (majorVersion == 11 && minorVersion >= 7)) && !isArmCPU && Capabilities.cpuArchitecture == 'x86') {
					render3D = new DisplayObjectContainerIn3D();
					render3D.setStatusCallback(handleRenderCallback);
					return;
				}
			}
		}

		render3D = null;
	}

	/*SCRATCH::allow3d*/
	protected function handleRenderCallback(enabled:Boolean):void {
		if (!enabled) {
			go2D();
			render3D = null;
		}
		else {
			for (var i:int = 0; i < stagePane.numChildren; ++i) {
				var spr:ScratchSprite = (stagePane.getChildAt(i) as ScratchSprite);
				if (spr) {
					spr.clearCachedBitmap();
					spr.updateCostume();
					spr.applyFilters();
				}
			}
			stagePane.clearCachedBitmap();
			stagePane.updateCostume();
			stagePane.applyFilters();
		}
	}

	public function clearCachedBitmaps():void {
		for (var i:int = 0; i < stagePane.numChildren; ++i) {
			var spr:ScratchSprite = (stagePane.getChildAt(i) as ScratchSprite);
			if (spr) spr.clearCachedBitmap();
		}
		stagePane.clearCachedBitmap();

		// unsupported technique that seems to force garbage collection
		try {
			new LocalConnection().connect('foo');
			new LocalConnection().connect('foo');
		} catch (e:Error) {
		}
	}

	/*SCRATCH::allow3d*/
	public function go3D():void {
		if (!render3D || isIn3D) return;

		var i:int = stagePart.getChildIndex(stagePane);
		stagePart.removeChild(stagePane);
		render3D.setStage(stagePane, stagePane.penLayer);
		stagePart.addChildAt(stagePane, i);
		isIn3D = true;
	}

	/*SCRATCH::allow3d*/
	public function go2D():void {
		if (!render3D || !isIn3D) return;

		var i:int = stagePart.getChildIndex(stagePane);
		stagePart.removeChild(stagePane);
		render3D.setStage(null, null);
		stagePart.addChildAt(stagePane, i);
		isIn3D = false;
		for (i = 0; i < stagePane.numChildren; ++i) {
			var spr:ScratchSprite = (stagePane.getChildAt(i) as ScratchSprite);
			if (spr) {
				spr.clearCachedBitmap();
				spr.updateCostume();
				spr.applyFilters();
			}
		}
		stagePane.clearCachedBitmap();
		stagePane.updateCostume();
		stagePane.applyFilters();
	}

	private var debugRect:Shape;

	public function showDebugRect(r:Rectangle):void {
		// Used during debugging...
		var p:Point = stagePane.localToGlobal(new Point(0, 0));
		if (!debugRect) debugRect = new Shape();
		var g:Graphics = debugRect.graphics;
		g.clear();
		if (r) {
			g.lineStyle(2, 0xFFFF00);
			g.drawRect(p.x + r.x, p.y + r.y, r.width, r.height);
			addChild(debugRect);
		}
	}

	public function strings():Array {
		return [
			'a copy of the project file on your computer.',
			'Project not saved!', 'Save now', 'Not saved; project did not load.',
			'Save project?', 'Don\'t save',
			'Save now', 'Saved',
			'Revert', 'Undo Revert', 'Reverting...',
			'Throw away all changes since opening this project?',
		];
	}

	public function viewedObj():ScratchObj {
		return viewedObject;
	}

	public function stageObj():ScratchStage {
		return stagePane;
	}

	public function projectName():String {
		return stagePart.projectName();
	}

	public function highlightSprites(sprites:Array):void {
		libraryPart.highlight(sprites);
	}

	public function refreshImageTab(fromEditor:Boolean):void {
		imagesPart.refresh(fromEditor);
	}

	public function refreshSoundTab():void {
		soundsPart.refresh();
	}

	public function selectCostume():void {
		imagesPart.selectCostume();
	}

	public function selectSound(snd:ScratchSound):void {
		soundsPart.selectSound(snd);
	}

	public function clearTool():void {
		CursorTool.setTool(null);
		topBarPart.clearToolButtons();
	}

	public function tabsRight():int {
		return tabsPart.x + tabsPart.w;
	}

	public function enableEditorTools(flag:Boolean):void {
		imagesPart.editor.enableTools(flag);
	}

	public function get usesUserNameBlock():Boolean {
		return _usesUserNameBlock;
	}

	public function set usesUserNameBlock(value:Boolean):void {
		_usesUserNameBlock = value;
		stagePart.refresh();
	}

	public function updatePalette(clearCaches:Boolean = true):void {
		// Note: updatePalette() is called after changing variable, list, or procedure
		// definitions, so this is a convenient place to clear the interpreter's caches.
		if (isShowing(scriptsPart)) scriptsPart.updatePalette();
		if (clearCaches) runtime.clearAllCaches();
	}

	public function setProjectName(s:String):void {
		if (s.slice(-3) == '.sb') s = s.slice(0, -3);
		if (s.slice(-4) == '.sb2') s = s.slice(0, -4);
		stagePart.setProjectName(s);
	}

	protected var wasEditing:Boolean;

	public function setPresentationMode(enterPresentation:Boolean):void {
		if (enterPresentation) {
			wasEditing = editMode;
			if (wasEditing) {
				setEditMode(false);
				if (jsEnabled) externalCall('tip_bar_api.hide');
			}
		} else {
			if (wasEditing) {
				setEditMode(true);
				if (jsEnabled) externalCall('tip_bar_api.show');
			}
		}
		if (isOffline) {
			stage.displayState = enterPresentation ? StageDisplayState.FULL_SCREEN_INTERACTIVE : StageDisplayState.NORMAL;
		}
		for each (var o:ScratchObj in stagePane.allObjects()) o.applyFilters();

		if (lp) fixLoadProgressLayout();
		stagePane.updateCostume();
		/*SCRATCH::allow3d*/ {
			if (isIn3D) render3D.onStageResize();
		}
	}

	private function keyDown(evt:KeyboardEvent):void {
		// Escape stops drag operations
		if (!evt.shiftKey && evt.charCode == 27) {
			gh.escKeyDown();
		}
		// Escape exists presentation mode.
		else if ((evt.charCode == 27) && stagePart.isInPresentationMode()) {
			setPresentationMode(false);
			stagePart.exitPresentationMode();
		}
		// Handle enter key
//		else if(evt.keyCode == 13 && !stage.focus) {
//			stagePart.playButtonPressed(null);
//			evt.preventDefault();
//			evt.stopImmediatePropagation();
//		}
		// Handle ctrl-m and toggle 2d/3d mode
		else if (evt.ctrlKey && evt.charCode == 109) {
			SCRATCH::allow3d {
				isIn3D ? go2D() : go3D();
			}
			evt.preventDefault();
			evt.stopImmediatePropagation();
		}
		else {
			runtime.keyDown(evt);
		}
	}

	private function setSmallStageMode(flag:Boolean):void {
		stageIsContracted = flag;
		stagePart.updateRecordingTools();
		fixLayout();
		libraryPart.refresh();
		tabsPart.refresh();
		stagePane.applyFilters();
		stagePane.updateCostume();
	}

	public function projectLoaded():void {
		removeLoadProgressBox();
		System.gc();
		if (autostart) runtime.startGreenFlags(true);
		loadInProgress = false;
		saveNeeded = false;

		// translate the blocks of the newly loaded project
		for each (var o:ScratchObj in stagePane.allObjects()) {
			o.updateScriptsAfterTranslation();
		}

		if (jsEnabled && isExtensionDevMode) {
			if (pendingExtensionURLs) {
				loadGithubURL(pendingExtensionURLs);
				pendingExtensionURLs = null;
			}
			externalCall('JSprojectLoaded');
		}
	}

	public function resetPlugin(whenDone:Function):void {
		if (jsEnabled) {
			externalCall('ScratchExtensions.resetPlugin');
		}
		if (whenDone != null) {
			whenDone();
		}
	}

	protected function step(e:Event):void {
		// Step the runtime system and all UI components.
		gh.step();
		runtime.stepRuntime();
		Transition.step(null);
		stagePart.step();
		libraryPart.step();
		scriptsPart.step();
		imagesPart.step();
		if(closeOK == true)
		{
			app.arduinoUartConnect.setUartDisconnect();
			stage.nativeWindow.close();
		}
	}

	public function updateSpriteLibrary(sortByIndex:Boolean = false):void {
		libraryPart.refresh()
	}

	public function updateTopBar():void {
		topBarPart.refresh();
	}

	public function threadStarted():void {
		stagePart.threadStarted()
	}

	public function selectSprite(obj:ScratchObj):void {
		if (isShowing(imagesPart)) imagesPart.editor.shutdown();
		if (isShowing(soundsPart)) soundsPart.editor.shutdown();
		viewedObject = obj;
		libraryPart.refresh();
		tabsPart.refresh();
		if (isShowing(imagesPart)) {
			imagesPart.refresh();
		}
		if (isShowing(soundsPart)) {
			soundsPart.currentIndex = 0;
			soundsPart.refresh();
		}
		if (isShowing(scriptsPart)) {
			scriptsPart.updatePalette();
			scriptsPane.viewScriptsFor(obj);
			scriptsPart.updateSpriteWatermark();
		}
	}

	public function setTab(tabName:String):void {
		if (isShowing(imagesPart)) imagesPart.editor.shutdown();
		if (isShowing(soundsPart)) soundsPart.editor.shutdown();
		hide(scriptsPart);
		hide(imagesPart);
		hide(soundsPart);
		if (!editMode) return;
		if (tabName == 'images') {
			show(imagesPart);
			imagesPart.refresh();
		} else if (tabName == 'sounds') {
			soundsPart.refresh();
			show(soundsPart);
		} else if (tabName && (tabName.length > 0)) {
			tabName = 'scripts';
			scriptsPart.updatePalette();
			scriptsPane.viewScriptsFor(viewedObject);
			scriptsPart.updateSpriteWatermark();
			show(scriptsPart);
		}
		show(tabsPart);
		show(stagePart); // put stage in front
		tabsPart.selectTab(tabName);
		lastTab = tabName;
		if (saveNeeded) setSaveNeeded(true); // save project when switching tabs, if needed (but NOT while loading!)
	}

	public function installStage(newStage:ScratchStage):void {
		var showGreenflagOverlay:Boolean = shouldShowGreenFlag();
		stagePart.installStage(newStage, showGreenflagOverlay);
		selectSprite(newStage);
		libraryPart.refresh();
		setTab('scripts');
		scriptsPart.resetCategory();
		wasEdited = false;
	}

	protected function shouldShowGreenFlag():Boolean {
		return !(autostart || editMode);
	}

	protected function addParts():void {
		initTopBarPart();
		stagePart = getStagePart();
		libraryPart = getLibraryPart();
		tabsPart = new TabsPart(this);
		initScriptsPart();
		initImagesPart();
		soundsPart = new SoundsPart(this);
		addChild(topBarPart);
		addChild(stagePart);
		addChild(libraryPart);
		addChild(tabsPart);
	}

	protected function getStagePart():StagePart {
		return new StagePart(this);
	}

	protected function getLibraryPart():LibraryPart {
		return new LibraryPart(this);
	}

	public function fixExtensionURL(javascriptURL:String):String {
		return javascriptURL;
	}

	// -----------------------------
	// UI Modes and Resizing
	//------------------------------

	public function setEditMode(newMode:Boolean):void {
		Menu.removeMenusFrom(stage);
		editMode = newMode;
		if (editMode) {
			interp.showAllRunFeedback();
			hide(playerBG);
			show(topBarPart);
			show(libraryPart);
			show(tabsPart);
			setTab(lastTab);
			stagePart.hidePlayButton();
			runtime.edgeTriggersEnabled = true;
		} else {
			addChildAt(playerBG, 0); // behind everything
			playerBG.visible = false;
			hide(topBarPart);
			hide(libraryPart);
			hide(tabsPart);
			setTab(null); // hides scripts, images, and sounds
		}
		stagePane.updateListWatchers();
		show(stagePart); // put stage in front
		fixLayout();
		stagePart.refresh();
	}

	protected function hide(obj:DisplayObject):void {
		if (obj.parent) obj.parent.removeChild(obj)
	}

	protected function show(obj:DisplayObject):void {
		addChild(obj)
	}

	protected function isShowing(obj:DisplayObject):Boolean {
		return obj.parent != null
	}

	public function onResize(e:Event):void {
		if (!ignoreResize) fixLayout();
	}

	public function fixLayout():void {
		var w:int = stage.stageWidth;
		var h:int = stage.stageHeight - 1; // fix to show bottom border...

		w = Math.ceil(w / scaleX);
		h = Math.ceil(h / scaleY);

		updateLayout(w, h);
	}
	
	public function updateRecordingTools(t:Number):void {
		stagePart.updateRecordingTools(t);
	}
	
	public function removeRecordingTools():void {
		stagePart.removeRecordingTools();
	}
	
	public function refreshStagePart():void {
		stagePart.refresh();
	}

	protected function updateLayout(w:int, h:int):void {
		if (!isMicroworld) {
			topBarPart.x = 0;
			topBarPart.y = 0;
			topBarPart.setWidthHeight(w, 28);
		}

		var extraW:int = 2;
		var extraH:int = stagePart.computeTopBarHeight() + 1;
		if (editMode) {
			// adjust for global scale (from browser zoom)

			if (stageIsContracted) {
				stagePart.setWidthHeight(240 + extraW, 180 + extraH, 0.5);
			} else {
				stagePart.setWidthHeight(480 + extraW, 360 + extraH, 1);
			}
			stagePart.x = 5;
			stagePart.y = isMicroworld ? 5 : topBarPart.bottom() + 5;
			fixLoadProgressLayout();
		} else {
			drawBG();
			var pad:int = (w > 550) ? 16 : 0; // add padding for full-screen mode
			var scale:Number = Math.min((w - extraW - pad) / 480, (h - extraH - pad) / 360);
			scale = Math.max(0.01, scale);
			var scaledW:int = Math.floor((scale * 480) / 4) * 4; // round down to a multiple of 4
			scale = scaledW / 480;
			presentationScale = scale;
			var playerW:Number = (scale * 480) + extraW;
			var playerH:Number = (scale * 360) + extraH;
			stagePart.setWidthHeight(playerW, playerH, scale);
			stagePart.x = int((w - playerW) / 2);
			stagePart.y = int((h - playerH) / 2);
			fixLoadProgressLayout();
			return;
		}
		libraryPart.x = stagePart.x;
		libraryPart.y = stagePart.bottom() + 18;
		libraryPart.setWidthHeight(stagePart.w, h - libraryPart.y);

		tabsPart.x = stagePart.right() + 5;
		if (!isMicroworld) {
			tabsPart.y = topBarPart.bottom() + 5;
			tabsPart.fixLayout();
		}
		else
			tabsPart.visible = false;

		// the content area shows the part associated with the currently selected tab:
		var contentY:int = tabsPart.y + 27;
		if (!isMicroworld)
			w -= tipsWidth();
		updateContentArea(tabsPart.x, contentY, w - tabsPart.x - 6, h - contentY - 5, h);
	}

	protected function updateContentArea(contentX:int, contentY:int, contentW:int, contentH:int, fullH:int):void {
		imagesPart.x = soundsPart.x = scriptsPart.x = contentX;
		imagesPart.y = soundsPart.y = scriptsPart.y = contentY;
		imagesPart.setWidthHeight(contentW, contentH);
		soundsPart.setWidthHeight(contentW, contentH);
		scriptsPart.setWidthHeight(contentW, contentH);

		if (mediaLibrary) mediaLibrary.setWidthHeight(topBarPart.w, fullH);
		if (frameRateGraph) {
			frameRateGraph.y = stage.stageHeight - frameRateGraphH;
			addChild(frameRateGraph); // put in front
		}

		/*SCRATCH::allow3d*/ {
			if (isIn3D) render3D.onStageResize();
		}
	}

	private function drawBG():void {
		var g:Graphics = playerBG.graphics;
		g.clear();
		g.beginFill(0);
		g.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
	}

	private var modalOverlay:Sprite;

	public function setModalOverlay(enableOverlay:Boolean):void {
		var currentlyEnabled:Boolean = !!modalOverlay;
		if (enableOverlay != currentlyEnabled) {
			if (enableOverlay) {
				function eatEvent(event:MouseEvent):void {
					event.stopImmediatePropagation();
					event.stopPropagation();
				}

				modalOverlay = new Sprite();
				modalOverlay.graphics.beginFill(CSS.backgroundColor_ScratchX, 0.8);
				modalOverlay.graphics.drawRect(0, 0, stage.width, stage.height);
				modalOverlay.addEventListener(MouseEvent.CLICK, eatEvent);
				modalOverlay.addEventListener(MouseEvent.MOUSE_DOWN, eatEvent);
				if (SCRATCH::allow3d) { // TODO: use a better flag or rename this one
					// These events are only available in flash 11.2 and above.
					modalOverlay.addEventListener(MouseEvent.RIGHT_CLICK, eatEvent);
					modalOverlay.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, eatEvent);
					modalOverlay.addEventListener(MouseEvent.MIDDLE_CLICK, eatEvent);
					modalOverlay.addEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, eatEvent);
				}
				stage.addChild(modalOverlay);
			}
			else {
				stage.removeChild(modalOverlay);
				modalOverlay = null;
			}
		}
	}

	public function logoButtonPressed(b:IconButton):void {
		if (isExtensionDevMode) {
			externalCall('showPage', null, 'home');
		}
	}

	// -----------------------------
	// Translations utilities
	//------------------------------

	public function translationChanged():void {
		// The translation has changed. Fix scripts and update the UI.
		// directionChanged is true if the writing direction (e.g. left-to-right) has changed.
		for each (var o:ScratchObj in stagePane.allObjects()) {
			o.updateScriptsAfterTranslation();
		}
		var uiLayer:Sprite = app.stagePane.getUILayer();
		for (var i:int = 0; i < uiLayer.numChildren; ++i) {
			var lw:ListWatcher = uiLayer.getChildAt(i) as ListWatcher;
			if (lw) lw.updateTranslation();
		}
		topBarPart.updateTranslation();
		stagePart.updateTranslation();
		libraryPart.updateTranslation();
		tabsPart.updateTranslation();
		updatePalette(false);
		imagesPart.updateTranslation();
		soundsPart.updateTranslation();
	}

	// -----------------------------
	// Menus
	//------------------------------
	public function showFileMenu(b:*):void {
		var m:Menu = new Menu(null, 'File', CSS.topBarColor(), 28);
		m.addItem('New', createNewProject);
		m.addLine();

		// Derived class will handle this
		addFileMenuItems(b, m);

		m.showOnStage(stage, b.x, topBarPart.bottom() - 1);
	}
	
	public function stopVideo(b:*):void {
		runtime.stopVideo();
	}

	protected function addFileMenuItems(b:*, m:Menu):void {
		m.addItem('Load Project', runtime.selectProjectFile);
		m.addItem('Save Project', exportProjectToFile);
		if (runtime.recording || runtime.ready==ReadyLabel.COUNTDOWN || runtime.ready==ReadyLabel.READY) {
			m.addItem('Stop Video', runtime.stopVideo);
		} else {
			m.addItem('Record Project Video', runtime.exportToVideo);
		}
		if (canUndoRevert()) {
			m.addLine();
			m.addItem('Undo Revert', undoRevert);
		} else if (canRevert()) {
			m.addLine();
			m.addItem('Revert', revertToOriginalProject);
		}

		if (b.lastEvent.shiftKey) {
			m.addLine();
			m.addItem('Save Project Summary', saveSummary);
			m.addItem('Show version details', showVersionDetails);
		}
		if (b.lastEvent.shiftKey && jsEnabled) {
			m.addLine();
			m.addItem('Import experimental extension', function ():void {
				function loadJSExtension(dialog:DialogBox):void {
					var url:String = dialog.getField('URL').replace(/^\s+|\s+$/g, '');
					if (url.length == 0) return;
					externalCall('ScratchExtensions.loadExternalJS', null, url);
				}

				var d:DialogBox = new DialogBox(loadJSExtension);
				d.addTitle('Load Javascript Scratch Extension');
				d.addField('URL', 120);
				d.addAcceptCancelButtons('Load');
				d.showOnStage(app.stage);
			});
		}
	}

	public function showEditMenu(b:*):void {
		var m:Menu = new Menu(null, 'More', CSS.topBarColor(), 28);
		m.addItem('Undelete', runtime.undelete, runtime.canUndelete());
		m.addLine();
		m.addItem('Small stage layout', toggleSmallStage, true, stageIsContracted);
		m.addItem('Turbo mode', toggleTurboMode, true, interp.turboMode);
		addEditMenuItems(b, m);
		var p:Point = b.localToGlobal(new Point(0, 0));
		m.showOnStage(stage, b.x, topBarPart.bottom() - 1);
	}

	protected function addEditMenuItems(b:*, m:Menu):void {
		m.addLine();
		m.addItem('Edit block colors', editBlockColors);
	}
	
	/*
	以下内容由xuhy编辑
	 
	*/
	
	public function showComStatusDialog():void
	{
		uartDialog.addTitle("自动连接失败，请将硬件设备连接断开并重新连接");
		uartDialog.addText ("please plugout the cable");
//		uartDialog.addButton("放弃",     uartDialogOK);
		uartDialog.addButton("放弃",   uartDialogCancel);
	}

	
	/*
	//当uartAutoConnectButton 按键按下后，进行如下操作
	1) 检测是否可以直接连接串口号为scratchComID(默认的)的串口，自动检测是否有相关的串口可以得到心跳包// checkDefaultScratchComIDCanGetHeartPackage()
	2) 如果scratchComID 的串口连接不上，则通过插拔USB接口检测哪个COM口可用，得到scratchComID。  //checkArduinoCableIsPlugIn
	3) 如果新得到的scratchComID  可得到心跳包，则该com口可用，  且arduino板子上有固件
	4) 如果新得到的scratchComID  无法得到心跳包，则该COM口可用，只是arduino的板子上没有固件。
	*/
	public function uartAutoConnectButtonDown():void{
		var UartIDFromFile:int = 0x00;
		if(app.arduinoUartConnect.comStatus != 0x00)					//在串口没有连接上的状态时，按下Auto Connect的按键，则开始侦测可用串口
		{
			arduinoUartConnect.findAvailComIDForArduinoTimer();
		}
		else{															//串口可以正常通讯状态下，按下Auto Connect的按键，则关闭串口通讯	
			arduinoUartConnect.AutofindAvailComIDForArduinoFailed();
			xuhy_test_log("Scratch" + "arduinoUart.comStatus = " + app.arduinoUartConnect.comStatus);
		}	
	}
	
	public function uartDialogCancel():void
	{
		arduinoUartConnect.AutofindAvailComIDForArduinoFailed();
		clearInterval(arduinoUartConnect.manualChooseComIDTimerID);
		uartConnectCirSet(0);
		uartDialog.cancel();
	}
	/*
	public function uartDialogOK():void{  								//提醒用户重新插拔USB接口或下载固件
		uartDialog.
	}*/
		
	public function showCOMMenu(b:*):void {
		var m:Menu = new Menu(null, 'COM', CSS.topBarColor(), 28);
	
		if (arduinoUartConnect.comStatus != 0x00)
		{
			m.addItem("Auto Connect", arduinoUartConnect.setAutoConnect);
			app.xuhy_test_log("topbar show Auto Connect");
		}
		else
		{
			m.addItem("COM" + arduinoUart.scratchComID, arduinoUartConnect.setUartDisconnect, true, true);
			app.xuhy_test_log("topbar show COMID");
		}
		
		//蓝牙通信模式_wh
		if(blueFlag == false)
			m.addItem("Bluetooth", BlueOpen);
		else
			m.addItem("Bluetooth", BlueClose, true, true);
		
		m.addLine();
		
		m.addItem("Firmware", arduinoLib.dofirm);//固件更新_wh
		m.addLine();
		m.addItem("Drive", arduinoLib.dodrive);//固件更新_wh
		m.addLine();
		
		m.showOnStage(stage, b.x, topBarPart.bottom() - 1);
		/*
		if(UDFlag == false)
		{
			UDFlag = true;
			//上传固件等待文本框_wh
			UpDialog.addTitle('Upload');
			UpDialog.addButton('Close',cancel);
			UpDialog.addText(Translator.map("uploading") + " ... ");
		}
		
		showCOMFlag = false;*/
	}
	
	protected function BlueOpen():void {
		blueFlag = true;
	}
	
	protected function BlueClose():void {
		blueFlag = false;
	}
	
	/*
	设置UART通讯状态显示
	//@para state：状态灯的显示状态：0：无串口可用红灯显示 1：串口正常工作 绿灯显示 2：寻找可用串口绿灯闪烁
	*/
	public function uartConnectCirSet(state:Number):void
	{
		//通信正常标志_wh
		if(state == 1)
		{
			uartConnectCir.graphics.beginFill(0x80ff00);				//绿灯
			uartConnectCir.graphics.drawCircle(TopBarPart.UartAutoConnectX + 110,15,8);
			uartConnectCir.graphics.drawCircle(TopBarPart.UartAutoConnectX + 130,15,8);
			uartConnectCir.graphics.drawCircle(TopBarPart.UartAutoConnectX + 150,15,8);
			uartConnectCir.graphics.endFill();
			addChild(uartConnectCir);
		}
		else if(state == 0)
		{
			
			uartConnectCir.graphics.beginFill(0xff8060);				//红灯
			uartConnectCir.graphics.drawCircle(TopBarPart.UartAutoConnectX + 110,15,8);
			uartConnectCir.graphics.drawCircle(TopBarPart.UartAutoConnectX + 130,15,8);
			uartConnectCir.graphics.drawCircle(TopBarPart.UartAutoConnectX + 150,15,8);
			uartConnectCir.graphics.endFill();
			addChild(uartConnectCir);
		}
		else if(state == 2)
		{
			uartConnectCir.graphics.beginFill(0xE0E000);
			uartConnectCir.graphics.drawCircle(TopBarPart.UartAutoConnectX + 110,15,8);
			uartConnectCir.graphics.drawCircle(TopBarPart.UartAutoConnectX + 130,15,8);
			uartConnectCir.graphics.drawCircle(TopBarPart.UartAutoConnectX + 150,15,8);
			uartConnectCir.graphics.endFill();
			addChild(uartConnectCir);
		}
		else{
		}
	}
	
	/*****************************************************************
	功能：串口连接状态显示灯 流水显示
	*****************************************************************/
	public function uartConnectCirSetFlow(state:Number):void{
		switch(state)
		{
			case 0x00:
				uartConnectCir.graphics.beginFill(0x80ff00);
				uartConnectCir.graphics.drawCircle(TopBarPart.UartAutoConnectX + 110,15,8);  //位置坐标依照左上角为准
				uartConnectCir.graphics.beginFill(0xff8060);
				uartConnectCir.graphics.drawCircle(TopBarPart.UartAutoConnectX + 130,15,8);
				uartConnectCir.graphics.drawCircle(TopBarPart.UartAutoConnectX + 150,15,8);
				uartConnectCir.graphics.endFill();
				addChild(uartConnectCir);
				break;
			case 0x01:
				uartConnectCir.graphics.beginFill(0x80ff00);
				uartConnectCir.graphics.drawCircle(TopBarPart.UartAutoConnectX + 130,15,8);
				uartConnectCir.graphics.beginFill(0xff8060);
				uartConnectCir.graphics.drawCircle(TopBarPart.UartAutoConnectX + 110,15,8);	
				uartConnectCir.graphics.drawCircle(TopBarPart.UartAutoConnectX + 150,15,8);
				uartConnectCir.graphics.endFill();
				addChild(uartConnectCir);
				break;
			case 0x02:
				uartConnectCir.graphics.beginFill(0x80ff00);
				uartConnectCir.graphics.drawCircle(TopBarPart.UartAutoConnectX + 150,15,8);
				uartConnectCir.graphics.beginFill(0xff8060);
				uartConnectCir.graphics.drawCircle(TopBarPart.UartAutoConnectX + 110,15,8);	
				uartConnectCir.graphics.drawCircle(TopBarPart.UartAutoConnectX + 130,15,8);
				uartConnectCir.graphics.endFill();
				addChild(uartConnectCir);
				break;				
		}
	}
	
	/*
	//串口自动连接的按钮
	*/
	public function AdduartAutoConnectButton():void{
		var ButtonWidth:int = 110;
		addChild(uartAutoConnectButton);
		uartAutoConnectButton.x= TopBarPart.UartAutoConnectX;
		uartAutoConnectButton.y= TopBarPart.UartAutoConnectY;
	}
	
	
	/////////////////////////////////////////以上由xuhy添加///////////////////////////////////////////////////
	
	protected function dodrive():void {
		app.xuhy_test_log("dodrive");
	}
	
	public function showMYMenu(b:*):void{
		var m:Menu = new Menu(null,'More',CSS.topBarColor(), 28);
	}
	
	public function showHelpMenu(b:*):void {
	}
	

	
	
	protected function editBlockColors():void {
		var d:DialogBox = new DialogBox();
		d.addTitle('Edit Block Colors');
		d.addWidget(new BlockColorEditor());
		d.addButton('Close', d.cancel);
		d.showOnStage(stage, true);
	}

	protected function canExportInternals():Boolean {
		return false;
	}

	private function showAboutDialog():void {
		DialogBox.notify(
				'Scratch 2.0 ' + versionString,
				'\n\nCopyright © 2012 MIT Media Laboratory' +
				'\nAll rights reserved.' +
				'\n\nPlease do not distribute!', stage);
	}

	protected function createNewProjectAndThen(callback:Function = null):void {
		function clearProject():void {
			startNewProject('', '');
			setProjectName('Untitled');
			topBarPart.refresh();
			stagePart.refresh();
			if (callback != null) callback();
		}

		saveProjectAndThen(clearProject);
	}

	protected function createNewProject(ignore:* = null):void {
		createNewProjectAndThen();
	}

	protected function createNewProjectScratchX(jsCallback:Array):void {
		createNewProjectAndThen(function():void {
			externalCallArray(jsCallback);
		});
	}

	protected function saveProjectAndThen(postSaveAction:Function = null):void {
		// Give the user a chance to save their project, if needed, then call postSaveAction.
		function doNothing():void {
		}

		function cancel():void {
			d.cancel();
		}

		function proceedWithoutSaving():void {
			d.cancel();
			postSaveAction()
		}

		function save():void {
			d.cancel();
			exportProjectToFile(false, postSaveAction);
		}

		if (postSaveAction == null) postSaveAction = doNothing;
		if (!saveNeeded) {
			postSaveAction();
			return;
		}
		var d:DialogBox = new DialogBox();
		d.addTitle('Save project?');
		d.addButton('Save', save);
		d.addButton('Don\'t save', proceedWithoutSaving);
		d.addButton('Cancel', cancel);
		d.showOnStage(stage);
	}

	public function exportProjectToFile(fromJS:Boolean = false, saveCallback:Function = null):void {
		function squeakSoundsConverted():void {
			scriptsPane.saveScripts(false);
			var projectType:String = extensionManager.hasExperimentalExtensions() ? '.sbx' : '.sb2';
			var defaultName:String = StringUtil.trim(projectName());
			defaultName = ((defaultName.length > 0) ? defaultName : 'project') + projectType;
			var zipData:ByteArray = projIO.encodeProjectAsZipFile(stagePane);
			var file:FileReference = new FileReference();
			file.addEventListener(Event.COMPLETE, fileSaved);
			file.save(zipData, fixFileName(defaultName));
		}

		function fileSaved(e:Event):void {
			if (!fromJS) setProjectName(e.target.name);
			if (isExtensionDevMode) {
				// Some versions of the editor think of this as an "export" and some think of it as a "save"
				saveNeeded = false;
			}
			if (saveCallback != null) saveCallback();
			if(closeWait == true)//关闭按钮后等待保存完关闭软件_wh
				closeOK = true;
		}
		
		//不保存时序清零状态量_wh
		function fileNoSaved(e:Event):void {
			closeWait = false;//关闭按钮后等待保存完关闭软件_wh
		}
		if (loadInProgress) return;
		var projIO:ProjectIO = new ProjectIO(this);
		projIO.convertSqueakSounds(stagePane, squeakSoundsConverted);
	}

	public static function fixFileName(s:String):String {
		// Replace illegal characters in the given string with dashes.
		const illegal:String = '\\/:*?"<>|%';
		var result:String = '';
		for (var i:int = 0; i < s.length; i++) {
			var ch:String = s.charAt(i);
			if ((i == 0) && ('.' == ch)) ch = '-'; // don't allow leading period
			result += (illegal.indexOf(ch) > -1) ? '-' : ch;
		}
		return result;
	}

	public function saveSummary():void {
		var name:String = (projectName() || "project") + ".txt";
		var file:FileReference = new FileReference();
		file.save(stagePane.getSummary(), fixFileName(name));
	}

	public function toggleSmallStage():void {
		setSmallStageMode(!stageIsContracted);
	}

	public function toggleTurboMode():void {
		interp.turboMode = !interp.turboMode;
		stagePart.refresh();
	}

	public function handleTool(tool:String, evt:MouseEvent):void {
	}

	public function showBubble(text:String, x:* = null, y:* = null, width:Number = 0):void {
		if (x == null) x = stage.mouseX;
		if (y == null) y = stage.mouseY;
		gh.showBubble(text, Number(x), Number(y), width);
	}

	// TODO: calculate field width for up to 40 hex digits of CSS.normalTextFont
	protected const kGitHashFieldWidth:int = 7 * 41;
	protected function makeVersionDetailsDialog():DialogBox {
		var d:DialogBox = new DialogBox();
		d.addTitle('Version Details');
		d.addField('GPU enabled', kGitHashFieldWidth, SCRATCH::allow3d);
		d.addField('scratch-flash', kGitHashFieldWidth, SCRATCH::revision);
		return d;
	}

	protected function showVersionDetails():void {
		var versionDetailsBox:DialogBox = makeVersionDetailsDialog();
		versionDetailsBox.addButton('OK', versionDetailsBox.accept);
		versionDetailsBox.showOnStage(stage);
	}

	// -----------------------------
	// Project Management and Sign in
	//------------------------------

	public function setLanguagePressed(b:IconButton):void {
		function setLanguage(lang:String):void {
			Translator.setLanguage(lang);
			languageChanged = true;
		}

		if (Translator.languages.length == 0) return; // empty language list
		var m:Menu = new Menu(setLanguage, 'Language', CSS.topBarColor(), 28);
		if (b.lastEvent.shiftKey) {
			m.addItem('import translation file');
			m.addItem('set font size');
			m.addLine();
		}
		for each (var entry:Array in Translator.languages) {
			m.addItem(entry[1], entry[0]);
		}
		var p:Point = b.localToGlobal(new Point(0, 0));
		m.showOnStage(stage, b.x, topBarPart.bottom() - 1);
	}

	public function startNewProject(newOwner:String, newID:String):void {
		runtime.installNewProject();
		projectOwner = newOwner;
		projectID = newID;
		projectIsPrivate = true;
	}

	// -----------------------------
	// Save status
	//------------------------------

	public var saveNeeded:Boolean;

	public function setSaveNeeded(saveNow:Boolean = false):void {
		saveNow = false;
		// Set saveNeeded flag and update the status string.
		saveNeeded = true;
		if (!wasEdited) saveNow = true; // force a save on first change
		clearRevertUndo();
	}

	protected function clearSaveNeeded():void {
		// Clear saveNeeded flag and update the status string.
		function twoDigits(n:int):String {
			return ((n < 10) ? '0' : '') + n
		}

		saveNeeded = false;
		wasEdited = true;
	}

	// -----------------------------
	// Project Reverting
	//------------------------------

	protected var originalProj:ByteArray;
	private var revertUndo:ByteArray;

	public function saveForRevert(projData:ByteArray, isNew:Boolean, onServer:Boolean = false):void {
		originalProj = projData;
		revertUndo = null;
	}

	protected function doRevert():void {
		runtime.installProjectFromData(originalProj, false);
	}

	protected function revertToOriginalProject():void {
		function preDoRevert():void {
			revertUndo = new ProjectIO(Scratch.app).encodeProjectAsZipFile(stagePane);
			doRevert();
		}

		if (!originalProj) return;
		DialogBox.confirm('Throw away all changes since opening this project?', stage, preDoRevert);
	}

	protected function undoRevert():void {
		if (!revertUndo) return;
		runtime.installProjectFromData(revertUndo, false);
		revertUndo = null;
	}

	protected function canRevert():Boolean {
		return originalProj != null
	}

	protected function canUndoRevert():Boolean {
		return revertUndo != null
	}

	private function clearRevertUndo():void {
		revertUndo = null
	}

	public function addNewSprite(spr:ScratchSprite, showImages:Boolean = false, atMouse:Boolean = false):void {
		var c:ScratchCostume, byteCount:int;
		for each (c in spr.costumes) {
			if (!c.baseLayerData) c.prepareToSave()
			byteCount += c.baseLayerData.length;
		}
		if (!okayToAdd(byteCount)) return; // not enough room
		spr.objName = stagePane.unusedSpriteName(spr.objName);
		spr.indexInLibrary = 1000000; // add at end of library
		spr.setScratchXY(int(200 * Math.random() - 100), int(100 * Math.random() - 50));
		if (atMouse) spr.setScratchXY(stagePane.scratchMouseX(), stagePane.scratchMouseY());
		stagePane.addChild(spr);
		spr.updateCostume();
		selectSprite(spr);
		setTab(showImages ? 'images' : 'scripts');
		setSaveNeeded(true);
		libraryPart.refresh();
		for each (c in spr.costumes) {
			if (ScratchCostume.isSVGData(c.baseLayerData)) c.setSVGData(c.baseLayerData, false);
		}
	}

	public function addSound(snd:ScratchSound, targetObj:ScratchObj = null):void {
		if (snd.soundData && !okayToAdd(snd.soundData.length)) return; // not enough room
		if (!targetObj) targetObj = viewedObj();
		snd.soundName = targetObj.unusedSoundName(snd.soundName);
		targetObj.sounds.push(snd);
		setSaveNeeded(true);
		if (targetObj == viewedObj()) {
			soundsPart.selectSound(snd);
			setTab('sounds');
		}
	}

	public function addCostume(c:ScratchCostume, targetObj:ScratchObj = null):void {
		if (!c.baseLayerData) c.prepareToSave();
		if (!okayToAdd(c.baseLayerData.length)) return; // not enough room
		if (!targetObj) targetObj = viewedObj();
		c.costumeName = targetObj.unusedCostumeName(c.costumeName);
		targetObj.costumes.push(c);
		targetObj.showCostumeNamed(c.costumeName);
		setSaveNeeded(true);
		if (targetObj == viewedObj()) setTab('images');
	}

	public function okayToAdd(newAssetBytes:int):Boolean {
		// Return true if there is room to add an asset of the given size.
		// Otherwise, return false and display a warning dialog.
		const assetByteLimit:int = 50 * 1024 * 1024; // 50 megabytes
		var assetByteCount:int = newAssetBytes;
		for each (var obj:ScratchObj in stagePane.allObjects()) {
			for each (var c:ScratchCostume in obj.costumes) {
				if (!c.baseLayerData) c.prepareToSave();
				assetByteCount += c.baseLayerData.length;
			}
			for each (var snd:ScratchSound in obj.sounds) assetByteCount += snd.soundData.length;
		}
		if (assetByteCount > assetByteLimit) {
			var overBy:int = Math.max(1, (assetByteCount - assetByteLimit) / 1024);
			DialogBox.notify(
					'Sorry!',
					'Adding that media asset would put this project over the size limit by ' + overBy + ' KB\n' +
					'Please remove some costumes, backdrops, or sounds before adding additional media.',
					stage);
			return false;
		}
		return true;
	}

	// -----------------------------
	// Flash sprite (helps connect a sprite on the stage with a sprite library entry)
	//------------------------------

	public function flashSprite(spr:ScratchSprite):void {
		function doFade(alpha:Number):void {
			box.alpha = alpha
		}

		function deleteBox():void {
			if (box.parent) {
				box.parent.removeChild(box)
			}
		}

		var r:Rectangle = spr.getVisibleBounds(this);
		var box:Shape = new Shape();
		box.graphics.lineStyle(3, CSS.overColor, 1, true);
		box.graphics.beginFill(0x808080);
		box.graphics.drawRoundRect(0, 0, r.width, r.height, 12, 12);
		box.x = r.x;
		box.y = r.y;
		addChild(box);
		Transition.cubic(doFade, 1, 0, 0.5, deleteBox);
	}

	// -----------------------------
	// Download Progress
	//------------------------------

	public function addLoadProgressBox(title:String):void {
		removeLoadProgressBox();
		lp = new LoadProgress();
		lp.setTitle(title);
		stage.addChild(lp);
		fixLoadProgressLayout();
	}

	public function removeLoadProgressBox():void {
		if (lp && lp.parent) lp.parent.removeChild(lp);
		lp = null;
	}

	private function fixLoadProgressLayout():void {
		if (!lp) return;
		var p:Point = stagePane.localToGlobal(new Point(0, 0));
		lp.scaleX = stagePane.scaleX;
		lp.scaleY = stagePane.scaleY;
		lp.x = int(p.x + ((stagePane.width - lp.width) / 2));
		lp.y = int(p.y + ((stagePane.height - lp.height) / 2));
	}

	// -----------------------------
	// Frame rate readout (for use during development)
	//------------------------------

	private var frameRateReadout:TextField;
	private var firstFrameTime:int;
	private var frameCount:int;

	protected function addFrameRateReadout(x:int, y:int, color:uint = 0):void {
		frameRateReadout = new TextField();
		frameRateReadout.autoSize = TextFieldAutoSize.LEFT;
		frameRateReadout.selectable = false;
		frameRateReadout.background = false;
		frameRateReadout.defaultTextFormat = new TextFormat(CSS.font, 12, color);
		frameRateReadout.x = x;
		frameRateReadout.y = y;
		addChild(frameRateReadout);
		frameRateReadout.addEventListener(Event.ENTER_FRAME, updateFrameRate);
	}

	private function updateFrameRate(e:Event):void {
		frameCount++;
		if (!frameRateReadout) return;
		var now:int = getTimer();
		var msecs:int = now - firstFrameTime;
		if (msecs > 500) {
			var fps:Number = Math.round((1000 * frameCount) / msecs);
			frameRateReadout.text = fps + ' fps (' + Math.round(msecs / frameCount) + ' msecs)';
			firstFrameTime = now;
			frameCount = 0;
		}
	}

	// TODO: Remove / no longer used
	private const frameRateGraphH:int = 150;
	private var frameRateGraph:Shape;
	private var nextFrameRateX:int;
	private var lastFrameTime:int;

	private function addFrameRateGraph():void {
		addChild(frameRateGraph = new Shape());
		frameRateGraph.y = stage.stageHeight - frameRateGraphH;
		clearFrameRateGraph();
		stage.addEventListener(Event.ENTER_FRAME, updateFrameRateGraph);
	}

	public function clearFrameRateGraph():void {
		var g:Graphics = frameRateGraph.graphics;
		g.clear();
		g.beginFill(0xFFFFFF);
		g.drawRect(0, 0, stage.stageWidth, frameRateGraphH);
		nextFrameRateX = 0;
	}

	private function updateFrameRateGraph(evt:*):void {
		var now:int = getTimer();
		var msecs:int = now - lastFrameTime;
		lastFrameTime = now;
		var c:int = 0x505050;
		if (msecs > 40) c = 0xE0E020;
		if (msecs > 50) c = 0xA02020;

		if (nextFrameRateX > stage.stageWidth) clearFrameRateGraph();
		var g:Graphics = frameRateGraph.graphics;
		g.beginFill(c);
		var barH:int = Math.min(frameRateGraphH, msecs / 2);
		g.drawRect(nextFrameRateX, frameRateGraphH - barH, 1, barH);
		nextFrameRateX++;
	}

	// -----------------------------
	// Camera Dialog
	//------------------------------

	public function openCameraDialog(savePhoto:Function):void {
		closeCameraDialog();
		cameraDialog = new CameraDialog(savePhoto);
		cameraDialog.fixLayout();
		cameraDialog.x = (stage.stageWidth - cameraDialog.width) / 2;
		cameraDialog.y = (stage.stageHeight - cameraDialog.height) / 2;
		addChild(cameraDialog);
	}

	public function closeCameraDialog():void {
		if (cameraDialog) {
			cameraDialog.closeDialog();
			cameraDialog = null;
		}
	}

	// Misc.
	public function createMediaInfo(obj:*, owningObj:ScratchObj = null):MediaInfo {
		return new MediaInfo(obj, owningObj);
	}

	static public function loadSingleFile(fileLoaded:Function, filter:FileFilter = null):void {
		function fileSelected(event:Event):void {
			if (fileList.fileList.length > 0) {
				var file:FileReference = FileReference(fileList.fileList[0]);
				file.addEventListener(Event.COMPLETE, fileLoaded);
				file.load();
			}
		}

		var fileList:FileReferenceList = new FileReferenceList();
		fileList.addEventListener(Event.SELECT, fileSelected);
		try {
			// Ignore the exception that happens when you call browse() with the file browser open
			fileList.browse(filter != null ? [filter] : null);
		} catch (e:*) {
		}
	}

	// -----------------------------
	// External Interface abstraction
	//------------------------------

	public function externalInterfaceAvailable():Boolean {
		return ExternalInterface.available;
	}

	public function externalCall(functionName:String, returnValueCallback:Function = null, ...args):void {
		args.unshift(functionName);
		var retVal:*;
		try {
			retVal = ExternalInterface.call.apply(ExternalInterface, args);
		}
		catch (e:Error)
		{
			logException(e);
			// fall through to below
		}
		if (returnValueCallback != null) {
			returnValueCallback(retVal);
		}
	}

	public function addExternalCallback(functionName:String, closure:Function):void {
		ExternalInterface.addCallback(functionName, closure);
	}

	// jsCallbackArray is: [functionName, arg1, arg2...] where args are optional.
	// TODO: rewrite all versions of externalCall in terms of this
	public function externalCallArray(jsCallbackArray:Array, returnValueCallback:Function = null):void {
		var args:Array = jsCallbackArray.concat(); // clone
		args.splice(1, 0, returnValueCallback);
		externalCall.apply(this, args);
	}

}}




























