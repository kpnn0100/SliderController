#include "BluetoothSerial.h"
#include <AccelStepper.h>
#include <cstring>
#include <vector>
#include "CircularList.h"
#include "Keyframe.h"
int numberOfDim = 3;
int ENDSTOP_X = 14;
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
AccelStepper stepper[3];

// define parameter
std::vector<Keyframe> keyframeList;
std::vector<std::vector<double>> valueList;
double valueToPulse[3];


long accelarator = 4500;
const unsigned long REFRESH_INTERVAL = 1000; // ms
unsigned long lastRefreshTime = 0;
const unsigned long RUN_REFRESH_INTERVAL = 100; // ms
double dt = (double)RUN_REFRESH_INTERVAL / 1000.0;
unsigned long lastRunRefreshTime = 0;
uint8_t instruction;
bool readState;
int s;
int cou = 0;
long MAX_SPEED = 8000;
int minDim[3];
CircularList<uint8_t> buff;
Point cubic_bezier(Point p0, Point p1, Point p2, Point p3, double t)
{
    // Calculate blending functions
    double t2 = t * t;
    double t3 = t2 * t;
    double mt = 1 - t;
    double mt2 = mt * mt;
    double mt3 = mt2 * mt;

    // Calculate interpolated point
    double x = mt3 * p0.x + 3 * mt2 * t * p1.x + 3 * mt * t2 * p2.x + t3 * p3.x;
    double y = mt3 * p0.y + 3 * mt2 * t * p1.y + 3 * mt * t2 * p2.y + t3 * p3.y;

    Point result = {x, y};
    return result;
}
double findTfromX(Point p0, Point p1, Point p2, Point p3, double x)
{
    double delta = p3.x - p0.x;
    double lowX = 0;
    double highX = 1;
    double indexOfX = x;

    if (x > 0.9)
    {
        indexOfX = 1;
    }

    double dataToSearch = cubic_bezier(p0, p1, p2, p3, indexOfX).x;
    double xNeedEqual = (dataToSearch - p0.x) / delta;

    while (std::abs(x - xNeedEqual) > 0.000001)
    {
        if (x > xNeedEqual)
        {
            lowX = indexOfX;
            indexOfX = (indexOfX + highX) / 2;
        }
        else
        {
            highX = indexOfX;
            indexOfX = (indexOfX + lowX) / 2;
        }

        dataToSearch = cubic_bezier(p0, p1, p2, p3, indexOfX).x;
        xNeedEqual = (dataToSearch - p0.x) / delta;
    }

    return indexOfX;
}

double bezierYfromTime(Point p0, Point p1, Point p2, Point p3, double t)
{
    return cubic_bezier(p0, p1, p2, p3, findTfromX(p0, p1, p2, p3, t)).y;
}

void keyframeToStep()
{
    std::vector<std::vector<double>> velocity;

    for (int k = 0; k < numberOfDim; k++)
    {
        velocity.push_back({0.0});

        Serial.print("start processing for dim ");
        Serial.println(k);

        for (int i = 1; i < keyframeList.size() - 1; i++)
        {
            double time1 = keyframeList.at(i - 1).time;
            double time2 = keyframeList.at(i).time;
            double time3 = keyframeList.at(i+1).time;
            double pos1 = keyframeList.at(i - 1).value[k];
            double pos2 = keyframeList.at(i).value[k];
            double pos3 = keyframeList.at(i+1).value[k];
            double veBefore = (pos2 - pos1) / (time2 - time1);
            double veAfter = (pos3 - pos2) / (time3 - time2);
            velocity[k].push_back(veBefore+veAfter/2);
        }
        velocity[k].push_back(0.0);
        for (int i = 0; i < keyframeList.size() - 1; i++)
        {
            double time1 = keyframeList.at(i).time;
            double time2 = keyframeList.at(i + 1).time;
            double pos1 = keyframeList.at(i).value[k];
            double pos2 = keyframeList.at(i + 1).value[k];
            double outgoing = keyframeList.at(i).outgoing / 100;
            double ingoing = keyframeList.at(i + 1).ingoing / 100;
            Point p[4];
            p[0].x = time1;
            p[0].y = pos1;

            p[1].x = time1 + (time2 - time1) * outgoing;
            p[1].y = pos1 + velocity[k][i] * (time2 - time1) * outgoing;


            p[2].x = time2 - (time2 - time1) * ingoing;
            p[2].y = pos2 - velocity[k][i + 1] * (time2 - time1) * ingoing;

            p[3].x = time2;
            p[3].y = pos2;
            for (double j = time1; j < time2-dt/10; j += dt)
            {

                double result = bezierYfromTime(p[0], p[1], p[2], p[3], (j - time1) / (time2 - time1));
                if (result < minDim[k])
                {
                  result = minDim[k];
                }
                Serial.println(result, 8);
                valueList[k].push_back(result);
            }
        }
    }
}
double percentIncrease[3] = {1, 1, 1};
double DIFF[3];

void setup()
{
    pinMode(ENDSTOP_X,INPUT_PULLUP);
    Serial.begin(115200);
    SerialBT.begin("SliderController");
    /* If no name is given, default 'ESP32' is applied */
    /* If you want to give your own name to ESP32 Bluetooth device, then */
    /* specify the name as an argument SerialBT.begin("myESP32Bluetooth*/
    SerialBT.begin();
    Serial.println("Bluetooth Started! Ready to pair...");
    stepper[0] = AccelStepper(1, 23, 22);
    stepper[1] = AccelStepper(1, 18, 19);
    stepper[2] = AccelStepper(1, 17, 16);
    stepper[0].setPinsInverted(true);
    stepper[1].setPinsInverted(true);
    minDim[0]=0;
    minDim[1]=-90;
    minDim[2]=-45;
    pinMode(15,OUTPUT);
    digitalWrite(15, LOW);
    for (int i = 0; i < numberOfDim; i++)
    {
      stepper[i].setAcceleration(accelarator);
      stepper[i].setMaxSpeed(MAX_SPEED);

    }
    
    valueList.push_back({});
    valueList.push_back({});
    valueList.push_back({});
    valueToPulse[0] = 1000 / 40 * 1600;
    valueToPulse[1] = 40;// 1600 * 9/360
    valueToPulse[2] = 1600 * 3/360;
        for (int i = 0; i < numberOfDim; i++)
    {
      if (i>0)
      {
        DIFF[i] = 0 / valueToPulse[i]/360;
      }
      else
        DIFF[i] = 0 / valueToPulse[i];
        
    }
    instruction = 0;
    readState = false;
}
bool readStateForDim[3] = {false, false, false};
void readValue(int dimension)
{
    static uint8_t dataBuffer[sizeof(double)];
    if (!readStateForDim[dimension])
    {
        Serial.print("about to receive dim: ");
        Serial.println(dimension);
        cou = 0;
        readStateForDim[dimension] = true;
    }
    else
    {
        cou++;
        if (cou == sizeof(double))
        {
            for (int j = 0; j < sizeof(double); j++)
            {
                dataBuffer[j] = buff[0];
                Serial.print("buffer ");
                Serial.print(j);
                Serial.print(" ");
                Serial.println(dataBuffer[j]);
                buff.pop_front();
            }
            double value = charToDouble(dataBuffer);
            Serial.print(value);
            Serial.print(" ");
            stepper[dimension].stop();
            stepper[dimension].moveTo((long)(value * valueToPulse[dimension]));
            stepper[dimension].setMaxSpeed(MAX_SPEED);
            cou = 0;
            readStateForDim[dimension] = false;
            instruction = 0;
        }
    }
}


bool script_start = false;
long TIME_OUT = 2000;
long checkIn;
void loop()
{    
    if (digitalRead(ENDSTOP_X)==1)
    {
      
      Serial.println("emergency stop");    
      instruction = 0;
      script_start = false;
      buff.clear();
      stepper[0].setAcceleration(accelarator*10);
      stepper[0].stop();
      stepper[0].runToPosition();
      stepper[0].setExpectedSpeed(accelarator);
      while  (digitalRead(ENDSTOP_X) == 1)
      {
        stepper[0].runSpeedWithAccel();
      }
      stepper[0].setExpectedSpeed(0);
      stepper[0].stop();
      stepper[0].runToPosition();
      stepper[0].setCurrentPosition(0);
      

      stepper[0].setAcceleration(accelarator);
    }
    static Keyframe currentKeyframe;
    static int propertyIndex = 0;
    static int index = 0;

    static uint8_t readBuffer[sizeof(int)];

    if (Serial.available())
    {
        SerialBT.write(Serial.read());
    }

    if (SerialBT.available() || buff.size()>0)
    {
        if (SerialBT.available())
        {
          buff.push_back(SerialBT.read());
        }
        if (instruction == 0)
        {
            checkIn = millis();
            Serial.println("new Instruction");
            instruction = buff.front();
            Serial.println(instruction);
            buff.pop_front();
        }
        
        switch (instruction)
        {
          //c homing x
        case 99:
        {
               stepper[0].setAcceleration(accelarator);
               stepper[0].setExpectedSpeed(-MAX_SPEED/10);
               while (digitalRead(ENDSTOP_X)==0)
              {
                  stepper[0].runSpeedWithAccel();
              }
              stepper[0].setAcceleration(accelarator*5);
              stepper[0].stop();
              stepper[0].runToPosition();
              stepper[0].setExpectedSpeed(MAX_SPEED/5);
              while  (digitalRead(ENDSTOP_X) == 1)
              {
                stepper[0].runSpeedWithAccel();
              }
              stepper[0].setExpectedSpeed(0);
              stepper[0].setAcceleration(accelarator*5);
              stepper[0].stop();
              stepper[0].runToPosition();
              stepper[0].setCurrentPosition(0);
              stepper[0].setAcceleration(accelarator);

              break;
        }
            // x  position
        case 120:
        {
            readValue(0);
            break;
        }
            // p  pan
        case 112:
        {
            readValue(1);
            break;
        }
        case 116:
        {
            readValue(2);
            break;
        }
        //unlock
        case 117:
        {
          buff.clear();
          Serial.println("unlocked");
          digitalWrite(15,HIGH);
          instruction = 0;
          break;
        }
        //lock
        case 108:
        {
          buff.clear();
          Serial.println("locked");
          digitalWrite(15,LOW);
          for (int i = 0; i<numberOfDim; i++ )
          {
            stepper[i].setCurrentPosition(0);
          }
          instruction = 0;
          break;
        }
        // s send script
        case 115:
        {
            if (!readState)
            {
                Serial.println("about to receive script");
                propertyIndex = 0;
                s = 0;
                cou = 0;
                readState = true;
                keyframeList.clear();
                for (int i = 0; i < numberOfDim; i++)
                 {
                    valueList[i].clear();
                 }
            }
            else
            {
                if (s == 0)
                {
                    Serial.println("reading length...");
                    cou++;
                    if (cou == sizeof(int))
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
                        cou = 0;
                        propertyIndex = 0 ;
                    }
                }
                else
                {
                    static uint8_t dataBuffer[sizeof(double)];
                    cou++;
                    if (cou == sizeof(double))
                    {
                        for (int j = 0; j < sizeof(double); j++)
                        {
                            dataBuffer[j] = buff[0];
                            buff.pop_front();
              

                        }
                        double value = charToDouble(dataBuffer);
                        Serial.print(value);
                        Serial.print(" ");
                        *(((double *)&currentKeyframe) + propertyIndex) = value;
                        propertyIndex++;
                        if (propertyIndex * sizeof(double) == sizeof(currentKeyframe))
                        {
                            keyframeList.push_back(currentKeyframe);
                            
                            Serial.println("reach size");
                            propertyIndex = 0;
                        }
                        cou = 0;
                    }
                    if (keyframeList.size() == s)
                    {
                        Serial.println("done reading data");
                        for (int i = 0; i<numberOfDim; i++)
                        {
                          stepper[i].moveTo((long)((keyframeList[0].value[i]) * valueToPulse[i]));
                          stepper[i].setMaxSpeed(MAX_SPEED);
                        }
                        keyframeToStep();
                        readState = false;
                        instruction = 0;
                        s = 0;
                    }
                }
            }
            break;
        }
        //o stop script
        case 111:
        {
          script_start = false;
          Serial.println("stop slider");
          for (int i = 0; i<numberOfDim;i++)
          {
            stepper[i].setAcceleration(accelarator);
            stepper[i].stop();
          }
          instruction = 0;
          break;
        }
        // i  start script
        case 105:
        {
            buff.clear();
            if (script_start)
            {
              break;
            }
            if (stepper[0].isRunning() || stepper[1].isRunning() || stepper[2].isRunning())
            {
                Serial.println("Slider is not in stop state");
                instruction = 0;
                break;
            }
            if (keyframeList.size() < 2)
            {
                Serial.println("size to small");
                instruction = 0;
            }
            else
            {
                Serial.println("start");
                index = 0;
                script_start = true;
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
         if (script_start || true)
         {
//            for (int i = 0 ; i<1;i++)
//            {
//  //              Serial.print(stepper[i].currentPosition()/valueToPulse[i],6);

//              Serial.print(stepper[i].speed());
//             Serial.print(", ");
//             Serial.print(stepper[i].expectedSpeed());

//            }
//            Serial.println();
          for (int i = 0; i<numberOfDim; i++)
          {
              Serial.print(stepper[i].currentPosition());
               Serial.print(", ");
          }
              Serial.println();
         }
     }
    if (millis() - lastRunRefreshTime >= RUN_REFRESH_INTERVAL)
    {
        lastRunRefreshTime += RUN_REFRESH_INTERVAL;

                

        //                            Serial.print("current pos: ");
        //           Serial.println((double)stepper[0].currentPosition() / valueToPulse[0], 8 );
//             for (int i = 0; i < 3; i++)
//                {
//                    Serial.print("Stepper ");
//                    Serial.print(i);
//                    Serial.print(": ");
//                    Serial.println(stepper[i].currentPosition());
//                }
        if (script_start)
        {
            index++;
            if (index == valueList[0].size())
            {
                for (int i = 0; i < numberOfDim; i++)
                {
                    percentIncrease[i] = 1;
                    stepper[i].setAcceleration(accelarator);
                    stepper[i].moveTo((long)((keyframeList[0].value[i]) * valueToPulse[i]));
                    stepper[i].setMaxSpeed(MAX_SPEED);
                }

                Serial.println("stopping");
                      
                instruction = 0;
                script_start = false;
            }
            else
            {

                long delta[3];
                static long oldSpeedNeeded[3] = {0, 0, 0};
                long distanceToNext[3];
                long speedNeeded[3];

                if (index>1)
                {
                  for (int i = 0; i < numberOfDim; i++)
                  {

                      delta[i] = (stepper[i].currentPosition() - valueList[i][index - 1] * valueToPulse[i]);
                
                      // me   -----> target
                      if (delta[i] < 0)
                      { // delta  ///
                          //  from -------me--------target
                          if (valueList[i][index - 1] - valueList[i][index - 2] > 0)
                          {
                              delta[i] = abs(delta[i]);
                          }
                      }
                      else
                      {
                          // delta  ///
                          //  from ---------------target ---------me
                          if (valueList[i][index - 1] - valueList[i][index - 2] > 0)
                          {
                              delta[i] = -delta[i];
                          } // delta  ///
                      }

                      percentIncrease[i] += (delta[i] * DIFF[i]*dt);
                      if (percentIncrease[i] > 2)
                      {
                          percentIncrease[i] = 2;
                      }
                      if (percentIncrease[i] <0 )
                      {
                          percentIncrease[i] = 0;
                      }
                      oldSpeedNeeded[i] = 0;
                      distanceToNext[i] = (valueList[i][index] * valueToPulse[i] - stepper[i].currentPosition());
                      long dataI = long(distanceToNext[i]/dt);


                      speedNeeded[i] = dataI;

                      speedNeeded[i] *= percentIncrease[i];
                      stepper[i].setExpectedSpeed(speedNeeded[i]);
                      oldSpeedNeeded[i] = speedNeeded[i];
                      
                      double speedToNext = abs(stepper[i].speed()-speedNeeded[i]);
                      speedToNext = speedToNext/dt;
                      if (abs(speedToNext) >accelarator)
                      {
                       stepper[i].setAcceleration(accelarator);
                      }
                      else
                      {
                        stepper[i].setAcceleration(speedToNext);
                      }

                  }
                }
                //                stepper[0].setMaxSpeed(speedNeeded);
                //                stepper[0].setAcceleration(abs((long)(((double)(speedNeeded-oldSpeedNeeded))/dt)));

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

                //                Serial.print("moving to: ");
                //                Serial.println((valueList[0][index]), 8);
                //                Serial.print("current speed: ");
                //                Serial.println(stepper[0].speed());
            }
        }
    }
    if (millis()>checkIn + TIME_OUT)
    {
      if (!script_start)
      {
        buff.clear();
        instruction = 0;
        cou = 0;
        for (int i = 0; i<numberOfDim; i++)
        {
          readStateForDim[i] = false;
        }
      }
    }
    for (int i = 0; i < numberOfDim; i++)
    {
        if (script_start)
        {
            if(stepper[i].runSpeedWithAccel())
            {


            }
        }
        else
        {
            stepper[i].run();
        }
    }
}
