declare name 		"A Generalised Feedback Delay Network";
declare version 	"1.0";
declare author 		"Facundo Franchino";

import("stdfaust.lib");
//controls

//"research" switcgh
// 0 = standard FDN (clean delays),good for "ringing" analysis
// 1 = allpass FDN (K.Barr style),good for "density" analysis
mode = hslider("Engine Mode [style:radio{'Standard':0;'Allpass':1}]", 0, 0, 1, 1) : int;

fb = hslider("Feedback", 0.5, 0, 0.99, 0.01);
wet = hslider("Dry/Wet", 0.5, 0, 1, 0.01);

//modulation controls (only active in allpass mode)
modSpeed = hslider("Mod Speed", 0.2, 0.01, 5.0, 0.01);
modDepth = hslider("Mod Depth", 10, 0, 50, 0.1);


//helper functions

op(g) = _ : (+ : _ * (1-g)) ~ * (g);

hadamard(2) = si.bus(2) <: +, -;
hadamard(4) = par(i, 2, hadamard(2)) : ro.interleave(2,2) : par(i, 2, hadamard(2));

//hardcoded prime delays (approx 68ms-99ms)
prime(0) = 3263; prime(1) = 3695; prime(2) = 4319; prime(3) = 4751;


//generalised branch

generalisedBranch(idx) = _ <: ba.selectn(2, mode, pathDelay, pathAllpass) : _
with {
    N = prime(idx);
    
    // mode 0, standard delay
    pathDelay = _@N;
    
    //mode 1. modulated allpass
    //this is the "Keith Barr" smear technique
    lfo = os.osc(modSpeed) * modDepth;
    pathAllpass = (+ <: (de.fdelay(65536, N-1+lfo), *(0.5))) ~ *(-0.5) : mem, _ : +;
};


//main FDN

fdn = (inputPath : opPath : branchPath : hadamardPath : normHadamard : decay) ~ si.bus(4) : delCompensation
with{
    inputPath = ro.interleave(4, 2) : par(i, 4, (_, _) :> _);
    
    opPath = par(i, 4, op(0.4));
    
    //now use the 'generalisedBranch' instead of simple delays
    branchPath = par(i, 4, generalisedBranch(i));
    
    hadamardPath = hadamard(4);
    
    normHadamard = par(i, 4, _ * 0.5);
    
    decay = par(i, 4, *(fb));
            
    delCompensation = par(i, 4, mem);
};

stereoToQuad = _,_ <: _,_,_,_;

process = _,_ <: (*(1-wet), *(1-wet)), (stereoToQuad : fdn :> _,_ : *(wet), *(wet)) :> _,_;