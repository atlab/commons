%{
reso.BeadStack (manual) # stacks with beads for PSF computations
date            : date                  # acquisition date
stack_num       : smallint              # stack number for that day
---
who                         : varchar(63)                   # who acquired the data
setup=2                     : smallint                      # which two-photon setup
lens                        : decimal(5,2)                  # lens magnification
na                          : decimal(3,2)                  # numerical aperture of the objective lens
fov_x                       : float                         # (um) field of view at selected magnification
fov_y                       : float                         # (um) field of view at selected magnification
wavelength                  : smallint                      # (nm) laser wavelength
path                        : varchar(1023)                 # file path
filename                    : varchar(255)                  # file name
note=""                     : varchar(1023)                 # any other information
mwatts=0.0                  : decimal(3,1)                  # mwatts out of objective
%}

classdef BeadStack < dj.Relvar
    
    properties(Constant)
        table = dj.Table('reso.BeadStack')
    end
    
end
