function SWCCSimulate( File_read, File_save, R, n, num, Plan )

% R is the matrix of SWCC range, like : R = [1, 2, 3, 4, 5, 6, ...]
% n is the part of air, and its gray value can note be 255
% num is the memory cut number, if num is bigger, which can reduce the
    % memory requirement
% Plan = [ SWCC，孔径统计，连通矩阵 ]，用0-1标记
% air-0，water-100，ske-255

p = gcp( 'nocreate' );
delete( p ); %关闭并行计算释放内存

% 保存结果文件夹===================================
if strcmp( Plan, 'SWCC Simulate' )
    SWCCCal( File_read, File_save, R, n, num );
end

if strcmp( Plan, 'SWCC Pore' )
    PoreStatistics( File_read, R, num );
end

end

function SWCCCal( File_read, File_save, R, n, num )
File_save = strcat( File_save, '\');
[~, ~, ~] = mkdir( strcat( File_save,  'SWCC' ) ); % 保存D, z, 结果
File_save = strcat( File_save, 'SWCC\' ); 

cf_swcc = strcat( File_save, 'swcc.mat');
D = importdata( File_read ); % 导入数据

% 标记骨架和孔隙===================================
[x, y, z] = size( D );
Permute = z > max( [x, y] );
if Permute 
    D = permute( D, [1, 3, 2] ); %解决立方体问题
    [~, ~, z] = size( D );
end
list = round( rand( round(z/10), 1 ) * z );    %随机抽取1/10
list( list <  1 )= [];                 list( list > z ) = [];
se = unique( D(:, :, list) );      Chose = se( n );

D = BlockAssignment( D, Chose, 255, '~=', num ); % 骨架
D = BlockAssignment( D, 255, 1, '<', num ); % 孔隙
D = uint8( D ); % 节省内存
file_D = strcat( File_save, 'D.mat' ); %临时存储D变量，节省内存
save( file_D, 'D', '-v7.3' )

vpore = BlockFind( D, 1, num ); %计算孔隙总体积
swcc = zeros( length(R), 2 ); %记录[半径，相对含水率]
swcc(:, 1) = R; %弯液面半径

tic
hWaitbar = waitbar(0, 'simulating SWCC .......') ; %建立进度条========
for i = 1 : length( R )
    
    file_I = strcat( File_save, 'r_', num2str( R(i) ), '_SWCC.mat' );
    if exist( file_I, 'file' ) %是否计算过
        I = importdata( file_I );
        swcc(i, 2) = BlockFind( I, 100, num ); %计算液体体积
    else % 还未计算
        D = importdata( file_D ); 
        I = D; %加载初始孔隙矩阵
        clear D
    
        I = BlockAssignment( I, 255, 0, '==', num ); % 只留孔隙
        r = Strel3d( 2*R( i ) );%生成球形的结构元素，半径
        I = imopen( I, r ); %进行开运算
        I = BlockAssignment( I, 255, 0, '==', num ); % 侵入骨架部分置0，多余？

        D = importdata( file_D ); 
        I = I + D; % 水1，空气2，骨架255
        clear D
    
        % 凸显灰度==========================  
        I = BlockAssignment( I, 1, 100, '==', num ); % 标记为液体
        I = BlockAssignment( I, 2, 0, '==', num ); % 标记为孔隙 
        swcc(i, 2) = BlockFind( I, 100, num ); %计算液体体积
    
        % 保存结果=============================================
        if Permute%解决立方体问题
            I = permute( I, [1, 3, 2] );
            [~, ~, z] = size( I );
        end
    
        file_I = strcat( File_save, 'r_', num2str( R(i) ), '_SWCC.mat' );
        save( file_I, 'I', '-v7.3' )
    
        hWaitbar2 = waitbar(0, 'Saving SWCC results .......') ; %建立进度条
        File_save2 = strcat( File_save, 'r_', num2str(R(i)), '_SWCC' );
        [~, ~, ~] = mkdir( strcat( File_save, 'r_', num2str(R(i)), '_SWCC' ) ); % 保存D, z, 结果
        
        for j = 1 : z
            imwrite( uint8( I(:, :, j) ), strcat( File_save2, '\',  num2str(j), '.tif' ) ); %保存处理后的tif
            if mod(j, round(z/100) ) == 0
                waitbar( j/z, hWaitbar2 ); %进度
            end
        end
        close(hWaitbar2)
    end
    
    swcc(i, 2) = 100 * swcc(i, 2 ) / vpore;
    save( cf_swcc, 'swcc' );

    
    waitbar( i/length(R), hWaitbar, ['NO.', num2str(i), ' time= ', num2str(toc) ] ); %进度
    if swcc(i, 2) >= 100 %水已经饱和，结束计算
        break
    end
    
end
delete( file_D );
close(hWaitbar)
figure, plot( 1./ swcc(:, 1), swcc(:, 2) ); title( ' SWCC simulation based on CT ' );
end

function PoreStatistics( File_save, R, num )
% 统计孔径分布于连通性
% D标记孔径大小矩阵，P孔径统计，C连通矩阵

file_D = strcat( File_save, 'r_', num2str( R(1) ), '_SWCC.mat' );
D = importdata( file_D ); % 初始化并标记孔径大小矩阵
P = zeros( length( R ), 2 ); %记录半径和体积数 

P(:, 1) = R(:);
P(1, 2) = BlockFind( D, 100, num ); %计算R(1)孔隙体积
D = BlockAssignment( D, 100, R(1), '==', num ); % 标记孔隙R(1)
hWaitbar2 = waitbar(0, '统计孔径分布 .......') ; %建立进度条
for i = 1 : length( R ) - 1
    file_D1 = strcat( File_save, 'r_', num2str( R(i) ), '_SWCC.mat' );
    file_D2 = strcat( File_save, 'r_', num2str( R(i+1) ), '_SWCC.mat' );
    D1 = importdata( file_D1 );
    D2 = importdata( file_D2 );
    
    Di = D2 - D1;
    clear D1 D2
    P(i+1, 2) = BlockFind( Di, 100, num ); %计算R(i)孔隙体积
    Di = BlockAssignment( Di, 100, R(i+1), '==', num ); % 标记孔隙R(i+1)
    D = D + Di; % 累计孔径半径，骨架依旧是255
    waitbar( i/(length(R) - 1), hWaitbar2 ); %进度
end
clear Di
close( hWaitbar2 ); %进度

% 保存结果文件夹===================================
File_Pore = strcat( File_save, '\');
[~, ~, ~] = mkdir( strcat( File_Pore,  'Pore' ) ); % 保存D, z, 结果
File_Pore = strcat( File_Pore, 'Pore\' ); 
D_pore = strcat( File_Pore, 'Pore_D.mat');
P_pore = strcat( File_Pore, 'Pore_P.mat');

save( D_pore, 'D', '-v7.3');
save( P_pore, 'P', '-v7.3' );

hWaitbar2 = waitbar(0, 'Saving SWCC results .......') ; %建立进度条
for j = 1 : size(D, 3)
    imwrite( uint8( D(:, :, j) ), strcat( File_Pore, '\',  num2str(j), '.tif' ) ); %保存处理后的tif
    if mod(j, round(size(D, 3)/100) ) == 0
        waitbar( j/size(D, 3), hWaitbar2 ); %进度
    end
end
close( hWaitbar2 );
figure, plot( P(:, 1), P(:, 2) ); title( '孔径分布曲线' )
end

function se = Strel3d(sesize) %生成球形结构
sw = ( sesize - 1 ) / 2; 
ses2 = ceil( sesize / 2 );            % ceil sesize to handle odd diameters
[y, x, z] = meshgrid( -sw : sw, -sw : sw, -sw : sw ); 
m = sqrt( x.^2 + y.^2 + z.^2); 
b = ( m <= m( ses2, ses2, sesize ) ); 
se = strel( 'arbitrary', b );
end

function D = BlockAssignment( D, a, b, char, n )
% 分块替换赋值
[~, ~, z] = size( D );
z_cut = round( z/n ); %矩阵3分段点
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
% 分块替换赋值
[~, ~, z] = size( D );
z_cut = round( z/n ); %矩阵3分段点
v = 0; %累计记录指定数值
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

