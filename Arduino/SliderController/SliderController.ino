#include "BluetoothSerial.h"
#include <AccelStepper.h>
#include <cstring>
#include <vector>
#include "CircularList.h"
#include "Keyframe.h"
double charToDouble(uint8_t *charArray)
{
    double result;
    uint8_t *bytePtr = reinterpret_cast<uint8_t *>(&result);
    std::memcpy(bytePtr, charArray, sizeof(double));
    return result;
}
int charToInt(uint8_t *charArray)
{
    int result;
    uint8_t *bytePtr = reinterpret_cast<uint8_t *>(&result);
    std::memcpy(bytePtr, charArray, sizeof(int));
    return result;
}
/* Check if Bluetooth configurations are enabled in the SDK */
/* If not, then you have to recompile the SDK */
#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth is not enabled! Please run make menuconfig to and enable it
#endif
BluetoothSerial SerialBT;
AccelStepper xStepper(1, 23, 22);
AccelStepper panStepper(1, 14, 27);
AccelStepper tiltStepper(1, 4, 16);
// define parameter
std::vector<Keyframe> keyframeList;
std::vector<double> posList;
double meterToPulse = 1000/40 * 1600;
double panToPulse = 3200 / 360;
long maxXSpeed = 0.5 * meterToPulse;
long accelarator = 25600;
const unsigned long REFRESH_INTERVAL = 100; // ms
unsigned long lastRefreshTime = 0;
const unsigned long RUN_REFRESH_INTERVAL = 100; // ms
double dt = (double)RUN_REFRESH_INTERVAL / 1000.0;
unsigned long lastRunRefreshTime = 0;
uint8_t instruction;
bool readState;
int s;
double bezier(double t,double p0,double p1,double p2,double p3) {
    double u = 1 - t;
    double tt = t * t;
    double uu = u * u;
    double uuu = uu * u;
    double ttt = tt * t;


    double y = uuu * p0 + 3 * uu * t * p1 + 3 * u * tt * p2 + ttt * p3;

    return y;
}
void keyframeToStep()
{
        std::vector<double> posVelocity;
        posVelocity.push_back(0.0);
        Serial.println("start processing");
        Serial.println("calculating velocity");
        for (int i = 1; i < keyframeList.size()-1;i++)
        {
            double time1 =  keyframeList.at(i-1).time;
            double time2 =  keyframeList.at(i).time;
            double pos1 = keyframeList.at(i-1).position;
            double pos2 = keyframeList.at(i).position;
            posVelocity.push_back((pos2-pos1)/(time2-time1));
        }
        posVelocity.push_back(0.0);
        Serial.println("dividing keyframe");
        for (int i = 0; i < keyframeList.size()-1;i++)
        {
            Serial.println(i);
            double time1 =  keyframeList.at(i).time;
            double time2 =  keyframeList.at(i+1).time;
            double pos1 = keyframeList.at(i).position;
            double pos2 = keyframeList.at(i+1).position;
            Serial.println("ingoing and outgoing");
            double outgoing = keyframeList.at(i).outgoing/100;
            double ingoing = keyframeList.at(i+1).ingoing/100;

            double x1 = time1 + (time2 -  time1)*outgoing;
            double y1 = pos1 + posVelocity[i]*(time2 -  time1)*outgoing;

            double x2 = time2 - (time2 -  time1)*ingoing;
            double y2 = pos2-posVelocity[i+1]*(time2 -  time1)*ingoing;

            double p0 = pos1;
            double p1 =  y1 ;
            double p2 = y2 ;
            double p3 = pos2;
            Serial.println("dividing");
            for (double j = time1; j<time2;j+=dt)
            {

                double result = bezier((j-time1)/(time2-time1), p0, p1, p2, p3);
                Serial.println(result);
                posList.push_back(result);
            }
        }
}

void setup()
{
    pinMode(15, OUTPUT);
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
    instruction = 0;
    readState = false;
    xStepper.setRunWithoutStop(false);
}

CircularList<uint8_t> buff;
bool script_start = false;
void loop()
{
    static Keyframe currentKeyframe;
    static int propertyIndex = 0;
    static int index = 0;
    static int count;
    static uint8_t readBuffer[sizeof(int)];

    if (Serial.available())
    {
        SerialBT.write(Serial.read());
    }

    if (SerialBT.available())
    {
        buff.push_back(SerialBT.read());
        if (instruction == 0)
        {
            Serial.println("new Instruction");
            instruction = buff.back();
            Serial.println(instruction);
            buff.pop_back();
        }

        switch (instruction)
        {
//        case 120:
//        {
//          static uint8_t dataBuffer[sizeof(double)];
//          count++;
//          if (count == sizeof(double))
//          {
//              for (int j = 0; j < sizeof(double); j++)
//              {
//                  dataBuffer[j] = buff[0];
//                  buff.pop_front();
//                  instruction = 0;
//              }
//              double value = charToDouble(dataBuffer);
//              xStepper.stop();
//              xStepper.moveTo((long)(value * meterToPulse));
//              xStepper.setMaxSpeed(0.2*meterToPulse);
//              Serial.print(value);
//              Serial.print(" ");
//               Serial.print("size of buff: ");
//               Serial.println(buff.size());
//              count = 0;
//          }
//          break;
//        }
        case 115:
        {
            if (!readState)
            {
                Serial.println("about to receive script");
                propertyIndex = 0;
                s = 0;
                count = 0;
                readState = true;
                keyframeList.clear();
            }
            else
            {
                if (s == 0)
                {
                    Serial.println("reading length...");
                    count++;
                    if (count == sizeof(int))
                    {
                        for (int j = 0; j < sizeof(int); j++)
                        {
                            readBuffer[j] = buff[0];
                            buff.pop_front();
                        }
                        s = charToInt(readBuffer);
                        Serial.print("about to receive: ");
                        Serial.print(s);
                        Serial.print(" bytes");
                        Serial.println();
                        count = 0;
                    }
                }
                else
                {
                    static uint8_t dataBuffer[sizeof(double)];
                    count++;
                    if (count == sizeof(double))
                    {
                        for (int j = 0; j < sizeof(double); j++)
                        {
                            dataBuffer[j] = buff[0];
                            buff.pop_front();
                        }
                        double value = charToDouble(dataBuffer);
                        Serial.print(value);
                        Serial.print(" ");
                        *(((double*)&currentKeyframe)+propertyIndex) = value;
                        propertyIndex++;
                        if (propertyIndex*sizeof(double)==sizeof(currentKeyframe))
                        {
                            keyframeList.push_back(currentKeyframe);

                            Serial.println();
                            propertyIndex =0;
                        }
                        count = 0;
                    }
                    if (keyframeList.size() == s)
                    {
                        Serial.println("done reading data");
                        xStepper.moveTo((long)((keyframeList[0].position) * meterToPulse));
                        keyframeToStep();
                        instruction = 0;
                        s = 0;
                    }
                }
            }
            break;
        }
        case 105:
        {
            if (keyframeList.size() < 2)
            {
                instruction = 0;
            }
            else
            {
                index = 0;
                script_start = true;
                
                Serial.println("start");
                xStepper.setRunWithoutStop(true);
                instruction = 0;
            }
            break;
        }
          default:
          {
              instruction = 0;
              break;
          }
        }
    }    



    if (millis() - lastRefreshTime >= REFRESH_INTERVAL)
    {
        lastRefreshTime += REFRESH_INTERVAL;

    }
        static double percentIncrease = 1.0;
        static double const DIFF = 0.2 / meterToPulse;

        if (millis() - lastRunRefreshTime >= RUN_REFRESH_INTERVAL)
        {
            lastRunRefreshTime += RUN_REFRESH_INTERVAL;
                if (script_start)
        {
            index++;
            if (index == posList.size())
            {
                xStepper.setRunWithoutStop(false);
                percentIncrease=1;
                xStepper.moveTo((long)((keyframeList[0].position) * meterToPulse));
                xStepper.setMaxSpeed(accelarator);
                Serial.println("stopping");
                script_start = false;
            }
            else
            {
                long delta = ( xStepper.currentPosition() - posList[index - 1] * meterToPulse);
                // me   -----> target
                if (delta < 0)
                {                 // delta  ///
                  //  from -------me--------target
                  if (posList[index - 1] - posList[index - 2] > 0)
                  {
                    delta = abs(delta);
                  }
                  //  me--------target---------from
                  else
                  {
                    
                  }
                }
                else
                {
                                               // delta  ///
                  //  from ---------------target ---------me
                  if (posList[index - 1] - posList[index - 2] > 0)
                  {
                    delta = -delta;
                  }       // delta  ///
                  //  target---------me---------from
                  else
                  {
                    
                  }
                }
                percentIncrease += delta * DIFF;
                if (percentIncrease > 2)
                {
                    percentIncrease = 2;
                }
                static long oldSpeedNeeded = 0;
                long distanceToNext = (posList[index]* meterToPulse - xStepper.currentPosition()) ;
                long movingDirection = (posList[index] - posList[index-1])* meterToPulse;
                long speedNeeded;

                if (distanceToNext*movingDirection > 0)
                {
                   speedNeeded = abs( (long)(((double)distanceToNext) / dt));
                }
                else
                {
                  speedNeeded = 1;
                }


                speedNeeded *= percentIncrease;
                speedNeeded = abs(speedNeeded);

                xStepper.stop();
                xStepper.moveTo((long)((posList[index]) * meterToPulse));
                xStepper.setMaxSpeed(speedNeeded);
                xStepper.setAcceleration(abs((long)(((double)(speedNeeded-oldSpeedNeeded))/dt)));
                oldSpeedNeeded = speedNeeded;
//                Serial.print("distanceToNext ");
//                 Serial.println(distanceToNext);
//                  Serial.print("movingDirection ");
//                 Serial.println(movingDirection);
//                Serial.print("bluetooth buffer size: " );
//                Serial.println(buff.size());
//                Serial.print("current speed percent: ");
//                Serial.println(percentIncrease);
//                Serial.print("setAcceleration ");
//                Serial.println(abs((long)(((double)(speedNeeded-oldSpeedNeeded))/dt)));
//                Serial.print("new Max speed: ");
//                Serial.println(speedNeeded, 8);
//                
                Serial.print("current pos: ");
                Serial.println((double)xStepper.currentPosition() / meterToPulse, 8 );
                Serial.print("moving to: ");
                Serial.println((posList[index]), 8);
                Serial.print("current speed: ");
                Serial.println(xStepper.speed());
            }
        }
    }
    xStepper.run();
    panStepper.run();
}
