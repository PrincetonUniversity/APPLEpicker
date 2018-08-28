### APPLE Picker

This is the MATLAB version. Check out the 
[Python version](https://github.com/PrincetonUniversity/APPLEpicker-python)
of the project.

Also make sure to [subscribe](http://eepurl.com/dFmFfn) to our important updates, tips and tricks about APPLE Picker.

This package contains an implementation of the APPLE particle picker as
described in the paper

A. Heimowitz, J. Anden, and A. Singer, "APPLE Picker: Automatic Particle
Picking, a Low-Effort Cryo-EM Framework," https://arxiv.org/abs/1802.00469 .

To get started, run the following commands in MATLAB

    setup;
    getParticles;

This will automatically download two datasets of micrograph and run the APPLE
picker on them. The implementation requires the Image Processing Toolbox to be
installed. For best performance, it is recommended to run this on a GPU using
the Distributed Computing Toolbox.
