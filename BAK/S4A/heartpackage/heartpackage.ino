void setup()
{
 Serial.begin(115200);  
 Serial.flush();
}

void loop()
{
  Serial.println("hello arduino");
  delay(100);
}
