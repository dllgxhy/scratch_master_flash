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

import flash.display.Sprite;

public class ArduinoLibrary extends Sprite{
	
	public var uartData:ArduinoUart;
	
	public static var arduinoLightValue:int = 0x00;  //作为全局变量
	public static var arduinoSlideValue:int = 0x00;
	public static var arduinoSoundValue:int = 0x00;
	public static var arduinoUltrasonicValue:int = 0x00;
	
}}
