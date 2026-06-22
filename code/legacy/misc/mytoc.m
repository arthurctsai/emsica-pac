% mytoc() Formats elapsed time in a human-readable string and optionally displays it.
%
  % SYNTAX:
  %   elaspsed_time = mytoc(time_in_secs)
  %
  % DESCRIPTION:
  %   MYTOC converts a time duration (in seconds) into a human-readable format
  %   (e.g., "2 hours, 1 min, 1.0 secs") using the SECS2HMS function. If the
  %   function is called directly, it also prints the formatted time to the 
  %   command window using mdisp. If it is called within another function
  %   (e.g., disp), it only returns the formatted string.
  %
  % INPUT:
  %   time_in_secs - Duration in seconds to be converted into a formatted string.
  %
  % OUTPUT:
  %   elaspsed_time  - A string representing the formatted time in hours, minutes,
  %                  and seconds.
  %
  % USAGE:
  %   Example 1: Display elapsed time after a process:
  %       >> tic; pause(12); disp(['This program took ' mytoc(toc)]);
  %       % Output: "This program took 1 min, 1.0 secs"
  %
  %   Example 2: Print elapsed time directly:
  %       >> tic; pause(12); mytoc(toc);
  %       % Output: "...done. It takes 2 hours, 1 min, 1.0 secs."
  %
  % DEPENDENCIES:
  %   Requires the SECS2HMS function for formatting time.
  %
  % NOTES:
  %   - If used within disp or similar functions, it will not execute
  %     additional messages like mdisp.
  %   - For accurate usage, ensure the SECS2HMS function is available in the path.
  %
  % See also SECS2HMS, TIC, TOC, DISP
  %
  % History:
  % 2024-11-30 major revision. arthur
%
% Author: Arthur C. Tsai, Institute of Statistical Science, Academia Sinica, June 2026
% Copyright (c) 2026 Extended EMSICA-PAC contributors
% SPDX-License-Identifier: BSD-3-Clause

function elaspsed_time = mytoc(time_in_secs)
% 123456789012345678901234567890123456789012345678901234567890123456789012345678

  elaspsed_time = secs2hms(time_in_secs);

  % Check if this function is called directly or inside `disp`
  stack = dbstack;

  % Only display the additional message if called directly
  if nargout == 0
    disp([' ...done. It takes ' elaspsed_time '.']);
  end

end
