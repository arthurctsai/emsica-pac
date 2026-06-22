% gen_dummy_idx() 2022-10-12
%
% 2022-10-12
% generate an dummy eg. 3ica/ICs/idx.txt
% this function is called by channels_(), get_topo()
% 2024-05-1 arthur
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function txtfile = gen_dummy_idx(s, nbchan, targetdir)
s = get_info(s);

if nargin<3
    mymd(s.channelsCHsDir);
    cd(s.channelsCHsDir);
else
    mymd(targetdir);
    cd(targetdir);
end
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

%
%% ==========================================================
%% generate idx.txt
%% ==========================================================

txtfile = [mypwd 'idx.txt'];
if ~exist(txtfile,'file')
    fid = fopen(txtfile,'w+');
    for i= 1:nbchan
        fprintf(fid,['1 ' sprintf('%d',i) ' #\n']);
    end
    fclose(fid);
    mdisp([txtfile ' is generated.']);
end

