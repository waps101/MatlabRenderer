%ROTX   Rotation about x
% Homogeneous transform for rotation about x axis
%
% Syntax:  T = rotx(theta)
%
% Inputs:
%    theta - angle to rotate about x
%
% Outputs:
%    T - homogeneous rotation transformation
%
% See also: ROTY,  ROTZ

% Author: Travis Hydzik
% Last revision: 19 October 2004

function R = rotx(theta)
	
	R = [ 1     0           0       
          0  cosd(theta) -sind(theta) 
          0  sind(theta)  cosd(theta)];

% alternatively
% T = rot([1 0 0], theta)