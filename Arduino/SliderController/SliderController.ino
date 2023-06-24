#include "BluetoothSerial.h"
#include <AccelStepper.h>
#include <cstring>
#include <vector>
#include "CircularList.h"
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
AccelStepper xStepper(1, 0, 15);
AccelStepper panStepper(1, 14, 27);
AccelStepper tiltStepper(1, 4, 16);
// define parameter
std::vector<double> pos;
double pulseToMili = 16 / 3200;
double meterToPulse = 3200 / 16 * 1000;
double panToPulse = 3200 / 360;
long maxXSpeed = 0.5 * meterToPulse;
long accelarator = 25600;
long distanceToSpeed(long current, long target)
{
    int delta = target - current;
    if (delta < maxXSpeed)
        return delta;
    return maxXSpeed;
}
uint8_t instruction;
bool readState;
int s;

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
        case 115:
        {
            if (!readState)
            {
                Serial.println("about to receive script");

                s = 0;
                count = 0;
                readState = true;
                pos.clear();
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
                        pos.push_back(value);
                        Serial.print("size of pos :");
                        Serial.println(pos.size());
                        Serial.print(pos.back());
                        Serial.print(" ");
                        Serial.println();
                        if (pos.size() == s)
                        {
                            Serial.println("done reading data");
                            xStepper.moveTo((long)((pos[0]) * meterToPulse));
                            instruction = 0;
                            s = 0;
                        }
                        count = 0;
                    }
                }
            }
            break;
        }
        case 105:
        {
            if (pos.size() < 2)
            {
                instruction = 0;
            }
            else
            {
                index = 0;
                script_start = true;
                Serial.println("start");
                xStepper.setRunWithoutStop(true);
            }
            break;
        }
        default:
        {
            instruction = 0;
        }
        }
    }
    static const unsigned long REFRESH_INTERVAL = 100; // ms
    static unsigned long lastRefreshTime = 0;
    static double dt = 0.1;
    static const unsigned long RUN_REFRESH_INTERVAL = 100; // ms
    static unsigned long lastRunRefreshTime = 0;

    if (millis() - lastRefreshTime >= REFRESH_INTERVAL)
    {
        lastRefreshTime += REFRESH_INTERVAL;
        Serial.print("current pos: ");
        Serial.println(xStepper.currentPosition() / meterToPulse);
    }
        static double percentIncrease = 1.0;
        static double const DIFF = 2 / meterToPulse;

        if (millis() - lastRunRefreshTime >= RUN_REFRESH_INTERVAL)
        {
            lastRunRefreshTime += RUN_REFRESH_INTERVAL;
                if (script_start)
    {
            index++;
            if (index == pos.size())
            {
                xStepper.setRunWithoutStop(false);
                script_start = false;
            }
            else
            {
                long delta = pos[index - 1] * meterToPulse - xStepper.currentPosition();
                percentIncrease += delta * DIFF;
                if (percentIncrease > 4)
                {
                  percentIncrease = 4;
                }
                long distanceToNext = (pos[index] - pos[index - 1]) * meterToPulse;
                long speedNeeded = (long)(((double)distanceToNext) / dt);
                speedNeeded *= percentIncrease;
                speedNeeded = abs(speedNeeded);
                Serial.print("current speed percent: ");
                Serial.println(percentIncrease);
                xStepper.stop();
                xStepper.moveTo((long)((pos[index]) * meterToPulse));
                xStepper.setMaxSpeed(speedNeeded);
                Serial.print("new Max speed: ");
                Serial.println(speedNeeded);
                Serial.print("moving to: ");
                Serial.println((pos[index]));
                Serial.print("current speed: ");
                Serial.println(xStepper.speed());
            }
        }
    }
    xStepper.run();
    panStepper.run();
}
