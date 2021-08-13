function radial = ecef2bearing(current_point, reference_point, offset)
%% This function will calculate the bearing between current points and reference points
% The value of current_point should be the ecef position
% Station is the ecef of the station
%% Variables
radial = 0;
x = current_point(1);
y = current_point(2);
z = current_point(3);

lat0 = reference_point(1);
long0 = reference_point(2);
alt0 = reference_point(3);

reference = referenceEllipsoid('wgs84');

%% Do the calculation
[e,n,u] = ecef2enu(x,y,z,lat0,long0,alt0,reference,'degrees');

q = atan2(e,n)*180/pi + offset - 180;
if q < 0
    q = q+360;
end
if q>360
    q = q - 360;
end

radial = q;
    
end