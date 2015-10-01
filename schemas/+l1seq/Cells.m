%{
l1seq.Cells (manual) # info about each cell for L1 interneuron sequencing

->l1seq.Experiments
tube_num            : tinyint               # PCR tube number from that date
---
cell_num            : tinyint                # cell number within this experiment
sandberg_num=null        : tinyint               # Sandberg Lab's assigned sample number
type="unknown"      : enum('1','2','3','4','5','unknown')  # 1=defnitelye NGC, 2=likely eNGC, 3=could be eNGC or SBC, 4=likely SBC, 5=definitely SBC
input_res=null      : float               # input resistance
vrest=null          : float               # resting membrane potential
tau=null            : float               # membrane time constant in response to hyperpolarizing current
ls="unknown"             : enum('Yes','No','unknown')               # whether or not cell is late-spiking
latency=null        : float               # latency to first spike
bs="unknown"             : enum('Yes','No','unknown')               # whether or not cell is burst spiking
ahp="unknown"             : enum('Yes','No','unknown')             # whether or not cell has an after-hyperpolarization
adp="unknown"             : enum('Yes','No','unknown')               # whether or not cell has an after-depolarization
ap_amp=null         : float               # AP amplitude (mV)
ap_thresh=null      : float               # AP threshold (mV)
ap_hwhm=null        : float               # AP half width at half maximum
cell_notes=""       : varchar(4096)                                  #other comments about the cell
cell_ts=CURRENT_TIMESTAMP : timestamp                                # automatic
%}



classdef Cells< dj.Relvar

	properties(Constant)
		table = dj.Table('l1seq.Cells')
	end

	methods
		function self = Experiments(varargin)
			self.restrict(varargin)
        end
        function makeTuples(self,key)
            self.insert(key)
        end
	end
end
