#include "BluetoothSerial.h"
#include <AccelStepper.h>
#include <cstring>
#include <vector>

double charToDouble(char* charArray) {
    double result;
    char* bytePtr = reinterpret_cast<char*>(&result);
    std::memcpy(bytePtr, charArray, sizeof(double));
    return result;
}
/* Check if Bluetooth configurations are enabled in the SDK */
/* If not, then you have to recompile the SDK */
#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth is not enabled! Please run `make menuconfig` to and enable it
#endif
BluetoothSerial SerialBT;
AccelStepper xStepper(1, 0, 15);
AccelStepper panStepper(1, 14, 27);
AccelStepper tiltStepper(1, 4, 16);
//define parameter
std::vector<double> pos;
double pulseToMili = 16/3200;
double meterToPulse = 3200/16*1000;
double panToPulse = 3200/360;
long maxXSpeed = 0.5*meterToPulse;
long accelarator = 6400;
long distanceToSpeed(long current, long target)
{
  int delta = target-current;
  if (delta <maxXSpeed)
    return delta;
  return maxXSpeed;
  
}
void setup() {
  pinMode(15,OUTPUT);
  Serial.begin(115200);
  SerialBT.begin("SliderController");
  /* If no name is given, default 'ESP32' is applied */
  /* If you want to give your own name to ESP32 Bluetooth device, then */
  /* specify the name as an argument SerialBT.begin("myESP32Bluetooth*/
  SerialBT.begin();
  Serial.println("Bluetooth Started! Ready to pair...");
  xStepper.setAcceleration(accelarator);
  xStepper.setMaxSpeed(maxXSpeed);
  panStepper.setAcceleration(accelarator);
    panStepper.setMaxSpeed(maxXSpeed);
  tiltStepper.setAcceleration(accelarator);

}

void loop() {

  if (Serial.available())
  {
    SerialBT.write(Serial.read());
  }
  if (SerialBT.available())
  {
    char instruction = SerialBT.read();
    
    switch (instruction)
    {
      case 'x':
      {
        char input[sizeof(double)];
        int i=0;
        //should not do this with very low timing signal, reimplement when read
        while (SerialBT.available())
        {
          char r = SerialBT.read();
          if (r == '\n')
            break;
          input[i] = r;
          i++;
        }

        double value = charToDouble(input);     
        xStepper.stop();
        xStepper.moveTo((long) (value*meterToPulse));

        Serial.print("move to: ");
        Serial.println(xStepper.targetPosition());
        instruction =0;
        break;
      }
      case 'p':
      {
        char input[sizeof(double)];
        int i=0;
        //should not do this with very low timing signal, reimplement when read
        while (SerialBT.available())
        {
          char r = SerialBT.read();
          if (r == '\n')
            break;
          input[i] = r;
          i++;
        }

        double value = charToDouble(input);     
        panStepper.stop();
        panStepper.moveTo((long) (value*panToPulse));

        Serial.print("rotate to: ");
        Serial.println((long) (value*panToPulse));
        instruction =0;
        break;
      }
      case 's':
      {
        char input[sizeof(double)];
        int i=0;
        //should not do this with very low timing signal, reimplement when read
        while (SerialBT.available())
        {
          char r = SerialBT.read();
          if (r == '\n')
            break;
          input[i] = r;
          if (i ==1)
          {
            i=0;
            pos.push_back(charToDouble(input));
            Serial.print(pos.back());
            Serial.print(" ");
          }
          else
            i++;
        }
        
        double value = charToDouble(input);     
        panStepper.stop();
        panStepper.moveTo((long) (value*panToPulse));

        Serial.print("rotate to: ");
        Serial.println((long) (value*panToPulse));
        instruction =0;
        break;
      }
    
    }
  }
  static const unsigned long REFRESH_INTERVAL = 800; // ms
  static unsigned long lastRefreshTime = 0;
  
  if(millis() - lastRefreshTime >= REFRESH_INTERVAL)
  {
    lastRefreshTime += REFRESH_INTERVAL;
    Serial.print("current pos: ");
    Serial.println(xStepper.currentPosition()/meterToPulse);
     Serial.print("current rotate: ");
    Serial.println(panStepper.currentPosition()/panToPulse);
 

  }
    xStepper.run();
    panStepper.run();

}
