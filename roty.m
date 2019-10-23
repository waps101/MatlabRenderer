%ROTY   Rotation about y
% Homogeneous transform for rotation about y axis
%
% Syntax:  T = roty(phi)
%
% Inputs:
%    phi - angle to rotate about y
%
% Outputs:
%    T - homogeneous rotation transformation
%
% See also: ROTX,  ROTZ

% Author: Travis Hydzik
% Last revision: 19 October 2004

function R = roty(phi)
	
	R = [ cosd(phi)    0  sind(phi)    
             0        1     0       
         -sind(phi)    0  cosd(phi)   ];

% alternatively
% T = rot([0 1 0], phi)