function SWCCForce( File_read, WAK )
tic
% File_read, read tif file path
% WAK = [ water, air, ske ], the No of gray value
% Vct is the save data.

p = gcp( 'nocreate' );
delete( p ); %关闭并行计算释放内存

water = WAK(1);
air = WAK(2);
ske = WAK(3);

File_read = [ File_read, '\' ];
list = dir( [ File_read, '*.tif' ] );
z = length( list );
II = imread( [ File_read, list(1).name ] );
[n, m] = size( II );
D = zeros( n, m, z, 'uint8' );
add = [];
Vct_add = [];
for i = -1 : 1
    for j = -1 : 1
        for k = -1 : 1
             if (i == 0 && j == 0 && k == 0) || ( abs(i) == 1 && abs(j) == 1 && abs(k) == 1 )
             else
                 add(end+1, :) = [ i, j, k ]; %临域
                 Vct_add(end+1, :) = add(end, :) / norm( add(end, :) ); %邻域向量
             end 
        end
    end
end 
add = int16( add );
Vct_add = single( Vct_add );

num_file = zeros( z, 1 );
for i = 1 : z
    num_file( i ) = str2num( cell2mat(regexp(list(i).name,'\d', 'match')) );
end
num_file = min( num_file ); %计算文件最小名

hWaitbar = waitbar(0, 'reading the images .......') ; %建立进度条
for i = 1 : z
    fileName = str2num( cell2mat(regexp(list(i).name,'\d', 'match')) );
    II = imread([File_read, list(i).name]);
    D(:, :, fileName - num_file + 1 ) = II; % file_path必须转化成数字形式
    if mod(i, 20) == 0
        waitbar( i/z, hWaitbar,  'reading the images .......' ); %进度
    end
end 
D( D == 101 ) = 100; %滞后的灰度值也为water
close(hWaitbar) %关闭进度条

se = unique( D ); %液体灰度值
gray_ske = se( ske ); %骨架灰度值
gray_water = se( water );
gray_air = se( air ); 
disp( '全部灰度值：'); disp(num2str(se'));
disp( ['air灰度值：', num2str(gray_air)] )
disp( ['water灰度值为：', num2str( gray_water)] )
disp( ['ske灰度值为：', num2str( gray_ske)] )

CTo = D;
CTo( CTo ~= gray_water ) = 0;
CTo = bwperim( CTo ); 

Dx = uint16( [] );
Dy = Dx;
Dz = Dx;
hWaitbar = waitbar(0, 'calculating the xyz .......') ; %建立进度条
for k = 1 : z %计算骨架坐标值
    [x, y] = find( CTo(:, :, k) > 0 );
    Dx = cat(1, Dx, x);
    Dy = cat(1, Dy, y);
    Dz = cat(1, Dz, ones( length( x ), 1) * k );
    if mod(k, 20) == 0
        waitbar( k/z, hWaitbar,  'calculating the xyz .......' ); %进度
    end
end
close(hWaitbar) %关闭进度条
clear CTo
Dx = int16( Dx ); 
Dy = int16( Dy );
Dz = int16( Dz );
num_D = length( Dx );

filt_x = Dx == 1 | Dx == n; 
filt_y = Dy == 1 | Dy == m;
filt_z = Dz == 1 | Dz == z;
filt_xyz = filt_x | filt_y | filt_z; % 预处理边界
clear  filt_x filt_y filt_z II list  Line x y 

% 进行water-air, water_ske计算======================================
F = zeros( length(Dx), 2 ); % air, ske
F = F > 0; % 初始化为否logical
VCT.wa = zeros( num_D, 3, 'single'); %water_air
VCT.ws = VCT.wa; % water_ske

%气液固三相界面，water为基底，
hWaitbar = waitbar(0, 'calculating the surface points .......') ; %建立进度条
for i = 1 : length( add )
    xyz = [ Dx + add(i, 1), Dy + add(i, 2), Dz + add(i, 3) ]; %第i临域坐标
    xyz( filt_xyz, : ) = 1; % 超过边界为（1,1,1）
    xyz = int32( xyz ); % 防止数溢出
    xyz = xyz(:, 1) + ( xyz(:, 2) - 1 ) * n + ( xyz(:, 3) - 1 ) * n * m; % D line列号
    xyz = D( xyz ); % 第i临域灰度值
        
    xyz_water = xyz == gray_water; % 气液固三相界面，先按液液界面计算，最后在筛选出三相交点
    xyz_water( filt_xyz ) = 0; % 超出边界的为0
    F(:, 1) = F(:, 1) | xyz_water; %并集第i临域
        
    xyz_ske = xyz == gray_ske; 
    xyz_ske( filt_xyz ) = 0; 
    F(:, 2) = F(:, 2) | xyz_ske;
    % 计算有气液表面张力引起的附加应力=========
    for j = 1 : 3
        vcti = ones( num_D, 1, 'single') * Vct_add(i, j);
        
        vcti_ws = vcti;
        vcti_ws( ~xyz_ske ) = 0; %计算固液界面张力
        VCT.ws(:, j) = VCT.ws(:, j) + vcti_ws;
        
        vcti_wa = vcti;
        vcti_wa( ~xyz_water ) = 0; %计算气液界面张力
        VCT.wa(:, j) = VCT.wa(:, j) + vcti_wa;
    end
    
    waitbar( i/length(add), hWaitbar, num2str(toc) ); %进度
end
close(hWaitbar) %关闭进度条
f_wa = F(:, 1) & F(:, 2); %筛选固液气节点
f_ws = F(:, 2) == 1;  %筛选固液节点
disp( [ '气液/固液面积比值= ', num2str( length( find( f_wa>0)) / length( find(F(:,2) > 0 ) ) ) ] )
% 记录作用力点的坐标值
VCT.xyz_wa = [ Dx(f_wa), Dy(f_wa), Dz(f_wa) ]; % 固液气坐标
VCT.xyz_ws = [ Dx(f_ws), Dy(f_ws), Dz(f_ws) ]; %固液坐标
clear Dx Dy Dz D xyz_ske xyz_air vcti_wa vcti_ws %==========================

VCT.ws = VCT.ws( f_ws, :); %过滤掉无
VCT.ws = -VCT.ws; %water提供的是负压
NN = sqrt( VCT.ws(:, 1) .* VCT.ws(:, 1) + VCT.ws(:, 2) .* VCT.ws(:, 2) + VCT.ws(:, 3) .* VCT.ws(:, 3) ); %计算模
VCT.ws = [ VCT.ws(:, 1) ./ NN, VCT.ws(:, 2) ./ NN, VCT.ws(:, 3) ./ NN ];  %归一化法向量
VCT.ws( isnan( VCT.ws ) ) = 0; %筛除nan，0向量
F_ws = SumSwcc(VCT.ws) / 6;

VCT.wa =  VCT.wa( f_wa==1, :);
NN = sqrt(  VCT.wa(:, 1) .*  VCT.wa(:, 1) +  VCT.wa(:, 2) .*  VCT.wa(:, 2) +  VCT.wa(:, 3) .*  VCT.wa(:, 3) ); %计算模
VCT.wa = [  VCT.wa(:, 1) ./ NN,  VCT.wa(:, 2) ./ NN,  VCT.wa(:, 3) ./ NN ];  %归一化法向量
VCT.wa( isnan(  VCT.wa ) ) = 0; %筛除nan，0向量
F_wa = SumSwcc(VCT.wa) / 6;

VCT.F_ws = F_ws;
VCT.F_wa = F_wa;
vct_file = strcat( File_read, 'VCT.mat' ) ;
save( vct_file, 'VCT', '-v7.3' )
disp( [' 固液球应力= ', num2str(F_ws)])
disp( [' 气液球应力= ', num2str(F_wa)])
disp( '===============end==============' )
end

function q = SumSwcc(Vct) %自带sum出现错误
n = length( Vct );
m = floor( n / 100 );
cut = 1 : m : n;
cut(end) = n;

q = zeros( length(cut)-1, 1);
for i = 1 : length(cut) - 1
    if i == 1
        q(i) = sum( sum( abs( Vct( 1: cut(i), :) ) ) );
    else
        q(i) = sum( sum( abs( Vct( cut(i)+1 : cut(i+1), :) ) ) );
    end
end
q = sum(q);
end

