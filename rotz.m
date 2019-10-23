%ROTZ   Rotation about z
% Homogeneous transform for rotation about z axis
%
% Syntax:  T = roty(psi)
%
% Inputs:
%    psi - angle to rotate about z
%
% Outputs:
%    T - homogeneous rotation transformation
%
% See also: ROTX, ROTY

% Author: Travis Hydzik
% Last revision: 19 October 2004

function R = rotz(psi)
	
	R = [ cosd(psi)   -sind(psi)    0 
          sind(psi)    cosd(psi)    0 
             0           0        1  ];

% alternatively
% T = rot([0 0 1], psi)