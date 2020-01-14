function SWCCForce( File_read, WAK )
tic
% File_read, read tif file path
% WAK = [ water, air, ske ], the No of gray value
% Vct is the save data.

p = gcp( 'nocreate' );
delete( p ); %�رղ��м����ͷ��ڴ�

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
                 add(end+1, :) = [ i, j, k ]; %����
                 Vct_add(end+1, :) = add(end, :) / norm( add(end, :) ); %��������
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
num_file = min( num_file ); %�����ļ���С��

hWaitbar = waitbar(0, 'reading the images .......') ; %����������
for i = 1 : z
    fileName = str2num( cell2mat(regexp(list(i).name,'\d', 'match')) );
    II = imread([File_read, list(i).name]);
    D(:, :, fileName - num_file + 1 ) = II; % file_path����ת����������ʽ
    if mod(i, 20) == 0
        waitbar( i/z, hWaitbar,  'reading the images .......' ); %����
    end
end 
D( D == 101 ) = 100; %�ͺ�ĻҶ�ֵҲΪwater
close(hWaitbar) %�رս�����

se = unique( D ); %Һ��Ҷ�ֵ
gray_ske = se( ske ); %�ǼܻҶ�ֵ
gray_water = se( water );
gray_air = se( air ); 
disp( 'ȫ���Ҷ�ֵ��'); disp(num2str(se'));
disp( ['air�Ҷ�ֵ��', num2str(gray_air)] )
disp( ['water�Ҷ�ֵΪ��', num2str( gray_water)] )
disp( ['ske�Ҷ�ֵΪ��', num2str( gray_ske)] )

CTo = D;
CTo( CTo ~= gray_water ) = 0;
CTo = bwperim( CTo ); 

Dx = uint16( [] );
Dy = Dx;
Dz = Dx;
hWaitbar = waitbar(0, 'calculating the xyz .......') ; %����������
for k = 1 : z %����Ǽ�����ֵ
    [x, y] = find( CTo(:, :, k) > 0 );
    Dx = cat(1, Dx, x);
    Dy = cat(1, Dy, y);
    Dz = cat(1, Dz, ones( length( x ), 1) * k );
    if mod(k, 20) == 0
        waitbar( k/z, hWaitbar,  'calculating the xyz .......' ); %����
    end
end
close(hWaitbar) %�رս�����
clear CTo
Dx = int16( Dx ); 
Dy = int16( Dy );
Dz = int16( Dz );
num_D = length( Dx );

filt_x = Dx == 1 | Dx == n; 
filt_y = Dy == 1 | Dy == m;
filt_z = Dz == 1 | Dz == z;
filt_xyz = filt_x | filt_y | filt_z; % Ԥ����߽�
clear  filt_x filt_y filt_z II list  Line x y 

% ����water-air, water_ske����======================================
F = zeros( length(Dx), 2 ); % air, ske
F = F > 0; % ��ʼ��Ϊ��logical
VCT.wa = zeros( num_D, 3, 'single'); %water_air
VCT.ws = VCT.wa; % water_ske

%��Һ��������棬waterΪ���ף�
hWaitbar = waitbar(0, 'calculating the surface points .......') ; %����������
for i = 1 : length( add )
    xyz = [ Dx + add(i, 1), Dy + add(i, 2), Dz + add(i, 3) ]; %��i��������
    xyz( filt_xyz, : ) = 1; % �����߽�Ϊ��1,1,1��
    xyz = int32( xyz ); % ��ֹ�����
    xyz = xyz(:, 1) + ( xyz(:, 2) - 1 ) * n + ( xyz(:, 3) - 1 ) * n * m; % D line�к�
    xyz = D( xyz ); % ��i����Ҷ�ֵ
        
    xyz_water = xyz == gray_water; % ��Һ��������棬�Ȱ�ҺҺ������㣬�����ɸѡ�����ཻ��
    xyz_water( filt_xyz ) = 0; % �����߽��Ϊ0
    F(:, 1) = F(:, 1) | xyz_water; %������i����
        
    xyz_ske = xyz == gray_ske; 
    xyz_ske( filt_xyz ) = 0; 
    F(:, 2) = F(:, 2) | xyz_ske;
    % ��������Һ������������ĸ���Ӧ��=========
    for j = 1 : 3
        vcti = ones( num_D, 1, 'single') * Vct_add(i, j);
        
        vcti_ws = vcti;
        vcti_ws( ~xyz_ske ) = 0; %�����Һ��������
        VCT.ws(:, j) = VCT.ws(:, j) + vcti_ws;
        
        vcti_wa = vcti;
        vcti_wa( ~xyz_water ) = 0; %������Һ��������
        VCT.wa(:, j) = VCT.wa(:, j) + vcti_wa;
    end
    
    waitbar( i/length(add), hWaitbar, num2str(toc) ); %����
end
close(hWaitbar) %�رս�����
f_wa = F(:, 1) & F(:, 2); %ɸѡ��Һ���ڵ�
f_ws = F(:, 2) == 1;  %ɸѡ��Һ�ڵ�
disp( [ '��Һ/��Һ�����ֵ= ', num2str( length( find( f_wa>0)) / length( find(F(:,2) > 0 ) ) ) ] )
% ��¼�������������ֵ
VCT.xyz_wa = [ Dx(f_wa), Dy(f_wa), Dz(f_wa) ]; % ��Һ������
VCT.xyz_ws = [ Dx(f_ws), Dy(f_ws), Dz(f_ws) ]; %��Һ����
clear Dx Dy Dz D xyz_ske xyz_air vcti_wa vcti_ws %==========================

VCT.ws = VCT.ws( f_ws, :); %���˵���
VCT.ws = -VCT.ws; %water�ṩ���Ǹ�ѹ
NN = sqrt( VCT.ws(:, 1) .* VCT.ws(:, 1) + VCT.ws(:, 2) .* VCT.ws(:, 2) + VCT.ws(:, 3) .* VCT.ws(:, 3) ); %����ģ
VCT.ws = [ VCT.ws(:, 1) ./ NN, VCT.ws(:, 2) ./ NN, VCT.ws(:, 3) ./ NN ];  %��һ��������
VCT.ws( isnan( VCT.ws ) ) = 0; %ɸ��nan��0����
F_ws = SumSwcc(VCT.ws) / 6;

VCT.wa =  VCT.wa( f_wa==1, :);
NN = sqrt(  VCT.wa(:, 1) .*  VCT.wa(:, 1) +  VCT.wa(:, 2) .*  VCT.wa(:, 2) +  VCT.wa(:, 3) .*  VCT.wa(:, 3) ); %����ģ
VCT.wa = [  VCT.wa(:, 1) ./ NN,  VCT.wa(:, 2) ./ NN,  VCT.wa(:, 3) ./ NN ];  %��һ��������
VCT.wa( isnan(  VCT.wa ) ) = 0; %ɸ��nan��0����
F_wa = SumSwcc(VCT.wa) / 6;

VCT.F_ws = F_ws;
VCT.F_wa = F_wa;
vct_file = strcat( File_read, 'VCT.mat' ) ;
save( vct_file, 'VCT', '-v7.3' )
disp( [' ��Һ��Ӧ��= ', num2str(F_ws)])
disp( [' ��Һ��Ӧ��= ', num2str(F_wa)])
disp( '===============end==============' )
end

function q = SumSwcc(Vct) %�Դ�sum���ִ���
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

