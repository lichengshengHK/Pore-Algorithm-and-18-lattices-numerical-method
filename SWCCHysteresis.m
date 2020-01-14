function dw = SWCCHysteresis( File_read, WAK )
p = gcp( 'nocreate' );
delete( p ); %�رղ��м����ͷ��ڴ�

% File_read, is read the tif file path
% WAK = [ water, air, ske, hys of part ], the No of gray value
% if  WAK(4) = air, the simulation is Drying path
% if  WAK(4) = water, the simulation is wettying path

water = WAK(1);
air = WAK(2);
ske = WAK(3);
HysPart = WAK(4);
File_read = strcat( File_read, '\' );

if HysPart == air %��ǷǽӴ��ױߵĿ���
    File_save = strcat( File_read,  'Drying path' );
    [~, ~, ~] = mkdir( strcat( File_read, 'Drying path') ); % ����D, z, ���
elseif HysPart == water %��ǷǽӴ��ױߵ�ˮ
    File_save = strcat( File_read,  'Wetting path' );
    [~, ~, ~] = mkdir( strcat( File_read, 'Wetting path') ); % ����D, z, ���
end

list = dir([File_read, '*.tif']);
II = imread([File_read, list(1).name]);
[x, y] = size(II);
z = length(list);
D = zeros(x, y, z, 'uint8' );

% ���ͼƬslice=========================================
num_file =  zeros( z, 1);

for i = 1 : z
    num_file( i ) = str2num( cell2mat(regexp(list(i).name,'\d', 'match')) );
end
num_file = min( num_file ); %������С�ļ���

hWaitbar = waitbar(0, 'reading the images .......') ; %����������
for i = 1 : z
    fileName = str2num( cell2mat(regexp(list(i).name,'\d', 'match')) );
    II = imread([File_read, list(i).name]);
    D(:, :, fileName - num_file + 1 ) = II; % file_path����ת����������ʽ
    if mod(i, 50)
        waitbar( i/z, hWaitbar ); %����
    end
end
close(hWaitbar) %�رս�����
DD = D;

se = unique( D ); %Һ��Ҷ�ֵ
gray_ske = se( ske ); %�ǼܻҶ�ֵ
gray_water = se( water );
gray_air = se( air );

D( DD == gray_ske ) = 255;  %��һ��
D( DD == gray_air ) = 0;
D( DD == gray_water ) = 100;
DD = D;

V_pore = x * y * z - length( find( D == 255) ); %��϶���
if HysPart == air %��ǷǽӴ��ױߵĿ���
    D = D == 0; %�޳���air����
elseif HysPart == water %��ǷǽӴ��ױߵ�ˮ
    D = D == 100;
end

% ����ά���������̬ѧ���==================================
%D = int32( bwlabeln(D, num) );
hWaitbar = waitbar(0, 'Bwconncomp 3D image .......') ; %����������
CC = bwconncomp(D, 6); %��ʡ�ڴ�
D = D * 0; %��ʼ��
max_n = length( CC.PixelIdxList ); %���������ͨ�����ظ���
dd = floor( max_n / 50 ); %���
for i = 1 : max_n %��ֵ��D����
    Line = CC.PixelIdxList{i};
    [ ~, ~, Dz ] = ind2sub( [x, y, z], Line ); %��ȡ��i����ͨ������ֵ
    Dz = int16( Dz );
    
    if min( Dz ) > 1 %����ͨ��δ��ͨ�ױ߽�
        if HysPart == air %��ǷǽӴ��ױߵĿ���
            D( Line ) = 1; %���Ϊ�ͺ�Һ��,1, air->water
        elseif HysPart == water %��ǷǽӴ��ױߵ�ˮ
            D( Line ) = 2; %���Ϊ�ͺ������water->air
        end
        if mod( i, dd )
            waitbar( i/max_n, hWaitbar ); %����
        end
    end
end
close(hWaitbar) %�رս�����

DD( D == 1 ) = 100;  %Drying path
DD( D == 2 ) = 0; % wetting path
clear D

dw = 100 * length( find( DD == 100 ) ) / V_pore; %�ͺ��������Ͷ�

hWaitbar = waitbar(0, 'Saving hysteresis image .......') ; %����������
for i = 1 : z
    II = DD( :, :, i );
    imwrite( uint8( II ), strcat( File_save, '\',  num2str(i), '.tif' ) ); %���洦���ı߽�
    if mod( i, 100 )
        waitbar( i/z, hWaitbar ); %����
    end
end
close(hWaitbar) %�رս�����
end