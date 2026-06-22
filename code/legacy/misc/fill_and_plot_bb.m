% fill_and_plot_bb() which calls plot_b() and is good for debug.
%
%% =============================================================================
%% fill_and_plot_bb() which calls plot_b() and is good for debug.
%% =============================================================================
% good! a very useful function. by arthur 2021-07-22
% Usages:
% get_LB0A0_by_sphx():387:>fill_and_plot_bb():713:>plot_b():213:>draw_comp()
% get_lap():387:>fill_and_plot_bb():713:>plot_b():213:>draw_comp()
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function BBfilled = fill_and_plot_bb(s, emsicafolder, BB, rmIndices, reorderIdx, titlestr, returnBBonly)
  if nargin<=5
    titlestr='comp'; % titlestr = eg. 'invL-sLORETA'
  end;

  if nargin<=6
    returnBBonly=0;
  end;
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

  % BB should be a square matrix like B matrix
  [JJ, KK] = size(BB); if JJ<KK, BB=BB'; end

  % zscore on BB
  [BB,mu,sigma] = zscore(BB);

  %% ==============================================
  %% the broken hole on BB is filled with zero
  %% ==============================================
  % -arthur 2021-07-27
  [cortex, ~, combined] = get_dipoles(s,'meshspace','both');
  Jc=length(cortex.mesh.vertices);% Jc, the index of cortex in B
  J=length(combined.mesh.vertices);

  if JJ==J, BBfilled = BB; end;

  if JJ<J
    % rkffabcd 2021-09-3 
    BBfilled = zeros(J,KK);
    %keyboard
    reorderIdx(rmIndices) = [];
    
    % [~,idx] = sort(reorderIdx);
    % >> reorderIdx = [3 7 5]; 
    % >> [a,idx]=sort(X)
    % ans: a =
    %     3     5     7
    % idx =
    %     1     3     2

    BBfilled(reorderIdx,:)=BB;
  end

% not to plot by bb, just return BB for eg. SigmainvB0
  if returnBBonly, return; end;

  corticalB = BBfilled(1:Jc,:);
  subcorticalB = BBfilled(Jc+1:end,:);

  % Before you use get_allb() 
   % BBB = get_allb(s, 'corticalB', corticalB, 'subcorticalB', subcorticalB, 'onavgbrain',0, 'reducemesh',1);
   % to get BBB.B, BBB.Bdeep

   % Here we already have them by
   BBB.B = corticalB;
   BBB.Bdeep=subcorticalB;

  % plot by plot_b() by passing s.B to it
  s.B = BBB;
  if KK>8,
    KK=8;
  end
  plot_b(s, 'emsicafolder',emsicafolder, 'titlestr', titlestr,'visible','off', 'index', [1:KK]); % plot all components

  % set background to original to prevent further plotting color problem
  whitebg([1 1 1]);

