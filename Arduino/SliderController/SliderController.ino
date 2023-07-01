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
AccelStepper stepper[3];

// define parameter
std::vector<Keyframe> keyframeList;
std::vector<std::vector<double>> valueList;
double valueToPulse[3];


long accelarator = 6400;
const unsigned long REFRESH_INTERVAL = 100; // ms
unsigned long lastRefreshTime = 0;
const unsigned long RUN_REFRESH_INTERVAL = 100; // ms
double dt = (double)RUN_REFRESH_INTERVAL / 1000.0;
unsigned long lastRunRefreshTime = 0;
uint8_t instruction;
bool readState;
int s;
int cou = 0;
long MAX_SPEED = 32000;
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

    while (std::abs(x - xNeedEqual) > 0.002)
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

    for (int k = 0; k < 3; k++)
    {
        velocity.push_back({0.0});

        Serial.println("start processing");
        Serial.println("calculating velocity for ");
        Serial.println(k);

        for (int i = 1; i < keyframeList.size() - 1; i++)
        {
            double time1 = keyframeList.at(i - 1).time;
            double time2 = keyframeList.at(i).time;
            double pos1 = keyframeList.at(i - 1).value[k];
            double pos2 = keyframeList.at(i).value[k];
            velocity[k].push_back((pos2 - pos1) / (time2 - time1));
        }
        velocity[k].push_back(0.0);

        Serial.println("dividing keyframe");
        for (int i = 0; i < keyframeList.size() - 1; i++)
        {
            Serial.println(i);
            double time1 = keyframeList.at(i).time;
            double time2 = keyframeList.at(i + 1).time;
            double pos1 = keyframeList.at(i).value[k];
            double pos2 = keyframeList.at(i + 1).value[k];
            Serial.println("ingoing and outgoing");
            double outgoing = keyframeList.at(i).outgoing / 100;
            double ingoing = keyframeList.at(i + 1).ingoing / 100;

            Serial.print("point ");
            Point p[4];
            p[0].x = time1;
            p[0].y = pos1;

            p[1].x = time1 + (time2 - time1) * outgoing;
            ;
            p[1].y = pos1 - velocity[k][i] * (time2 - time1) * outgoing;
            ;

            p[2].x = time2 - (time2 - time1) * ingoing;
            ;
            p[2].y = pos2 + velocity[k][i + 1] * (time2 - time1) * ingoing;
            ;

            p[3].x = time2;
            p[3].y = pos2;

            Serial.println("dividing");
            for (double j = time1; j < time2; j += dt)
            {

                double result = bezierYfromTime(p[0], p[1], p[2], p[3], (j - time1) / (time2 - time1));
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
    pinMode(15,OUTPUT);
    digitalWrite(15, LOW);
    for (int i = 0; i < 3; i++)
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
        for (int i = 0; i < 3; i++)
    {
      if (i>0)
      {
        DIFF[i] = 1 / valueToPulse[i]/360;
      }
      else
        DIFF[i] = 1 / valueToPulse[i];
        
    }
    instruction = 0;
    readState = false;
}

void readValue(int dimension)
{
    static bool readStateForDim[3] = {false, false, false};
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
            stepper[dimension].setMaxSpeed(stepper[dimension].currentPosition() - (long)(value * valueToPulse[dimension]));
            cou = 0;
            readStateForDim[dimension] = false;
            instruction = 0;
        }
    }
}


bool script_start = false;

void loop()
{    

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
            Serial.println("new Instruction");
            instruction = buff.front();
            Serial.println(instruction);
            buff.pop_front();
        }
        
        switch (instruction)
        {
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
                for (int i = 0; i < 3; i++)
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
                        for (int i = 0; i<3; i++)
                        {
                          stepper[i].moveTo((long)((keyframeList[0].value[i]) * valueToPulse[i]));
                          stepper[i].setMaxSpeed(valueToPulse[0]);
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
        // i  start script
        case 105:
        {
            if (script_start)
            {
              break;
            }
            if (stepper[0].isRunning() || stepper[1].isRunning() || stepper[2].isRunning())
            {
              Serial.println("Slider is not in stop state");
                break;
            }
            if (keyframeList.size() < 2)
            {
                Serial.println("size to small");
            }
            else
            {
                Serial.println("start");
                index = 0;
                script_start = true;

                
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
                for (int i = 0; i < 3; i++)
                {
                    percentIncrease[i] = 1;
                    stepper[i].moveTo((long)((keyframeList[0].value[i]) * valueToPulse[i]));
                    stepper[i].setMaxSpeed(accelarator);
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
                  for (int i = 0; i < 3; i++)
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

                      percentIncrease[i] += (delta[i] * DIFF[i]);
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

                      speedNeeded[i] = (long)(((double)distanceToNext[i]) / dt);
                      if (distanceToNext[i]<0)
                      {
                        speedNeeded[i] = -abs(speedNeeded[i]);
                      }
                      speedNeeded[i] *= percentIncrease[i];
                      stepper[i].setSpeed(speedNeeded[i]);
                      for (int i = 0; i < 3; i++)
                      {
                          oldSpeedNeeded[i] = speedNeeded[i];
                      }
                      for (int i = 0; i < 3; i++)
                      {
                          Serial.print((double)stepper[i].currentPosition() / valueToPulse[i], 8);
                          Serial.print(", ");
                      }
                      Serial.println();
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
    for (int i = 0; i < 3; i++)
    {
        if (script_start)
        {
            stepper[i].runSpeed();
        }
        else
        {
            stepper[i].run();
        }
    }
}
