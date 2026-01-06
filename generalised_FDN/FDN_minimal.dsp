import("stdfaust.lib");

op(g) = _ : (+ : _ * (1-g)) ~ * (g);

hadamard(2) = si.bus(2) <: +, -;
hadamard(4) = par(i, 2, hadamard(2)) : ro.interleave(2,2) : par(i, 2, hadamard(2));

fb = hslider("Feedback", 0.5, 0, 0.99, 0.01);
wet = hslider("Dry/Wet", 0.5, 0, 1, 0.01);

fdn = (inputPath : opPath : delaysPath : hadamardPath : normHadamard : decay) ~ si.bus(4) : delCompensation
with{
    inputPath = ro.interleave(4, 2) : par(i, 4, (_, _) :> _);
    opPath = par(i, 4, op(0.4));
    delaysPath = _@3263, _@3695, _@4319, _@4751;
    hadamardPath = hadamard(4);
    normHadamard = par(i, 4, _ * 0.5);
    decay = par(i, 4, *(fb));
    delCompensation = par(i, 4, mem);
};

stereoToQuad = _,_ <: _,_,_,_;

process = _,_ <: (*(1-wet), *(1-wet)), (stereoToQuad : fdn :> _,_ : *(wet), *(wet)) :> _,_;