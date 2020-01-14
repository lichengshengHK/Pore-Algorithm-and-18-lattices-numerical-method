function SWCCSimulate( File_read, File_save, R, n, num, Plan )

% R is the matrix of SWCC range, like : R = [1, 2, 3, 4, 5, 6, ...]
% n is the part of air, and its gray value can note be 255
% num is the memory cut number, if num is bigger, which can reduce the
    % memory requirement
% Plan = [ SWCC���׾�ͳ�ƣ���ͨ���� ]����0-1���
% air-0��water-100��ske-255

p = gcp( 'nocreate' );
delete( p ); %�رղ��м����ͷ��ڴ�

% �������ļ���===================================
if strcmp( Plan, 'SWCC Simulate' )
    SWCCCal( File_read, File_save, R, n, num );
end

if strcmp( Plan, 'SWCC Pore' )
    PoreStatistics( File_read, R, num );
end

end

function SWCCCal( File_read, File_save, R, n, num )
File_save = strcat( File_save, '\');
[~, ~, ~] = mkdir( strcat( File_save,  'SWCC' ) ); % ����D, z, ���
File_save = strcat( File_save, 'SWCC\' ); 

cf_swcc = strcat( File_save, 'swcc.mat');
D = importdata( File_read ); % ��������

% ��ǹǼܺͿ�϶===================================
[x, y, z] = size( D );
Permute = z > max( [x, y] );
if Permute 
    D = permute( D, [1, 3, 2] ); %�������������
    [~, ~, z] = size( D );
end
list = round( rand( round(z/10), 1 ) * z );    %�����ȡ1/10
list( list <  1 )= [];                 list( list > z ) = [];
se = unique( D(:, :, list) );      Chose = se( n );

D = BlockAssignment( D, Chose, 255, '~=', num ); % �Ǽ�
D = BlockAssignment( D, 255, 1, '<', num ); % ��϶
D = uint8( D ); % ��ʡ�ڴ�
file_D = strcat( File_save, 'D.mat' ); %��ʱ�洢D��������ʡ�ڴ�
save( file_D, 'D', '-v7.3' )

vpore = BlockFind( D, 1, num ); %�����϶�����
swcc = zeros( length(R), 2 ); %��¼[�뾶����Ժ�ˮ��]
swcc(:, 1) = R; %��Һ��뾶

tic
hWaitbar = waitbar(0, 'simulating SWCC .......') ; %����������========
for i = 1 : length( R )
    
    file_I = strcat( File_save, 'r_', num2str( R(i) ), '_SWCC.mat' );
    if exist( file_I, 'file' ) %�Ƿ�����
        I = importdata( file_I );
        swcc(i, 2) = BlockFind( I, 100, num ); %����Һ�����
    else % ��δ����
        D = importdata( file_D ); 
        I = D; %���س�ʼ��϶����
        clear D
    
        I = BlockAssignment( I, 255, 0, '==', num ); % ֻ����϶
        r = Strel3d( 2*R( i ) );%�������εĽṹԪ�أ��뾶
        I = imopen( I, r ); %���п�����
        I = BlockAssignment( I, 255, 0, '==', num ); % ����Ǽܲ�����0�����ࣿ

        D = importdata( file_D ); 
        I = I + D; % ˮ1������2���Ǽ�255
        clear D
    
        % ͹�ԻҶ�==========================  
        I = BlockAssignment( I, 1, 100, '==', num ); % ���ΪҺ��
        I = BlockAssignment( I, 2, 0, '==', num ); % ���Ϊ��϶ 
        swcc(i, 2) = BlockFind( I, 100, num ); %����Һ�����
    
        % ������=============================================
        if Permute%�������������
            I = permute( I, [1, 3, 2] );
            [~, ~, z] = size( I );
        end
    
        file_I = strcat( File_save, 'r_', num2str( R(i) ), '_SWCC.mat' );
        save( file_I, 'I', '-v7.3' )
    
        hWaitbar2 = waitbar(0, 'Saving SWCC results .......') ; %����������
        File_save2 = strcat( File_save, 'r_', num2str(R(i)), '_SWCC' );
        [~, ~, ~] = mkdir( strcat( File_save, 'r_', num2str(R(i)), '_SWCC' ) ); % ����D, z, ���
        
        for j = 1 : z
            imwrite( uint8( I(:, :, j) ), strcat( File_save2, '\',  num2str(j), '.tif' ) ); %���洦����tif
            if mod(j, round(z/100) ) == 0
                waitbar( j/z, hWaitbar2 ); %����
            end
        end
        close(hWaitbar2)
    end
    
    swcc(i, 2) = 100 * swcc(i, 2 ) / vpore;
    save( cf_swcc, 'swcc' );

    
    waitbar( i/length(R), hWaitbar, ['NO.', num2str(i), ' time= ', num2str(toc) ] ); %����
    if swcc(i, 2) >= 100 %ˮ�Ѿ����ͣ���������
        break
    end
    
end
delete( file_D );
close(hWaitbar)
figure, plot( 1./ swcc(:, 1), swcc(:, 2) ); title( ' SWCC simulation based on CT ' );
end

function PoreStatistics( File_save, R, num )
% ͳ�ƿ׾��ֲ�����ͨ��
% D��ǿ׾���С����P�׾�ͳ�ƣ�C��ͨ����

file_D = strcat( File_save, 'r_', num2str( R(1) ), '_SWCC.mat' );
D = importdata( file_D ); % ��ʼ������ǿ׾���С����
P = zeros( length( R ), 2 ); %��¼�뾶������� 

P(:, 1) = R(:);
P(1, 2) = BlockFind( D, 100, num ); %����R(1)��϶���
D = BlockAssignment( D, 100, R(1), '==', num ); % ��ǿ�϶R(1)
hWaitbar2 = waitbar(0, 'ͳ�ƿ׾��ֲ� .......') ; %����������
for i = 1 : length( R ) - 1
    file_D1 = strcat( File_save, 'r_', num2str( R(i) ), '_SWCC.mat' );
    file_D2 = strcat( File_save, 'r_', num2str( R(i+1) ), '_SWCC.mat' );
    D1 = importdata( file_D1 );
    D2 = importdata( file_D2 );
    
    Di = D2 - D1;
    clear D1 D2
    P(i+1, 2) = BlockFind( Di, 100, num ); %����R(i)��϶���
    Di = BlockAssignment( Di, 100, R(i+1), '==', num ); % ��ǿ�϶R(i+1)
    D = D + Di; % �ۼƿ׾��뾶���Ǽ�������255
    waitbar( i/(length(R) - 1), hWaitbar2 ); %����
end
clear Di
close( hWaitbar2 ); %����

% �������ļ���===================================
File_Pore = strcat( File_save, '\');
[~, ~, ~] = mkdir( strcat( File_Pore,  'Pore' ) ); % ����D, z, ���
File_Pore = strcat( File_Pore, 'Pore\' ); 
D_pore = strcat( File_Pore, 'Pore_D.mat');
P_pore = strcat( File_Pore, 'Pore_P.mat');

save( D_pore, 'D', '-v7.3');
save( P_pore, 'P', '-v7.3' );

hWaitbar2 = waitbar(0, 'Saving SWCC results .......') ; %����������
for j = 1 : size(D, 3)
    imwrite( uint8( D(:, :, j) ), strcat( File_Pore, '\',  num2str(j), '.tif' ) ); %���洦����tif
    if mod(j, round(size(D, 3)/100) ) == 0
        waitbar( j/size(D, 3), hWaitbar2 ); %����
    end
end
close( hWaitbar2 );
figure, plot( P(:, 1), P(:, 2) ); title( '�׾��ֲ�����' )
end

function se = Strel3d(sesize) %�������νṹ
sw = ( sesize - 1 ) / 2; 
ses2 = ceil( sesize / 2 );            % ceil sesize to handle odd diameters
[y, x, z] = meshgrid( -sw : sw, -sw : sw, -sw : sw ); 
m = sqrt( x.^2 + y.^2 + z.^2); 
b = ( m <= m( ses2, ses2, sesize ) ); 
se = strel( 'arbitrary', b );
end

function D = BlockAssignment( D, a, b, char, n )
% �ֿ��滻��ֵ
[~, ~, z] = size( D );
z_cut = round( z/n ); %����3�ֶε�
for i = 1 : n
    if i == 1
        star_z = 1;
    else
        star_z = (i - 1) * z_cut + 1;
    end
    if i == n
        end_z = z;
    else
        end_z = i * z_cut;
    end

    Di = D( :, :, star_z : end_z );
    if char == '=='
        Di( Di == a ) = b;
    elseif char == '~='
        Di( Di ~= a ) = b;
    elseif char == '<'
        Di( Di < a ) = b;
    end
    D( :, :, star_z : end_z ) = Di;
end
end

function v = BlockFind( D, a, n )
% �ֿ��滻��ֵ
[~, ~, z] = size( D );
z_cut = round( z/n ); %����3�ֶε�
v = 0; %�ۼƼ�¼ָ����ֵ
for i = 1 : n
    if i == 1
        star_z = 1;
    else
        star_z = (i - 1) * z_cut + 1;
    end
    if i == n
        end_z = z;
    else
        end_z = i * z_cut;
    end

    Di = D( :, :, star_z : end_z );
    v = v + length( find( Di == a ) );
end
end

