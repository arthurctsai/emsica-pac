% get_dipoles_cortical() This function is called by get_dipoles(), runbem()
%
% This function is called by get_dipoles(), runbem()
% get_dipoles() > get_dipoles_cortical(), get_dipoles_subcortical()
%
% get_dipoles_cortical()
% Output:
%   * For subjects with MRI, this get_dipoles_cortical() will generate dipmatfile
%     i.e., 5lfm/dipoles_cortical.mat or dipoles_cortical_reduced.mat (depend on s.reducemesh)
%     inside 5lfm/dipoles_cortical.mat there are smoothwm, smoothwmreducedmesh, vertNormals, vertNormalsUnit, idxnongraymatter, mesh_dip_dec
%
%   * For subjects without MRI, this get_dipoles_cortical() will call get_dipoles_warping_5layers() to generate output dipmatfile == 5lfm/dipoles_cortical_reduced_warped.mat
%     mesh_dip_dec is meshe before warping
%     smoothwmreducedmesh is meshe after warping
%     idxnongraymatter is the idx of gray matters with thickness == 0
% See http://emsica.art/cortical/plot_l_issue_on_mni_warped_subjects

%  2014-07-6 arthur reorganize and make it more general purpose
% initiated by Frank Chang
% 2024-08-14 plotmore on by rkffabcd & arthur
% See also, get_dipoles_subcortical, get_itp_cortical
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function [smoothwmreducedmesh, dipoles, idxnongraymatter, dipmatfile, mesh_dip_dec, idx] = get_dipoles_cortical(s, varargin)
  s = get_info(s);
  defaultsetting = {...
    % name          type       range default
    'recompute',    'string',  [],   'off';... % 'on' | 'off'
    'reducemesh',   'integer', [],   s.reducemesh ;... % 'on' | 'off'
    'plotmore',     'real',    [],   0;... 
    'logging',      'string',  [],   'off';...
    };

[g, s] = gparser(s, varargin, defaultsetting); ff = fieldnames(g);
for i = 1:length(ff), eval([ff{i} '=getfield(g,''' ff{i}  ''');']); end % flatten parameters

mymd(s.lfmDir); cd(s.lfmDir);
if strcmp(logging,'on')
  logfid = fopen([s.lfmDir 'L/log.txt'],'a');
else
  logfid=[];
end
mesh_dip_dec = [];% default. after you loaded dipoles_cortical_reduced_warped.mat it will be asigned
smoothwmreducedmesh = [];
dipoles =[];
idxnongraymatter = [];
dipmatfile = [];
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

%% tentative code - you hve the same code in get_dipoles_warping_5layers()
% to rename lfm_cortical_dip_reduced.mat to dipoles_cortical_reduced.mat
% 2025-01-7 arthur @UCSD
% Define the old and new file names
oldFiles = {'lfm_cortical_dip_reduced.mat', 'lfm_cortical_dip.mat', 'lfm_subcortical_dip_reduced.mat', 'lfm_subcortical_dip.mat', 'lfm_cortical_dip_reduced_warped.mat', 'lfm_subcortical_dip_reduced_warped.mat'};
newFiles = {'dipoles_cortical_reduced.mat', 'dipoles_cortical.mat', 'dipoles_subcortical_reduced.mat', 'dipoles_subcortical.mat', 'dipoles_cortical_reduced_warped.mat', 'dipoles_subcortical_reduced_warped.mat'};

% Loop through both cases
for i = 1:length(oldFiles)
    oldFile = [s.lfmDir oldFiles{i}];
    newFile = [s.lfmDir newFiles{i}];

    % Check if the old file exists
    if isfile(oldFile)
        % Rename the file
        movefile(oldFile, newFile);
        mdisp('yellow', ['Renamed ' mypath(oldFile) ' to ' mypath(newFile)]);
    end
end

%% for subjects without MRI
if ~hasmri(s) && ~strcmpi(s.subject,'.colin27') && ~contains(s.subject,'7raicar') % if subject has no mri
  % Note, despite reducemesh, for subject without mri, since we call get_dipoles_warping_5layers()
  % to get mesh which is always mesh with reduction.

  [smoothwmreducedmesh, dipoles, idxnongraymatter, dipmatfile, mesh_dip_dec, idx] = get_dipoles_warping_5layers(s, 'toget','cortical');

  if plotmore
    mesh = smoothwmreducedmesh;
    figure;
    V=smoothwmreducedmesh.vertices; F=smoothwmreducedmesh.faces; figure; trisurf(F, V(:,1), V(:,2), V(:,3));
    axis equal; title('smoothwmreducedmesh');
    vis;

    % ~/1_zen/zm32/5lfm/corticalmeshes0.png
    pngfilename = mypath([s.lfmDir 'corticalmeshes0.png']);
    print('-dpng',pngfilename);  % close;
    mdisp([pngfilename ' is printed.']);
    set(gcf,'visible','on');
  end

  if plotmore
    meshs = cell(1,5);
    meshs{1} = 1;
    meshs{2} = 'all';
    meshs{3} = [122 186 220 0];
    meshs{1,4}=smoothwmreducedmesh.vertices(:,1:3);
    meshs{1,5}=smoothwmreducedmesh.faces(:,1:3);
    mydraw(s,'scalp-cortical', meshs, 1); % without scalp
    mydraw(s,'scalp-cortical', meshs, 2); % with scalp
  end

  return
end % if subject has no mri

%% for subjects with MRI
if hasmri(s) || strcmpi(s.subject,'.colin27') || contains(s.subject,'7raicar')
  % define dipmatfile
  if reducemesh % for EEG, the dipoles you get usually reducemesh=1
    dipmatfile = [s.lfmDir 'dipoles_cortical_reduced.mat'];
  else
    dipmatfile = [s.lfmDir 'dipoles_cortical.mat'];
  end

  surffile = [s.surfDir 'lh.smoothwm'];
  % since we use surffile to compute dipmatfile,
  % so if dipmatfile is older than surffile, recompute it.
  portable_cached = ~isempty(getenv('EMSICA_PAC_ROOT')) && isfile(dipmatfile);
  if portable_cached
    recompute = 0;
  else
    recompute = checkrecompute(recompute, dipmatfile, surffile); % if dipmatfile is newer than surf/lh.smoothm, good! recompute=0!
  end
  if recompute
    %mdisp(['Here is going to recompute ' mypath(dipmatfile) '!! check it out!!']);
    %keyboard
    myrm(dipmatfile);
  end

  if ~recompute
    load(dipmatfile);
    mdisp(['...loading ' mypath(dipmatfile)]);

    % workaround for 2esspfmriyear1 study 2024-05-11
    if exist('smoothwmreduced','var')
      smoothwmreducedmesh = smoothwmreduced;
    end

    dipoles = [smoothwmreducedmesh.vertices/1000 vertNormalsUnit];

    if strcmp(plotmore,'off')
      return;
    end
  end
end

%% ==== for subjects with MRI, recompute dipoles_cortical.mat / dipoles_cortical_reduced.mat =========
if recompute
    logprintf(logfid,'\n-------------------------------\n %s %s\n------------------------------\n',['::' mfilename() ':'],[s.subject ', ' datestr(now, 'mmm dd, yyyy | HH:MM:SS')]);
    if ~isfolder(s.surfDir);
        mdisp('red',['subject ' s.subject ' has mri but cannot find its surf, check your freesurf reconall results.']);
        keyboard;
    end
    cd(s.surfDir);
    % load ?h.smoothwm
    [lh.vertices, lh.faces] = freesurfer_read_surf([s.surfDir 'lh.smoothwm']);
    [rh.vertices, rh.faces] = freesurfer_read_surf([s.surfDir 'rh.smoothwm']);

    % load ?h.thickness
  [lh.thickness, ~] = freesurfer_read_curv([s.surfDir 'lh.thickness']);
  [rh.thickness, ~] = freesurfer_read_curv([s.surfDir 'rh.thickness']);

  if length(lh.vertices)~= length(lh.thickness) || ...
      length(rh.vertices)~= length(rh.thickness)
    error('Dimension of ?h.smoothwm and ?h.thickness not matched.')
  end

  % merge lh and rh
  smoothwm.faces = [lh.faces; rh.faces + size(lh.vertices, 1)]; %<-----
  smoothwm.vertices = [lh.vertices; rh.vertices];
  smoothwm.thickness=[lh.thickness;rh.thickness];
  LRsegment = length(lh.vertices);

  if reducemesh
    %  % 20121112 vincent:
    %  % reduce patch before merge, in order to get the vertice index of ?h
    %  [lh.faces, lh.vertices] = reducepatch(lh.faces, lh.vertices, 20000);
    %  2025-03-14 arthur: this reducepatch attempts to reduce the mesh to approximately 20,000 faces by default, not vertices.
    %  To control the number of vertices instead of faces:
    %  Use the 'vertices' option: [lh.faces, lh.vertices] = reducepatch(lh.faces, lh.vertices, 20000, 'vertices');
    % 
    %  lh = remove_invalid_vertices(lh);
    %  [rh.faces, rh.vertices] = reducepatch(rh.faces, rh.vertices, 20000);
    %  rh = remove_invalid_vertices(rh);
    %  smoothwmreducedmesh.faces = [lh.faces; rh.faces + size(lh.vertices, 1)];
    %  smoothwmreducedmesh.vertices = [lh.vertices; rh.vertices];
    %   
    % 2025-03-13 arthur Replace reducepatch with FreeSurfer in MATLAB for cortical surface mesh simplification
    % Define paths for FreeSurfer input/output
    lh_input = [s.surfDir 'lh.smoothwm']; % Left hemisphere mesh
    rh_input = [s.surfDir 'rh.smoothwm']; % Right hemisphere mesh
    lh_output = [s.surfDir 'lh.smoothwm.dec']; % Decimated left hemisphere mesh
    rh_output = [s.surfDir 'rh.smoothwm.dec']; % Decimated right hemisphere mesh

    % Use FreeSurfer's mris_remesh to reduce the number of vertices
    mysystem(sprintf('mris_remesh -i %s -o %s --nvert 10000', lh_input, lh_output));
    mysystem(sprintf('mris_remesh -i %s -o %s --nvert 10000', rh_input, rh_output));

    %keyboard
    % Load the reduced surfaces back into MATLAB
    [lh.vertices, lh.faces] = freesurfer_read_surf(lh_output);
    if ~all(lh.faces(:))
      % Convert faces from 0-based to 1-based indexing (MATLAB uses 1-based indexing)
      lh.faces = lh.faces+1;
    end

    [rh.vertices, rh.faces] = freesurfer_read_surf(rh_output);
    if ~all(rh.faces(:))
      % Convert faces from 0-based to 1-based indexing (MATLAB uses 1-based indexing)
      rh.faces = rh.faces+1;
    end
    % 2025-03-18 Check it, sometimes
    % rr=unique(rh.faces(:))
    % rr(1)=1
    % rr(10000) = 10000
    % So it is not 0-based, +1 is not ncecssary!!!

% >> rh
% 
% rh = 
% 
%   struct with fields:
% 
%     vertices: [10000x3 double]
%        faces: [19996x3 double]
% 
% >> rr=unique(rh.faces(:))


    % Merge left and right hemisphere meshes
    smoothwmreducedmesh.faces = [lh.faces; rh.faces + size(lh.vertices, 1)];
    smoothwmreducedmesh.vertices = [lh.vertices; rh.vertices];

    mdisp('FreeSurfer remesh completed.');

  else
    smoothwmreducedmesh = smoothwm;
  end

  % 2025-03-13 the following code segment for merging lh and rh mesh is suggested by chatgpt

  % Define segment labels
  smoothwmreducedmesh.segmentLabel = {'lh'; 'rh'};

  % Store face and vertex counts for each hemisphere
  smoothwmreducedmesh.segmentFaces = [size(lh.faces, 1); size(rh.faces, 1)];
  smoothwmreducedmesh.segmentVertices = [size(lh.vertices, 1); size(rh.vertices, 1)];

  % Ensure face indices do not exceed available vertices
  % rh_offset = smoothwmreducedmesh.segmentVertices(1) - 1; % Adjusted offset <-- wrong!
  rh_offset = smoothwmreducedmesh.segmentVertices(1); % Adjusted offset <-- correct! 2025-09-24

  % Debugging print statements
  fprintf('Max RH Face Index (Before Offset): %d\n', max(rh.faces(:)));
  fprintf('RH Offset: %d\n', rh_offset);
  fprintf('Max RH Face Index (After Offset): %d\n', max(rh.faces(:)) + rh_offset);
  fprintf('Total Vertices After Merge: %d\n', sum(smoothwmreducedmesh.segmentVertices));

  if max(rh.faces(:)) + rh_offset > sum(smoothwmreducedmesh.segmentVertices)
    error('Right hemisphere face indices will exceed available vertices. Check indexing!');
  end

  % Apply correct offset for RH faces
  rh.faces = rh.faces + rh_offset;

  % Merge both hemispheres
  smoothwmreducedmesh.faces = [lh.faces; rh.faces];
  smoothwmreducedmesh.vertices = [lh.vertices; rh.vertices];

  % Adjust vertex indexing
  smoothwmreducedmesh.verticesIdx = [
    1, smoothwmreducedmesh.segmentVertices(1);
    smoothwmreducedmesh.segmentVertices(1) + 1, sum(smoothwmreducedmesh.segmentVertices)
    ];

  % Check for face index issues
  maxFaceIdx = max(smoothwmreducedmesh.faces(:));
  numVertices = size(smoothwmreducedmesh.vertices, 1);

  if maxFaceIdx > numVertices
    mdisp('red', 'Mesh face indices exceed the number of vertices. Check face indexing.');
    keyboard
  end

  % Please refer to confine_L_to_gm.m and
  %   http://emsica.art/cortical/how_to_properly_set_dipoles_on_cortical_and_subcortical_structure
  % 201201114 vincent
  % Dipoles should not be on everywhere of the surface of ?h.smoothwm.
  % We need to confine dipoles to where there is gray matter.
  % Find vertices where the thickness equals 0, and set those columns of L to 0
  % Output:
%   idxnongraymatter: the index in reduce-patched cortical mesh where its
%                       thickness is 0
%
% find smoothwm.thickness of downpatched smoothwm mesh

% 2025-03-13 The following is for using MATLAB’s reducepatch which can keep existing vertices
% [tmp,idx]=ismember(smoothwmreducedmesh.vertices, smoothwm.vertices, 'rows');
% idx(idx==0)=[];
% 
% % if the following error occurs, your smoothwmreducedmesh in ./5lfm/dipoles_cortical.mat and l/rh.smoothwm does not match.
% % 2014-06-13 -arthur
% if isempty(idx)
%   error([mymfilenames() ' your smoothwmreducedmesh in ./5lfm/dipoles_cortical.mat should be a subset of [lh.smoothwm ; rh.smoothwm]']);
% end
% 
% if ~isempty(idx)
%   smoothwmthickness=smoothwm.thickness(idx);
% end


% 2025-03-13 The following is for using freesurfer mris_remesh() which can not keep existing vertices
% Find smoothwm.thickness of downsampled smoothwm mesh

% [idx, dist] = knnsearch(smoothwm.vertices, smoothwmreducedmesh.vertices);

[lidx, ldist] = knnsearch(smoothwm.vertices(1:LRsegment,:), lh.vertices);
[ridx, rdist] = knnsearch(smoothwm.vertices(LRsegment+1:end,:), rh.vertices);
idx = [lidx;ridx+LRsegment];
dist = [ldist;rdist];

% Define a reasonable threshold (adjust if needed)
max_dist_threshold = 0.7;  % Based on histogram

% Keep only valid matches within threshold
valid_matches = dist < max_dist_threshold;

% Debug: How many vertices are valid?
fprintf('Valid matches: %d / %d\n', sum(valid_matches), length(idx));

if sum(valid_matches) < 0.95 * length(idx)  % If too many unmatched points exist
    mdisp('red','Warning: A large number of vertices do not have close matches. Consider increasing max_dist_threshold.');
end

% Only keep valid matches
% idx = idx(valid_matches);

smoothwmreducedmesh.vertices = smoothwm.vertices(idx, :);

% Extract thickness values for matched vertices
smoothwmthickness = smoothwm.thickness(idx);

% Identify non-gray matter vertices (where thickness == 0)
idxnongraymatter=find(smoothwmthickness==0);

%=======================================================

% We can plot unmatched points to see where the issue occurs:
% todo: plot only those invalid matched
% todo: plot on mesh
if 0

  scatter3(smoothwm.vertices(:,1), smoothwm.vertices(:,2), smoothwm.vertices(:,3), 10, 'b'); % Original mesh (blue)  
  hold on;
  scatter3(smoothwmreducedmesh.vertices(:,1), smoothwmreducedmesh.vertices(:,2), smoothwmreducedmesh.vertices(:,3), 10, 'r'); % Reduced mesh (red)
  legend({'Original Mesh', 'Reduced Mesh'});
  hold off;
  vis
end

% % cleanup 2025-03-18
% smoothwm=cleanup(smoothwm);
% smoothwmreducedmesh=cleanup(smoothwmreducedmesh);

%=======================================================

% Compute vertex normals
[vertNormals, vertNormalsUnit] = mesh_vertex_normals(smoothwmreducedmesh);

% save 5lfm/lfm_cortical.dip, Note that all of your sens, dip are in m scale -arthur
dipoles = [smoothwmreducedmesh.vertices/1000 vertNormalsUnit];

cd(s.lfmDir);
% save 5lfm/dipoles_cortical.mat Note that smoothwmreducedmesh.vertices are in meter scale as in freesurfer -arthur
save(dipmatfile, 'vertNormals', 'vertNormalsUnit', 'smoothwm', 'smoothwmreducedmesh', 'idxnongraymatter','idx');
mdisp([dipmatfile ' is generated.']);

% lfm_corticals.dip and lfm_subcorticals.dip files are no longer saved.
% Because they can be obtained from get_dipoles_cortical() and get_dipoles_subcortical(), respectively.
% That's why the following codes are marked. 2024-04-14 -arthur
%
% save(dipfile, 'dipoles', '-ascii'); % lfm.dip
% mdisp([s.lfmDir dipfile ' is generated.']);

end

if plotmore
  mesh = smoothwmreducedmesh;

  V=smoothwmreducedmesh.vertices; F=smoothwmreducedmesh.faces; figure; trisurf(F, V(:,1), V(:,2), V(:,3));
  axis equal; title('smoothwmreducedmesh');
  vis;

  % ~/1_zen/zm32/5lfm/corticalmeshes0.png
  pngfilename = mypath([s.lfmDir 'corticalmeshes0.png']);
  print('-dpng',pngfilename);  % close;
  mdisp([pngfilename ' is printed.']);
  set(gcf,'visible','on');
end

if plotmore
  meshs = cell(1,5);
  meshs{1} = 1;
  meshs{2} = 'all';
  meshs{3} = [122 186 220 0];
  meshs{1,4}=smoothwmreducedmesh.vertices(:,1:3);
  meshs{1,5}=smoothwmreducedmesh.faces(:,1:3);
  mydraw(s,'scalp-cortical', meshs, 1); % without scalp
  mydraw(s,'scalp-cortical', meshs, 2); % with scalp
end

%%=========================================================================
  function mydraw(s, name, corticalmeshes, flag)
    %% for subjects with MRI
    if hasmri(s) || strcmpi(s.subject,'.colin27') || contains(s.subject,'7raicar')
      % use outer_skin_surface instead of mri_scalp -arthur 2023-04-27
      % read watershed outer_skin_surface
      mdisp('loading watershed/_outer_skin_surface...');
      if ~isfile('watershed/_outer_skin_surface')
        mdisp('red', 'Cannot load watershed/_outer_skin_surface. You need to run watershed(s)');
        keyboard
      end
      [vertices, faces ]= freesurfer_read_surf([s.lfmDir 'watershed/_outer_skin_surface']);
    else %% for subjects without MRI
      mdisp('nonewline','... loading lfm_warp/outerskin.mat...');
      load([s.lfmDir 'lfm_warp/outerskin.mat']);
      disp('done.');
      % Note, outerskin.mat is generated by get_dipoles_warping_5layers(s)
      faces = Escalp(:,2:4);
      vertices=Cscalp_w(:,2:4);
    end

    figure('Name',name);
    for i=1:5
      subplot(2,3,i);
      if flag
        plotmesh_color(faces, vertices, [], 1, 'none', [1,.75,.65], 0.5);% transparent plot
        %plotmesh_color(faces, vertices, [], 1,[1,.75,.65], 'none',1);
        hold on
      end
      plotmesh_color2(corticalmeshes,[], 1);

      switch i
        case 1
          view(90,0); %title('view(90,0)');
        case 2
          view(180,0); %title('view(180,0)');
        case 3
          view(270,0); %title('view(270,0)');
        case 4
          view(180,-90); %title('view(180,-90)');
          title('inferior')
        case 5
          view(180, 90); %title('view(180,-90)'); % superior
          title('superior')
      end

      puttext();

    end % for i=1:5


    %% Add legend for each cortical region -arthur 2023-04-27
    if i==5
      n=size(corticalmeshes,1)/2;
      n = ceil(n);
      region_names = cell(n,1); % preallocate region_names cell array
      region_colors = zeros(n,3); % preallocate region_colors matrix

      for i=1:n
        split_name = strsplit(corticalmeshes{i,2}, '.');
        region_names{i} = split_name{end};
        region_colors(i,:) = corticalmeshes{i,3}(1:3)/256;
      end

      % Add legend
      region_patches = zeros(length(region_names), 1);
      for i = 1:length(region_names)
        region_patches(i) = patch('DisplayName', region_names{i}, 'FaceColor', region_colors(i,:), 'EdgeColor', 'none');
      end
      ll = legend(region_patches);
      set(ll,'position',[0.7697 0.2626 0.1113 0.0413]); %
    end

    % ~/1_zen/zm32/5lfm/corticalmeshes0.png
    pngfilename = mypath([s.lfmDir 'corticalmeshes' int2str(flag) '.png']);
    print('-dpng',pngfilename);  % close;
    mdisp([pngfilename ' is printed.']);
    set(gcf,'visible','on');

    %%=========================================================================

    function puttext()
      tmp=get(gca,'Xlim');
      l=tmp(1);
      r=tmp(2);
      tmp=get(gca,'Ylim');
      p=tmp(1);
      a=tmp(2);
      tmp=get(gca,'Zlim');
      s=tmp(2);
      z0=(tmp(1)+tmp(2))/2;

      text(0,0,0.9*s,'S');
      text(1.1*r,0,z0,'R');
      text(1.1*l,0,z0,'L');
      text(0,1.1*a,z0,'A');
      text(0,1.1*p,z0,'P');
      axis equal;




% Helper Functions for cortical surface mesh simplification using freesurf
% 2025-03-13 arthur with chatgpt

function write_freesurfer_surface(filename, vertices, faces)
    fid = fopen(filename, 'w');
    if fid == -1, error('Cannot open file: %s', filename); end
    fprintf(fid, '# Created by MATLAB\n');
    fprintf(fid, '%d %d\n', size(vertices, 1), size(faces, 1));
    fprintf(fid, '%f %f %f\n', vertices');
    fprintf(fid, '%d %d %d\n', faces' - 1); % Convert 1-based to 0-based index
    fclose(fid);

function [vertices, faces] = read_freesurfer_surface(filename)
    fid = fopen(filename, 'r');
    if fid == -1, error('Cannot open file: %s', filename); end
    fgetl(fid);  % Skip comment line
    dims = fscanf(fid, '%d %d', 2);
    vertices = fscanf(fid, '%f %f %f', [3, dims(1)])';
    faces = fscanf(fid, '%d %d %d', [3, dims(2)])' + 1; % Convert 0-based to 1-based
    fclose(fid);
