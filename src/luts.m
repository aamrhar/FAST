
%% This structiure contains information relative to the flight tests


%% nav info struct
lut.nav_info.yjn.name='ST JEAN VORTAC';
lut.nav_info.yjn.id='yjn';
lut.nav_info.yjn.navf=115.8;
lut.nav_info.yjn.lat_dd=45.255813;
lut.nav_info.yjn.lon_dd=-73.32129';
lut.nav_info.yjn.elevation_m=230;

lut.nav_info.ihu.name='ILS-DME CYUHU'; % to fill
lut.nav_info.ihu.id='ihu';
lut.nav_info.ihu.navf=111.1;
lut.nav_info.ihu.lat_dd=45.5225;
lut.nav_info.ihu.lon_dd=-73.4083;
lut.nav_info.ihu.elevation_m=36.2712;

lut.nav_info.yul.name='Montreal VOR-DME'; % to fill
lut.nav_info.yul.id='yul';
lut.nav_info.yul.navf=116.3;
lut.nav_info.yul.lat_dd=45.615002;
lut.nav_info.yul.lon_dd=-73.971703;
lut.nav_info.yul.elevation_m=60,96;


lut.mode_lut=containers.Map(... 
    {'OFF' 'SBY' 'TMS' 'ADSB' 'DME1' 'DME2' 'WBR'}, ...
    1:7);
disp('loading constants...')
%% wbr map
lut.wbr_modc_lut=...
    containers.Map({'DBPSK64' 'DBPSK32' 'DQPSK64' 'DQPSK32' 'D8PSK64' 'D8PSK32' 'D16QAM64' 'D16QAM32'}, ...
    [0:7]);
%% nav map
lut.nav_lut=...
    containers.Map([115.8 111.1 116.3], ...
    {lut.nav_info.yjn lut.nav_info.ihu lut.nav_info.yul});



%% DME stations

lut.DMEs(1).name='ST JEAN VORTAC';
lut.DMEs(1).id='yjn';
lut.DMEs(1).navf=115.8;
lut.DMEs(1).lat_dd=45.255813;
lut.DMEs(1).lon_dd=-73.32129';
lut.DMEs(1).elevation_m=230;

lut.DMEs(2).name='ILS-DME CYUHU'; % to fill
lut.DMEs(2).id='ihu';
lut.DMEs(2).navf=111.1;
lut.DMEs(2).lat_dd=45.5225;
lut.DMEs(2).lon_dd=-73.4083;
lut.DMEs(2).elevation_m=36.2712;


%% airports

lut.airport(1).name = 'St-Hubert';
lut.airport(1).id = 'cyhu';
lut.airport(1).lat = 45.518333;
lut.airport(1).long = -73.416667;
lut.airport(1).elevation = 27.432;

%% LASSENA ground stations

lut.mgs(1).name = 'Descente de bateaux, St-Damasse';
lut.mgs(1).latitude = 45.4924;
lut.mgs(1).longitude = -72.9813;
lut.mgs(1).elevation_m = 0;

lut.mgs(2).name = 'Chemin Martel, St-Damasse';
lut.mgs(2).latitude = 45.482512;
lut.mgs(2).longitude = -73.000021;
lut.mgs(2).elevation_m = 34;

%% Aircrafts

lut.aircraft(1).name = 'Cessna 172';

lut.aircraft(2).name = 'Piaggio Avanti';

%% WBR
lut.max_rate.DBPSK64 = 44500;
lut.max_rate.DBPSK32 = 50667;
lut.max_rate.DQPSK64 = 87200;
lut.max_rate.DQPSK32 = 100855;
lut.max_rate.D8PSK64 = 126218;
lut.max_rate.D8PSK32 = 151795;
lut.max_rate.D16QAM64 = 172622;
lut.max_rate.D16QAM32 = 201343;

lut.wbr_modcod = [44500, 50667, 87200, 100855, 126218, 151795, 172622, 201343];



%% ADS-B LUTS

TC4={'No Info.' 'Light' 'Small' 'Large' 'High-Vortex'...
    'Heavy' 'High Performance' 'Rotorcraft'}.';
TC3={'No Info.' 'Glider' 'Lighter-than-Air' 'Parachutist' ...
    'Ultralight' 'Reserved' 'Unmanned Aerial Vehicle' 'Space'}.';
TC2={'No Info' 'Emergency Vehicle' 'Service Vehicle' 'Point Obstacle' ...
    'Cluster Obstacle' 'Line Obstacle' 'Reserved' 'Reserved'}.';
TC1={'No info' 'Reserved' 'Reserved' 'Reserved' 'Reserved' 'Reserved' ...
    'Reserved' 'Reserved'}.';
lut.adsb_cat=cell2table([TC4 TC3 TC2 TC1]);
lut.adsb_cat.Properties.VariableNames=({'TC4' 'TC3' 'TC2' 'TC1'});

