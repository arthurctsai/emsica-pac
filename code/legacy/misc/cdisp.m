function cdisp(style, fmatString, varargin)
    % Uses ANSI escape codes to print colored output when using MATLAB
    % from a terminal. If not running in a terminal, or if called by MATLAB's
    % datatipinfo function, cdisp reverts to standard printf. The latter is
    % desirable if cdisp is used within an object's disp() method to avoid
    % seeing the ANSI characters here.
    %
    % The first argument is an style description that consists of space-separated
    % words. These words may include: 
    %
    % one of the following colors:
    %   black, red, green, yellow, blue, purple, cyan, darkGray, lightGray, white
    %
    % one of the following background colors:
    %   onBlack, onRed, onGreen, onYellow, onBlue, onPurple, onCyan, onWhite
    %
    % and any of the following modifiers:
    %   bright : use the bright (or bold) form of the color, not applicable for
    %       black, darkGray, lightGray, or white
    %   underline : draw an underline under each character
    %   blink : This is a mistake. Please don't use this ever.
    %
    % Example:
    %   cdisp('lightGray onRed underline', 'Message: %20s\n', msg);
    %
    % cdisp is a modified version of tcprintf.
    % Original work Copyright (c) 2012, Dan O'Shea.
    % Modifications Copyright (c) 2026, Arthur.
    %
    % Modifications:
    %   - Renamed tcprintf to cdisp.
    %   - Improved ANSI escape construction and safe fprintf usage.
    %
    % BSD 2-Clause License
    %
    % Copyright (c) 2012, Dan O'Shea
    % All rights reserved.
    %
    % Redistribution and use in source and binary forms, with or without
    % modification, are permitted provided that the following conditions are
    % met:
    %
    %     * Redistributions of source code must retain the above copyright
    %       notice, this list of conditions and the following disclaimer.
    %     * Redistributions in binary form must reproduce the above copyright
    %       notice, this list of conditions and the following disclaimer in
    %       the documentation and/or other materials provided with the distribution
    %
    % THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
    % AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
    % IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
    % ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
    % LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
    % CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
    % SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
    % INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
    % CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
    % ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    % POSSIBILITY OF SUCH DAMAGE.

    if nargin < 2 || ~ischar(style) || ~ischar(fmatString)
        error('Usage: cdisp(style, fmatString, ...)');
    end

    % determine if we're using 
    usingTerminal = ~usejava('desktop');

    % determine if datatipinfo is higher on the stack. If cdisp
    % is used within an object's disp() method, we don't want to
    % use color in the hover datatip or all you'll see are ANSI codes.
    stack = dbstack;
    inDataTip = ismember('datatipinfo', {stack.name});

    if ~usingTerminal || inDataTip
        % print the message without color and return
        fprintf(fmatString, varargin{:});
        return;
    end

    bright = 1;
    [colorName backColorName bright underline blink] = parseStyle(style);
    colorCodes = getColorCode(colorName, bright);
    backColorCodes = getBackColorCode(backColorName);

    codes = [colorCodes; backColorCodes];

    if underline
        codes = [codes; 4];
    end

    if blink
        codes = [codes; 5];
    end

    codeStr = strjoin(codes, ';');

    % evaluate the printf style message
    contents = sprintf(fmatString, varargin{:});

    % if the message ends with a newline, we should turn off
    % formatting before the newline to avoid issues with 
    % background colors
    if ~isempty(contents) && contents(end) == char(10)
        contents = contents(1:end-1);
        endOfLine = char(10);
    else
        endOfLine = '';
    end
        
    esc = char(27);
    str = [esc '[' codeStr 'm' contents esc '[0m' endOfLine];
    fprintf('%s', str);
end

function [colorName backColorName bright underline blink] = parseStyle(style)
    defaultColor = 'white';
    defaultBackColor = 'onDefault';

    tokens = regexp(style, '(?<value>\S+)[\s]?', 'names');
    
    values = {tokens.value};

    if ismember('bright', values)
        bright = true;
    else
        bright = false;
    end

    if ismember('underline', values)
        underline = true;
    else
        underline = false;
    end
    
    if ismember('blink', values)
        blink = true;
    else
        blink = false;
    end

    % find foreground color
    colorList = {'black', 'darkGray', 'lightGray', 'red', 'green', 'yellow', ...
        'blue', 'purple', 'cyan', 'lightGray', 'white', 'default'};
    idxColor = find(ismember(colorList, values), 1);
    if ~isempty(idxColor)
        colorName = colorList{idxColor}; 
    else
        colorName = defaultColor;
    end

    % find background color
    backColorList = {'onBlack', 'onRed', 'onGreen', 'onYellow', 'onBlue', ...
        'onPurple', 'onCyan', 'onWhite', 'onDefault'};
    idxBackColor = find(ismember(backColorList, values), 1);
    if ~isempty(idxBackColor)
        backColorName = backColorList{idxBackColor}; 
    else
        backColorName = defaultBackColor;
    end

end

function colorCodes = getColorCode(colorName, bright)

    switch colorName
        case 'black'
            code = 30;
            bright = 0;
        case 'darkGray';
            code = 30;
            bright = 1;
        case 'red'
            code = 31;
        case 'green'
            code = 32;
        case 'yellow'
            code = 33;
        case 'blue'
            code = 34;
        case 'purple'
            code = 35;
        case 'cyan'
            code = 36;
        case 'lightGray'
            code = 37;
            bright = 0;
        case 'white'
            code = 37;
            bright = 1;
        case 'default'
            code = 39;
    end

    if bright
        colorCodes = [1; code];
    else
        colorCodes = [code];
    end

end

function colorCodes = getBackColorCode(colorName)

    switch colorName
        case 'onBlack'
            code = 40;
        case 'onRed'
            code = 41;
        case 'onGreen'
            code = 42;
        case 'onYellow'
            code = 43;
        case 'onBlue'
            code = 44;
        case 'onPurple'
            code = 45;
        case 'onCyan'
            code = 46;
        case 'onWhite'
            code = 47;
        case 'onDefault'
            code = 49;
    end

    colorCodes = code;
end

function str = strjoin(strCell, join)
    % str = strjoin(strCell, join)
    % creates a string by concatenating the elements of strCell, separated by the string
    % in join (default = ', ')
    %
    % e.g. strCell = {'a','b'}, join = ', ' [ default ] --> str = 'a, b'

    if nargin < 2
        join = ', ';
    end

    if isempty(strCell)
        str = '';
    else
        if isnumeric(strCell) || islogical(strCell)
            % convert numeric vectors to strings
            strCell = arrayfun(@num2str, strCell, 'UniformOutput', false);
        end

        str = cellfun(@(str) [str join], strCell, ...
            'UniformOutput', false);
        str = [str{:}]; 
        str = str(1:end-length(join));
    end
end
