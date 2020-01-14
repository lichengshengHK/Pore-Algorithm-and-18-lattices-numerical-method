function dw = SWCCHysteresis( File_read, WAK )
p = gcp( 'nocreate' );
delete( p ); %关闭并行计算释放内存

% File_read, is read the tif file path
% WAK = [ water, air, ske, hys of part ], the No of gray value
% if  WAK(4) = air, the simulation is Drying path
% if  WAK(4) = water, the simulation is wettying path

water = WAK(1);
air = WAK(2);
ske = WAK(3);
HysPart = WAK(4);
File_read = strcat( File_read, '\' );

if HysPart == air %标记非接触底边的空气
    File_save = strcat( File_read,  'Drying path' );
    [~, ~, ~] = mkdir( strcat( File_read, 'Drying path') ); % 保存D, z, 结果
elseif HysPart == water %标记非接触底边的水
    File_save = strcat( File_read,  'Wetting path' );
    [~, ~, ~] = mkdir( strcat( File_read, 'Wetting path') ); % 保存D, z, 结果
end

list = dir([File_read, '*.tif']);
II = imread([File_read, list(1).name]);
[x, y] = size(II);
z = length(list);
D = zeros(x, y, z, 'uint8' );

% 组合图片slice=========================================
num_file =  zeros( z, 1);

for i = 1 : z
    num_file( i ) = str2num( cell2mat(regexp(list(i).name,'\d', 'match')) );
end
num_file = min( num_file ); %计算最小文件名

hWaitbar = waitbar(0, 'reading the images .......') ; %建立进度条
for i = 1 : z
    fileName = str2num( cell2mat(regexp(list(i).name,'\d', 'match')) );
    II = imread([File_read, list(i).name]);
    D(:, :, fileName - num_file + 1 ) = II; % file_path必须转化成数字形式
    if mod(i, 50)
        waitbar( i/z, hWaitbar ); %进度
    end
end
close(hWaitbar) %关闭进度条
DD = D;

se = unique( D ); %液体灰度值
gray_ske = se( ske ); %骨架灰度值
gray_water = se( water );
gray_air = se( air );

D( DD == gray_ske ) = 255;  %归一化
D( DD == gray_air ) = 0;
D( DD == gray_water ) = 100;
DD = D;

V_pore = x * y * z - length( find( D == 255) ); %孔隙体积
if HysPart == air %标记非接触底边的空气
    D = D == 0; %剔除非air属性
elseif HysPart == water %标记非接触底边的水
    D = D == 100;
end

% 对三维矩阵进行形态学标记==================================
%D = int32( bwlabeln(D, num) );
hWaitbar = waitbar(0, 'Bwconncomp 3D image .......') ; %建立进度条
CC = bwconncomp(D, 6); %节省内存
D = D * 0; %初始化
max_n = length( CC.PixelIdxList ); %计数最大联通团像素个数
dd = floor( max_n / 50 ); %间隔
for i = 1 : max_n %赋值到D矩阵
    Line = CC.PixelIdxList{i};
    [ ~, ~, Dz ] = ind2sub( [x, y, z], Line ); %获取第i个连通域坐标值
    Dz = int16( Dz );
    
    if min( Dz ) > 1 %该连通域未连通底边界
        if HysPart == air %标记非接触底边的空气
            D( Line ) = 1; %标记为滞后液体,1, air->water
        elseif HysPart == water %标记非接触底边的水
            D( Line ) = 2; %标记为滞后空气，water->air
        end
        if mod( i, dd )
            waitbar( i/max_n, hWaitbar ); %进度
        end
    end
end
close(hWaitbar) %关闭进度条

DD( D == 1 ) = 100;  %Drying path
DD( D == 2 ) = 0; % wetting path
clear D

dw = 100 * length( find( DD == 100 ) ) / V_pore; %滞后的体积饱和度

hWaitbar = waitbar(0, 'Saving hysteresis image .......') ; %建立进度条
for i = 1 : z
    II = DD( :, :, i );
    imwrite( uint8( II ), strcat( File_save, '\',  num2str(i), '.tif' ) ); %保存处理后的边界
    if mod( i, 100 )
        waitbar( i/z, hWaitbar ); %进度
    end
end
close(hWaitbar) %关闭进度条
end