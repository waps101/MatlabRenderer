function R = axang2rotm(axang)

theta = norm(axang);

if theta==0
    R = eye(3);
else
    k = axang./theta;

    K = [0 -k(3) k(2); k(3) 0 -k(1); -k(2) k(1) 0];
    
    R = eye(3) + sin(theta).*K + (1-cos(theta)).*K*K;
end

end