declare name 		"Switchable Diffusivity Feedback Delay Network";
declare version 	"1.1";
declare author 		"Facundo Franchino";

import("stdfaust.lib");

//controls

//mode 0 = standard fdn (metallic)
//mode 1 = allpass fdn (lush)
mode = hslider("engine mode [style:radio{'standard':0;'allpass':1}]", 0, 0, 1, 1) : int;

t60 = hslider("decay t60 [unit:s]", 2.0, 0.1, 10.0, 0.1);
damp = hslider("hf damping [0-1]", 0.45, 0, 0.9, 0.01);

wet = hslider("dry/wet", 0.5, 0, 1, 0.01);

//modulation (tuned lower for vocals)
modSpeed = hslider("mod speed [hz]", 0.2, 0.01, 5.0, 0.01);
modDepth = hslider("mod depth [samp]", 4, 0, 50, 0.1);


//helper functions

//air absorption filter
op(g) = _ : (+ : _ * (1-g)) ~ * (g);

//input diffusion (tuned for smoother onset)
diffuser = allpass(1021) : allpass(1361)
with {
    allpass(N) = (+ <: (de.delay(2048, N), *(-0.5))) ~ *(0.5) : mem, _ : +;
};

//lossless matrix
hadamard(2) = si.bus(2) <: +, -;
hadamard(4) = par(i, 2, hadamard(2)) : ro.interleave(2,2) : par(i, 2, hadamard(2));

//medium hall primes
prime(0) = 4001;
prime(1) = 4799;
prime(2) = 5647;
prime(3) = 6521;


//generalised branch

generalisedBranch(idx) = _ <: ba.selectn(2, mode, pathDelay, pathAllpass) : _
with {
    N = prime(idx);
    
    //mode 0, static integer delay
    pathDelay = _@N;
    
    //mode 1, modulated allpass
    //removed the 1.5x boost to fix vocal "warble"
    speedOffset = modSpeed + (idx * 0.11);
    lfo = os.osc(speedOffset) * modDepth;
    
    //reduced feedback slightly (0.55) to reduce metallic resonance on vocals
    pathAllpass = (+ <: (de.fdelay(65536, N-1+lfo), *(0.55))) ~ *(-0.55) : mem, _ : +;
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

//added diffuser to wet path
process = _,_ <: (*(1-wet), *(1-wet)), (stereoToQuad : par(i, 4, diffuser) : fdn :> _,_ : *(wet), *(wet)) :> _,_;