% myfiguremax() History
%
% Examples:
% ./conn/sif_tfce_eo_ey.m:729:myfiguremax('right', 'white', figurename);
% ./conn/sif_plot_eo_ey.m:400:    myfiguremax('left');
% ./conn/sif_plot_eo_ey.m:688:    myfiguremax('left','black', pngfile1);
% ./conn/sif_plot_eo_ey.m:699:    myfiguremax('right','black', pngfile2);
% ./conn/sif_.m:1005:      myfiguremax('right', 'black', pngfile);
% 
% 2024-2 
% 2024-12-10 arthur revised @UCSD
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function h = myfiguremax(pos, bg, figurename)
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

  h = gcf;
  set(h, 'WindowStyle', 'normal');
  % Check the input argument
  if nargin < 1
    pos = 'center';  % Default to center if no position is specified
  end

  if nargin >= 3
    set(h,'name', figurename);
  end

  % bg = 'black' | 'white'
  if nargin < 2
    bg = 'white';  % Default backgroound
  end

  % Validate the position argument
  validPositions = {'full', 'left', 'right', 'bottomright', 'top', 'bottom', 'center'};
  if ~ismember(pos, validPositions)
    error('Invalid position. Valid positions are: ''left'', ''right'', ''bottomright'', ''center''.');
  end

  % Get screen size
  screenSize = get(0, 'ScreenSize');
  leftEdge = screenSize(1);
  bottomEdge = screenSize(2);
  screenWidth = screenSize(3);
  screenHeight = screenSize(4);

  % Keep a small border so the native window title bar stays visible
  % and the figure can still be dragged around.
  sideMargin = 10;
  bottomMargin = 10;
  topMargin = 70;
  availableHeight = max(200, screenHeight - topMargin - bottomMargin);

  % Set the figure size to maximize height while keeping the aspect ratio
  % Adjust the width as necessary; here we keep it 60% of the screen width
  figureWidth = screenWidth * 0.6;    % 60% of the screen width
  figureHeight = availableHeight;

  % Determine the figure's position based on the specified 'pos'
  switch pos
    case 'full'
      if isprop(h, 'WindowState')
        set(h, 'WindowState', 'maximized');
      else
        figurePosition = [leftEdge + sideMargin, ...
                          bottomEdge + bottomMargin, ...
                          screenWidth - 2 * sideMargin, ...
                          availableHeight];
      end
    case 'left'
      figurePosition = [leftEdge + sideMargin, ...
                        bottomEdge + bottomMargin, ...
                        figureWidth, ...
                        figureHeight];  % Align to the left
    case 'bottomright'
      figurePosition = [leftEdge + screenWidth * 0.5, ...
                        bottomEdge + bottomMargin, ...
                        screenWidth * 0.5 - sideMargin, ...
                        min(screenWidth * 0.38, availableHeight)];  % Align to the right
    case 'right'
      figurePosition = [leftEdge + screenWidth - figureWidth - sideMargin, ...
                        bottomEdge + bottomMargin, ...
                        figureWidth, ...
                        figureHeight];  % Align to the right
    case 'top' % Positions the figure in the top half of the screen.
      topHeight = max(200, availableHeight / 2);
      figurePosition = [leftEdge + sideMargin, ...
                        bottomEdge + bottomMargin + availableHeight - topHeight, ...
                        screenWidth - 2 * sideMargin, ...
                        topHeight];  % Top half
    case 'bottom' % Positions the figure in the bottom half of the screen.
      figurePosition = [leftEdge + sideMargin, ...
                        bottomEdge + bottomMargin, ...
                        screenWidth - 2 * sideMargin, ...
                        max(200, availableHeight / 2)];  % Bottom half
    otherwise  % 'center'
      figurePosition = [leftEdge + (screenWidth - figureWidth) / 2, ...
                        bottomEdge + bottomMargin, ...
                        figureWidth, ...
                        figureHeight];  % Center
  end

  % Set the current figure's position
  if ~strcmpi(pos, 'full') || ~isprop(h, 'WindowState')
    set(h, 'Units', 'pixels');
    set(h, 'Position', figurePosition);
  end

  if strcmp(bg,'black')
    set(gcf, 'InvertHardCopy', 'off');
    set(gcf,'Color',[0 0 0]); % RGB values [0 0 0] indicates black color
  end
% keyboard
  if nargin >= 3
    saveas(h,figurename);
    if ~contains(figurename,'/')
      figurename = [mypwd figurename];
    end
    mdisp('yellow',['printing to ' figurename]);
  end

end
