#include "CFunBuzzer.h"

uint8_t buzzer_pin;
volatile long timer2_toggle_count;
volatile uint8_t *timer2_pin_port;
volatile uint8_t timer2_pin_mask;


// timer in CTC mode
// Set the OCR for the given timer,
// set the toggle count,
// then turn on the interrupts
// OCR2A = ocr;
void Timer2Init(uint32_t TimerFreq)
{

    static const uint16_t pscLst_alt[] = {0, 1, 8, 32, 64, 128, 256, 1024};

    //Set frequency of timer2
    //setting the waveform generation mode
    uint8_t wgm = 2;
    TCCR2A = 0;
    TCCR2B = 0;
    TCCR2A = (TCCR2A & B11111100) | (wgm & 3);
    TCCR2B = (TCCR2B & B11110111) | ((wgm & 12) << 1);

    uint16_t multiplier = F_CPU / 2 / TimerFreq / 256;
    byte iterate = 0;
    while(multiplier > pscLst_alt[++iterate]);
    multiplier = pscLst_alt[iterate];
    OCR2A = F_CPU/2/TimerFreq/ multiplier-1;
    TCCR2B = (TCCR2B & ~7) | (iterate & 7);

    //enable interrupt
    bitSet(TIMSK2, OCIE2B);
}

CFunBuzzer::CFunBuzzer()
 {
 
 }
 
CFunBuzzer::CFunBuzzer(uint8_t pin)
 {
  buzzer_pin = pin;
 }


 // frequency (in hertz) and duration (in milliseconds).
void CFunBuzzer::tone(uint8_t pin,uint16_t frequency, uint32_t duration)
{
  buzzer_pin = pin;
  // _buzz_ir=0;
  uint8_t prescalarbits = 0b001;
  long toggle_count = 0;
  uint32_t ocr = 0;
    timer2_pin_port = portOutputRegister(digitalPinToPort(buzzer_pin));
    timer2_pin_mask = digitalPinToBitMask(buzzer_pin);  
    // Set the pinMode as OUTPUT
    pinMode(buzzer_pin, OUTPUT); 
    // Calculate the toggle count
    if (duration > 0)
    {
      toggle_count = 2 * frequency * duration / 1000;
    }
    else
    {
      toggle_count = -1;
    }

    timer2_toggle_count = toggle_count;
    Timer2Init(frequency);
}

void CFunBuzzer::noTone(uint8_t pin)
{
    buzzer_pin=pin;
    bitWrite(TIMSK2, OCIE2B, 0); // disable interrupt
    digitalWrite(buzzer_pin, LOW);
}

ISR(TIMER2_COMPB_vect)
{

  if (timer2_toggle_count != 0)
  {
    // toggle the pin
    *timer2_pin_port ^= timer2_pin_mask;

    if (timer2_toggle_count > 0)
      timer2_toggle_count--;
  }
  else
  {
    bitWrite(TIMSK2, OCIE2B, 0); // disable interrupt
    digitalWrite(buzzer_pin, LOW);
  }
}
