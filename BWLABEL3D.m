function varargout = BWLABEL3D(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @BWLABEL3D_OpeningFcn, ...
    'gui_OutputFcn',  @BWLABEL3D_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
end


% --- Executes just before BWLABEL3D is made visible.
function BWLABEL3D_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
end


% --- Outputs from this function are returned to the command line.
function varargout = BWLABEL3D_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;
end


function Part_material_Callback(hObject, eventdata, handles)
input = get(hObject, 'String' );
if (isempty( input))
    set(hObject, 'String', '1'); %���ϳɷ�
end
end


% --- Executes during object creation, after setting all properties.
function Part_material_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function OpneR_Callback(hObject, eventdata, handles)
input = get(hObject, 'String' );
if (isempty( input))
    set(hObject, 'String', '2'); %������뾶
end
end


% --- Executes during object creation, after setting all properties.
function OpneR_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in Data.
function Data_Callback(hObject, eventdata, handles)
PathName = uigetdir; %��ȡ�ļ���·��
PathName = [ PathName, '\' ];
set(handles.ShowData, 'string' , PathName);
end



function ShowData_Callback(hObject, eventdata, handles)

end


% --- Executes during object creation, after setting all properties.
function ShowData_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function ShowBl_Callback(hObject, eventdata, handles)
end


% --- Executes during object creation, after setting all properties.
function ShowBl_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in if_output.
function if_output_Callback(hObject, eventdata, handles)
% �Ƿ���������ͨ��϶
end


% --- Executes on button press in Star_BL.
function Star_BL_Callback(hObject, eventdata, handles)
n = double( str2num( get( handles.Part_material, 'String' ) ) ); %��Ҫ��ǵĲ���
R = round( double( str2num( get( handles.OpneR, 'String' ) ) ) ); %������뾶
File_read = get( handles.ShowData, 'string' );
if_output = get( handles.if_output, 'Value' );
af = Bwlabel3D( n, R, File_read, if_output); %��n�ɷֽ��б��
set(handles.ShowBl, 'String', num2str(af) ); %������뾶
end


% --- Executes on button press in BWLABEL3DParticle.
function BWLABEL3DParticle_Callback(hObject, eventdata, handles)
n = double( str2num( get( handles.Part_material, 'String' ) ) ); %��Ҫ��ǵĲ���
R = round( double( str2num( get( handles.OpneR, 'String' ) ) ) ); %������뾶
File_read = get( handles.ShowData, 'string' );
BWLABEL3DParticle( n, R, File_read); %��n�ɷֽ��п������
end



function af = Bwlabel3D( n, R, File_read, if_output)
p = gcp( 'nocreate' );
delete( p ); %�رղ��м����ͷ��ڴ�
% numΪ��ͨ��,��άһ��Ϊ6
% nΪѡȡ�Ĳ���
% bigΪ����ĵڼ�����ͨ��϶��
File_save = strcat( File_read, num2str(n), '_part_D' );
[~, ~, ~] = mkdir( strcat( File_read, num2str(n), '_part_D') ); % ����D, z, ���

% ������̬����bwlabeln���п��ٷ���
list = dir( [File_read, '*.tif'] );
get_num = round( length(list)/2 );
if get_num < 1
    get_num = 1;
end
II = imread([File_read, list(get_num).name]);
[x, y] = size(II);
z = length(list);
CC = zeros(x, y, z, 'uint8' );
for z = 1 : length( list )
    CC(:, :, z ) = imread([File_read, list(z).name]);
end
se = unique( CC );
Chose = se( n ); %ѡȡ�Ĳ���

CC = zeros(x, y, z, 'uint8' );
% ���ͼƬslice============================================
% ������С�ļ�����
num_file =  zeros( z, 1);

for i = 1 : z
    num_file( i ) = str2num( cell2mat(regexp(list(i).name,'\d', 'match')) );
end
num_file = min( num_file ); %������С�ļ���

hWaitbar = waitbar(0, 'import the images .......') ; %����������
for i = 1 : z
    fileName = str2num( cell2mat(regexp(list(i).name,'\d', 'match')) );%�޳��������ַ���ת��������
    II = imread([File_read, list(i).name]);
    I = II;
    I( II ~= Chose ) = nan;
    I( II == Chose ) = 1;
    I( isnan( I ) ) = 0; %�޳��Ǳ�ѡȡ�Ĳ���
    CC(:, :, fileName - num_file + 1 ) = I; % file_path����ת����������ʽ
    if mod(i, round(z/1e2) ) == 0
        waitbar( i/z, hWaitbar ); %����
    end
end
close(hWaitbar) %�رս�����
Permute = z > max( [x, y] );
if Permute
    CC = permute( CC, [1, 3, 2] ); %�������������
    [x, y, z] = size( CC );
end

if R < 1; R = 1; end
r = Strel3d( 2*R );%�������εĽṹԪ�أ��뾶
CC = imopen( CC, r ); %���п�����

clear II se Chose num_file
% ����ά���������̬ѧ���==================================
%D = int32( bwlabeln(D, num) );
hWaitbar = waitbar(0, 'Bwconncomp 3D image .......') ; %����������
CC = bwconncomp(CC, 6); %��ʡ�ڴ�
max_n = length( CC.PixelIdxList ); %���������ͨ�����ظ���
Tab = zeros(max_n, 1); %ͳ�ƶ�Ӧ���ֵ�������
for i = 1 : max_n
    Tab(i) = length(CC.PixelIdxList{i});
    if mod(i, round(max_n/1e2) ) == 0
        waitbar( i/max_n, hWaitbar ); %����
    end
end
close(hWaitbar) %�رս�����
tab = tabulate( Tab(:) ); %����Ƶ��ͳ��
tab = tab( tab(:, 2) > 0, 1:2); %�޳�0ֵ
Cont = tab(:, 1) .* tab(:, 2);
af = sqrt( sum( Cont.^2 ) ) / sum( Cont );
save( [File_save, '\Tab_����ͳ��.mat'], 'tab', '-v7.3')
figure, semilogx(tab(:,1), tab(:,2))
legend( ['���ͳ�ƽ������ͨ��ָ��=', num2str(af)] )
xlabel(  '���(����' )
ylabel( '����' )

%==================================================
[~, ~, ~] = mkdir( strcat( File_save, '\image' ) ); % ����D, z, ���
File_save = strcat( File_save, '\image' );
D = zeros(x, y, z, 'uint8');
Tab_uint8 = uint8( rand( max_n, 1) * 255 );

max_num = x*y*z;
for i = 1 : max_n %��ֵ��D����
    Line = CC.PixelIdxList{i};
    Line( Line > max_num ) = max_num;
    D(Line(:)) = Tab_uint8(i);
end

hWaitbar = waitbar(0, 'saving images.......') ; %����������================
if Permute
    D = permute( D, [1, 3, 2] ); %�������������
    [~, ~, z] = size( D );
end
for i = 1 : z
    I = squeeze( D(:, :, i) );
    imwrite(I, strcat(File_save, '\', num2str(i),'.tif'));
    if mod(i, round(z/1e2) ) == 0
        waitbar( i/z, hWaitbar ); %����
    end
end
close(hWaitbar) %�رս�����

%���������ͨ��==================================================
if if_output
    [~, ~, ~] = mkdir( strcat( File_save, '\No.1' ) ); % ����D, z, ���
    File_save = strcat( File_save, '\No.1' );
    D = zeros(x, y, z, 'uint8');
    Line = CC.PixelIdxList{  Tab == max( Tab ) };
    Line( Line > max_num ) = max_num;
    D(Line(:)) = 255;
    
    II = imread([File_read, list(1).name]);
    II( II ~= 0 ) = 1;
    contour = bwperim( II );
    
    hWaitbar = waitbar(0, 'saving No.1.......') ; %����������================
    if Permute
        D = permute( D, [1, 3, 2] ); %�������������
        [~, ~, z] = size( D );
    end
    for i = 1 : z
        I = squeeze( D(:, :, i) );
        I( contour ) = 1;
        imwrite(I, strcat(File_save, '\', num2str(i),'.tif'));
        if mod(i, round(z/1e2) ) == 0
            waitbar( i/z, hWaitbar ); %����
        end
    end
    close(hWaitbar) %�رս�����
end
end

function se = Strel3d(sesize) %�������νṹ
sw = ( sesize - 1 ) / 2;
ses2 = ceil( sesize / 2 );            % ceil sesize to handle odd diameters
[y, x, z] = meshgrid( -sw : sw, -sw : sw, -sw : sw );
m = sqrt( x.^2 + y.^2 + z.^2);
b = ( m <= m( ses2, ses2, sesize ) );
se = strel( 'arbitrary', b );
end

% ͼƬ��ʽת��=============================================
% --- Executes on button press in Save.
function Save_Callback(hObject, eventdata, handles)
pathname = uigetdir; %��ȡ�ļ���·��
pathname = [ pathname, '\' ];
set( handles.Save_File, 'string', pathname );
end



function Save_File_Callback(hObject, eventdata, handles)
end


% --- Executes during object creation, after setting all properties.
function Save_File_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in Conversion.
function Conversion_Callback(hObject, eventdata, handles)
File_read = get( handles.ShowData, 'string' );
File_save = get( handles.Save_File, 'string' ); %��ȡsave�ļ�
Change_file( File_read, File_save );
end

function  Change_file( File_read, File_save )
% ת��ͼ���ʽ
list = dir( File_read ); %��ȡȫ����ʽ�ļ�
z = length( list );

hWaitbar = waitbar(0, 'waitting the calculting .......') ; %����������
for i = 1 : z
    bytes = list(i).bytes;
    if bytes > 5
        fileName = str2num( cell2mat(regexp(list(i).name,'\d', 'match')) ); %�޳��������ַ�
        I = imread( [ File_read, list(i).name ] );
        if length( size( I ) ) == 3
            I = rgb2gray(I);
        end
        imwrite( I, strcat( File_save, num2str(fileName), '.tif' ) );
    end
    if mod( i, 10 ) == 0
        waitbar( i/z, hWaitbar ); %����
    end
end
close(hWaitbar) %�رս�����
end



% SWCC Simulation====================================================

% --- Executes on button press in OpenData.
function OpenData_Callback(hObject, eventdata, handles)
[FileName, PathName]=uigetfile( {'*.mat'}, 'choose a File');
file = [ PathName, FileName ];
set(handles.ShowOpenData, 'string' , file);
end



function ShowOpenData_Callback(hObject, eventdata, handles)
end


% --- Executes during object creation, after setting all properties.
function ShowOpenData_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function R_Callback(hObject, eventdata, handles)
input = get(hObject, 'String' );
if (isempty( input))
    set(hObject, 'String', '1:10'); %������뾶
end
end


% --- Executes during object creation, after setting all properties.
function R_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function Memory_Callback(hObject, eventdata, handles)
input = get(hObject, 'String' );
if (isempty( input))
    set(hObject, 'String', '2'); %�ڴ�ϵ��
end
end


% --- Executes during object creation, after setting all properties.
function Memory_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in GenMat.
function GenMat_Callback(hObject, eventdata, handles) %����.mat����
File_read = get( handles.ShowData, 'string' );
File_save = get( handles.Save_File, 'string' ); %��ȡsave�ļ�
n = double( str2num( get( handles.Part_material, 'String' ) ) ); %��Ҫ��ǵĲ���
num = double( str2num( get( handles.Memory, 'String' ) ) ); %�ڴ�ϵ��
ReadV( File_read, File_save, n, num );
end


% --- Executes on button press in SWCCSim.
function SWCCSim_Callback(hObject, eventdata, handles)
File_read = get( handles.ShowOpenData, 'string' );
File_save = get( handles.Save_File, 'string' ); %��ȡsave�ļ�
n = double( str2num( get( handles.Part_material, 'String' ) ) ); %��Ҫ��ǵĲ���
R = get( handles.R, 'string' );
R = eval( R );
num = double( str2num( get( handles.Memory, 'String' ) ) ); %�ڴ�ϵ��
Plan = get( handles.list_Simulate, 'String' ); % �ƻ�����
Plan = Plan{ get( handles.list_Simulate, 'Value' ) };
SWCCSimulate( File_read, File_save, R, n, num, Plan );
end


% --- Executes on button press in SWCCHysteresis.
function SWCCHysteresis_Callback(hObject, eventdata, handles)
File_read = get( handles.ShowData, 'string' );
WAK = get( handles.R, 'string' );
WAK = eval( WAK ); %����ˮ-����-�Ǽ�-�ͺ�part��������ֵ
dw = SWCCHysteresis( File_read, WAK );
set( handles.HySr, 'string', num2str( dw ) );
end



% --- Executes on button press in SWCC_Force.
function SWCC_Force_Callback(hObject, eventdata, handles)
File_read = get( handles.ShowData, 'string' );
WAK = get( handles.R, 'string' );
WAK = eval( WAK ); %����ˮ-����-�Ǽ�-�ͺ�part��������ֵ
SWCCForce( File_read, WAK );
end



function HySr_Callback(hObject, eventdata, handles)

end


% --- Executes during object creation, after setting all properties.
function HySr_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on selection change in list_Simulate.
function list_Simulate_Callback(hObject, eventdata, handles)

end


% --- Executes during object creation, after setting all properties.
function list_Simulate_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
