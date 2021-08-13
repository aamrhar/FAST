function radial = ecef2radial(current_point, station, reference, VOR_offset)
%% This function will calculate the radial of the current point corresponding to the station
% The value of current_point should be the ecef position
% Station is the ecef of the station
%% Variables
radial = zeros(4,1);
x = current_point(1);
y = current_point(2);
z = current_point(3);

lat0 = station(1);
long0 = station(2);
alt0 = station(3);

lla = [lat0 long0 alt0];
out = lla2ecef(lla);
dx = out(1) - x;
dy = out(2) - y;
dz = out(3) - z;

%% Offset finding
offset = 0;
if (lat0==45.2558140000000)
    offset = VOR_offset(1);
%     display('Here I am');
end
if (lat0==45.6150000000000)
    offset = VOR_offset(2);
end
if (lat0==44.3971060000000)
    offset = VOR_offset(3);
end
if (lat0==45.8883330000000)
    offset = VOR_offset(4);
end
if (lat0==44.9143610000000)
    offset = VOR_offset(5);
end
if (lat0==45.3164360000000)
    offset = VOR_offset(6);
end
if (lat0==44.0854830000000)
    offset = VOR_offset(7);
end
if (lat0==44.6334140000000)
    offset = VOR_offset(8);
end

%% Do the calculation
[e,n,u] = ecef2enu(x,y,z,lat0,long0,alt0,reference,'degrees');

q = atan2(e,n)*180/pi + offset;
if q < 0
    q = q+360;
end
if q>360
    q = q - 360;
end
% if (q<(360-2*offset))
%     q = q + offset;
% else if (q<360-offset)
%     q = (q+offset) - (360-offset);     
% else
%     q = q - (360-offset);
%     end
% end



radial(1,1) = q;
radial(2,1) = dx;
radial(3,1) = dy;
radial(4,1) = dz;
end