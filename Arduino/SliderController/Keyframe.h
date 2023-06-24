#pragma once
class Keyframe
{
public:
    double time;
    double position;
    double focal;
    double pan;
    double tilt;
    double ingoing;
    double outgoing;
    Keyframe();
    Keyframe(double newTime, double newPosition, double newFocal
    , double newPan, double newTilt, double newIngoing, double newOutgoing);
    ~Keyframe();
};
Keyframe::Keyframe()
{
    time = 0;
    position = 0;
    focal = 0;
    pan = 0;
    tilt = 0;
    ingoing = 0;
    outgoing = 0;
}
Keyframe::Keyframe(double newTime, double newPosition, double newFocal
    , double newPan, double newTilt, double newIngoing, double newOutgoing)
{
    time = newTime;
    position = newPosition;
    focal = newFocal;
    pan = newPan;
    tilt = newTilt;
    ingoing = newIngoing;
    outgoing = newOutgoing;
}

Keyframe::~Keyframe()
{
}
