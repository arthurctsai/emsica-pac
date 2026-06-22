% eeg_checkicaact() Arthur C. Tsai arthur@stat.sinica.edu.tw
%
% usage:
% EEG=eeg_checkicaact(EEG); % to make EEG.icaact
% 2020-12-15
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function EEG = eeg_checkicaact(EEG, recompute);
if nargin < 2
    recompute = 0; % default
end
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

if size(EEG.icaact,1) ~= size(EEG.icawinv,2)
    recompute = 1;
end


%
if recompute || length(EEG.icaact)==0,
  w=EEG.icaweights*EEG.icasphere;
  EEG.icaact=w*EEG.data(EEG.icachansind,:);  
  EEG.icaact = reshape(EEG.icaact,size(w,1),EEG.pnts,EEG.trials);
end;
