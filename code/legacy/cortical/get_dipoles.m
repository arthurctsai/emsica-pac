% get_dipoles() This function is called by get_dipoles(), check_layers(), get_dipoles_warping_5layers()
%
% get_dipoles()
% This function is called by get_dipoles(), check_layers(), get_dipoles_warping_5layers()

% to get the dipole of mesh of dipoles 
% the size of the mesh corresponds to L obtained from L=get_lfm()
% see
% http://emsica.art/cortical/get_dipoles
%  
% 20121027 vincent
% originally this is get_mesh_dip_dec.m or get_smoothwmreducedmesh.m
% 2021-06-17 arthur reorganize this probram
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function [cortical, subcortical, combined, corticaldipmatfile, subcorticaldipmatfile] = get_dipoles(s,varargin)
  s=get_info(s);
  defaultsetting = {...
    %  name       type       range  default
    'meshspace',  'string',  '',    'both';...   % 'cortical'|'subcortical'|'both'
    'reducemesh', 'integer', [],    s.reducemesh;... % 'on' | 'off' -> after gparser, it becomes 0 | 1
    }; 

[g, s] = gparser(s, varargin, defaultsetting); ff = fieldnames(g);
for i = 1:length(ff), eval([ff{i} '=getfield(g,''' ff{i}  ''');']); end % flatten parameters
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

combined.mesh.faces=[];
combined.mesh.vertices=[];
combined.idx=[];
combined.name={};

cortical.mesh.faces=[];
cortical.mesh.vertices=[];
cortical.idx=[];
cortical.name={};

subcortical.mesh.faces=[];
subcortical.mesh.vertices=[];
subcortical.idx=[];
subcortical.name={};

corticaldipmatfile = '';
subcorticaldipmatfile = '';

if isempty(meshspace)
  if strcmp(s.subcortical, 'on')
    meshspace='both';
  else
    meshspace='cortical';
  end
end


%% ==== cortical ====
if strcmp(meshspace,'cortical') || strcmp(meshspace,'both')

% Retrieve cortical dipoles and associated mesh data
  [smoothwmreducedmesh, dipoles, idxnongraymatter, corticaldipmatfile] = get_dipoles_cortical(s, 'reducemesh',reducemesh); % **

  % Assign mesh and label properties to the cortical structure
  cortical.mesh.vertices = smoothwmreducedmesh.vertices;
  cortical.mesh.faces = smoothwmreducedmesh.faces;
  try
    cortical.name = smoothwmreducedmesh.segmentLabel;
    cortical.idx= smoothwmreducedmesh.verticesIdx;
    cortical.idxnongraymatter = idxnongraymatter; 
  catch
    mdisp('red', ['Warning: There is no segmentation information.']);
  end
end


%% ==== Subcortical ====
if strcmp(meshspace, 'subcortical') || strcmp(meshspace, 'both')
  % Retrieve subcortical dipoles
  [subcortical_dipoles, ~, subcorticaldipmatfile] = get_dipoles_subcortical(s, 'plotmore',0, 'reducemesh', reducemesh);
  subcortical = subcortical_dipoles; 
  % then, subcortical_dipoles.lThalamus,,, will be asigned to subcortical which is necessary for get_lap()

  % Assign relevant properties from subcortical dipoles
  subcortical.mesh.vertices = subcortical_dipoles.vertices;
  subcortical.mesh.faces = subcortical_dipoles.faces;
  subcortical.name = subcortical_dipoles.segmentLabel;
  subcortical.idx = subcortical_dipoles.verticesIdx;
end


%% ==== combine cortical and subcortical ====
if strcmp(meshspace,'both') 
  combined=[];
  combined.mesh.vertices = [cortical.mesh.vertices ; subcortical.mesh.vertices];
  combined.mesh.faces = [cortical.mesh.faces; subcortical.mesh.faces+length(cortical.mesh.vertices)];
  combined.name=[cortical.name;subcortical.name];
  combined.idx=[cortical.idx; subcortical.idx+cortical.idx(end)];
  combined.idxnongraymatter=cortical.idxnongraymatter;
end









