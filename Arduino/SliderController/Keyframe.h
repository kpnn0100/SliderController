#pragma once
class Keyframe
{
public:
    double time;
    //position pan tilt focal
    double value[4];
    double ingoing;
    double outgoing;
    Keyframe();
    Keyframe(double newTime, double newPosition
    , double newPan, double newTilt, double newFocal, double newIngoing, double newOutgoing);
    ~Keyframe();
};
Keyframe::Keyframe()
{
    time = 0;
    value[0] = 0;
    value[1] = 0;
    value[2] = 0;
    value[3] = 0;
    ingoing = 0;
    outgoing = 0;
}
Keyframe::Keyframe(double newTime, double newPosition, double newPan 
    , double newTilt , double  newFocal, double newIngoing, double newOutgoing)
{
    time = newTime;
    value[0]  = newPosition;
    value[1]  = newPan;
    value[2]  = newTilt;
    value[3]  = newFocal;
    ingoing = newIngoing;
    outgoing = newOutgoing;
}

Keyframe::~Keyframe()
{
}
