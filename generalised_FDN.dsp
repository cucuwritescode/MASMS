declare name 		"Switchable Diffusivity Feedback Delay Network";
declare version 	"1.0";
declare author 		"Facundo Franchino";

import("stdfaust.lib");

//controls

//mode 0 = standard fdn (metallic)
//mode 1 = allpass fdn (lush)
mode = hslider("engine mode [style:radio{'standard':0;'allpass':1}]", 0, 0, 1, 1) : int;

t60 = hslider("decay t60 [unit:s]", 2.0, 0.1, 10.0, 0.1);
damp = hslider("hf damping [0-1]", 0.4, 0, 0.9, 0.01);

wet = hslider("dry/wet", 0.5, 0, 1, 0.01);

//modulation (only for mode 1)
modSpeed = hslider("mod speed [hz]", 0.5, 0.01, 5.0, 0.01);
modDepth = hslider("mod depth [samp]", 10, 0, 50, 0.1);


//helper functions

//air absorption filter
op(g) = _ : (+ : _ * (1-g)) ~ * (g);

//lossless matrix
hadamard(2) = si.bus(2) <: +, -;
hadamard(4) = par(i, 2, hadamard(2)) : ro.interleave(2,2) : par(i, 2, hadamard(2));

//large hall primes (150ms-260ms approx)
prime(0) = 7919;
prime(1) = 8819;
prime(2) = 10201;
prime(3) = 11549;


//generalised branch

generalisedBranch(idx) = _ <: ba.selectn(2, mode, pathDelay, pathAllpass) : _
with {
    N = prime(idx);
    
    //mode 0, static integer delay
    pathDelay = _@N;
    
    //mode 1, modulated allpass
    lfo = os.osc(modSpeed) * modDepth;
    pathAllpass = (+ <: (de.fdelay(65536, N-1+lfo), *(0.5))) ~ *(-0.5) : mem, _ : +;
};


//main fdn

fdn = (inputPath : opPath : branchPath : hadamardPath : normHadamard : decay) ~ si.bus(4) : delCompensation
with{
    inputPath = ro.interleave(4, 2) : par(i, 4, (_, _) :> _);
    
    opPath = par(i, 4, op(damp));
    
    branchPath = par(i, 4, generalisedBranch(i));
    
    hadamardPath = hadamard(4);
    normHadamard = par(i, 4, _ * 0.5);
    
    //t60 calculation based on delay length
    g(i) = pow(0.001, (prime(i)/ma.SR) / t60); 
    decay = par(i, 4, *(g(i)));
            
    delCompensation = par(i, 4, mem);
};

stereoToQuad = _,_ <: _,_,_,_;

process = _,_ <: (*(1-wet), *(1-wet)), (stereoToQuad : fdn :> _,_ : *(wet), *(wet)) :> _,_;