% mdisp() Display a message with optional style in MATLAB's command window or a supported terminal.
%
% function mdisp(style, msg)
% MDISP Display a message with optional style in MATLAB's command window or a supported terminal.
%
% Usage:
%   mdisp(msg)
%   mdisp(style, msg)
%
% Description:
%   MDISP(style, msg) displays a formatted message `msg` using the specified `style`.
%   If the function is called with one argument, that argument is treated as the `msg`
%   with no style applied. If `style` is provided, the message will be styled according
%   to the specifications in `cdisp`, which supports various text styles and colors.
%
%   The function also prints a trace of calling functions, omitting the function
%   itself and any utilities, and adding line numbers to the last two functions in the
%   trace. The trace is displayed in dark gray.
%
% Arguments:
%   style (Optional) - A string specifying the style of the message, which can include
%                      text color, such as 'red', 'yellow', background color, and other modifiers such as
%                      'bright' or 'underline'. See `cdisp` documentation for details.
%   msg - The message to be displayed. This is a string.
%
% Examples:
%  1. mdisp('Hello, world!') (suppose this function is called in backupfolder())
%     % Displays "Hello, world!" with no additional style, preceded by the function call trace in dark gray.
%     % Example Output: run1()>ica_():75:>backupfolder():69: Hello world!
%     % where "run1()>ica_():75:>backupfolder():69:" is in dark gray.
%
%  2. mdisp('bright red', 'Error: Something went wrong!')
%
%  3. mdisp('bright yellow', 'sk=' sk], verbose);
%     % verbose can be 0 or 1, a switch for debugging purpose
%     % verbose = 0, donot show this message, in production phase
%     % verbose = 1, show this message, in developement phase
%
% %
% 2024-04-27 Arthur Tsai
% 2025-01-18 add verbose parameter
%
% See Also:
%   cdisp, fprintf, disp
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function mdisp(style, varargin)
if nargin == 0
    style = [];   % Or '', depending on your preference
    msg = '';     % Initialize empty message
    % You may want to skip the rest of the logic or return early
end
verbose =1; % default. always show messages
if ~isempty(varargin) % input is msg only
    lastInput = varargin{end};
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

    if isnumeric(lastInput) && isscalar(lastInput) && (lastInput == 1 || lastInput == 0)
        % disp(['The last input is the parameter verbose and is: ', num2str(lastInput)]);
        verbose = lastInput;
        if verbose == 0
            return
        end
        varargin{end}=[];
    end
end

if isempty(varargin) % input is msg only
    msg = style;
    style = [];
else
    msg = varargin{1};
end

% nonewline is for the case when we want to print a message, but no newline is needed after printing.
% usually when we print eg.
% ... calculating vertex surface normals ....
% then we want to print 'done' laster after it sucessfully calcualted
% 2024-04-28 arthur
if strcmp(style,'nonewline')
    nonewline = 1;
else
    nonewline = 0;
end

stack = dbstack('-completenames');

% Check if the stack has more than one entry
if numel(stack) > 1
    % Remove the first entry (top of the stack) 'mymfilenames'
    stack(1) = [];
else
    % If 'mymfilenames' is the only entry, clearing the stack
    stack = [];
end
n = numel(stack) ;% - 1; % Exclude `mymfilenames` from the count

if n < 1 % No caller trace available (e.g. base workspace); still print the message.
    filenames = '';
    if isempty(style)
        if nonewline
            fprintf('%s', msg);
        else
            disp(msg);
        end
    else
        if nonewline
            cdisp(style, '%s', msg);
        else
            cdisp(style, '%s\n', msg);
        end
    end
    return;
end
% Setup for filenames, exclude the function itself
filenames = cell(n, 1);

for i = 1:n
    %     % Add line numbers only to the last two functions
    %     if i <= 2 % n - 1
    %       filenames{i} = sprintf('%s():%d:', stack(i).name, stack(i).line);
    %     else
    %       % Regular function names for the others
    %       filenames{i} = sprintf('%s()', stack(i).name);
    %     end

    % Now, always add line numbers 2024-4-28 arthur
    filenames{i} = sprintf('%s():%d:', stack(i).name, stack(i).line);
end

% Reverse filenames to start from the top-level function
filenames = flip(filenames);
% Change #1: Convert the cell array of filenames to a single string
% Convert each element to char to ensure compatibility with strjoin
filenames = cellfun(@char, filenames, 'UniformOutput', false); % <-- Change #1

if ~isstr(filenames{1})
    keyboard
end

try
    % Join filenames with '>'
    % filenames = strjoin(filenames, '>'); % <-- Change #2
    % avoid using strjoin()
    filenames = sprintf('%s>', filenames{:});
    filenames(end) = [];  % remove trailing '>'
catch
    keyboard
end
%   % Convert to string array
%   filenames = cellfun(@(x) string(x), filenames, 'UniformOutput', true);
%
%   % Join filenames with '>'
%   filenames = strjoin(filenames, '>');

% Convert the final string array to a character array
filenames = [char(filenames) ' '];

% Use cdisp to display in the desired style
cdisp('darkGray', '%s', filenames);

if isempty(style)
    if nonewline
        fprintf(msg);
    else
        disp(msg);
    end
else
    if nonewline
        cdisp(style,'%s', msg);
    else
        cdisp(style,'%s\n', msg);
    end
end

end
