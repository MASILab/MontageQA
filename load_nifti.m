%% MASILab - HEAD CCT Montage QA Tool
masimatlab_path = '/nfs/share5/clineci/software/masimatlab-utils/'; % replace this with your path
csv_path = '/nfs/masi/clineci/CQS_TBI/dataList/preprocessList.csv'; % replace this with your csv file path

addpath(masimatlab_path);

% path where the montage is saved
out_folder = 'montage';
label_folder = 'labels';

image_path_table = readtable(csv_path, 'HeaderLines', 1);
num_rows = height(image_path_table);
score_list = image_path_table.(2);
image_path_table = cell2table(image_path_table.(1));
image_path_list = table2array(image_path_table);

label_file = ['labels_', datestr(now), '.csv'];
label_file = fullfile(label_folder, label_file);

prompt = 'Continue from last sessoin? (y/n) Enter q to quit.\n';
arg1 = input(prompt, 's');
while arg1 ~= 'y' && arg1 ~= 'n' && arg1 ~= 'q'
    fprintf('Enter y or n. Enter q to quit.\n');
    arg1 = input(prompt, 's');
end

if arg1 == 'y'
    fid = fopen('i.info', 'r');
    label_table_path = fgetl(fid);
    labels = readLabelTable(label_table_path);
    i = str2double(fgetl(fid));
    fclose(fid);
elseif arg1 == 'n'
    labels = zeros(num_rows, 3) - 1;
    i = 1;
elseif arg1 == 'q'
    return;
end

prev_i = 0;
contrast = [1005, 1115];

while score_list(i) == 9
    i = i + 1;
end

while i <= num_rows
    if prev_i ~= i
        nifti_path = cell2mat(image_path_list(i));
        res = makeMontage(nifti_path, out_folder, i, contrast, labels);
    end
    
    prev_i = i;
    i = getKeyboardInput(i, res, score_list, num_rows, labels, label_file);
end

function labels = readLabelTable(label_table_path)
    label_table = readtable(label_table_path, 'HeaderLines', 1);
    label_table = label_table(:,2:width(label_table));
    labels = table2array(label_table);
end

function saveImageButtonPushed(image_out)
    current_frame = getframe(gca);
    montage_uint16 = im2uint16(current_frame.cdata);
    imwrite(montage_uint16, image_out);
end

function contrastButtonPushed(montage_handle, ~)
    contrast_handle = imcontrast(montage_handle);
    set(contrast_handle, 'CloseRequestFcn', ...
        @(s, e)getMinMax(s)); 
end

function getMinMax(handle)
    window_min = str2double(get(findobj(handle, 'tag', ...
         'window min edit'), 'String'));
    window_max = str2double(get(findobj(handle, 'tag', ...
         'window max edit'), 'String'));
    assignin('base', 'contrast', [window_min, window_max]);
    delete(handle);
end
 
% label format: [T G B]
function current_label = labelButtonPushed(col, current_label)
    if current_label(col) == 0
        current_label(col) = 1;
    else
        current_label(col) = 0;
    end
    fprintf('[T: %d G: %d B: %d]\n', current_label(1), ...
        current_label(2), current_label(3));
end

function writeButtonPushed(i, current_label, label_file)
    labels = evalin('base', 'labels');
    image_path_list = evalin('base', 'image_path_list');
    labels(i, :) = current_label;
        
    tmp = table(image_path_list, labels(:,1), labels(:,2), labels(:,3), ...
        'VariableNames', {'image path', 'taken out', 'grainy', 'broken',});
    writetable(tmp, label_file);
    % save i for the next session
    fid = fopen('i.info', 'w+');
    fprintf(fid, '%s\n', label_file);
    fprintf(fid, '%d\n', i);
    fclose(fid);
    
    fprintf('wrote: [T: %d G: %d B: %d]\n', current_label(1), ...
        current_label(2), current_label(3));
    assignin('base', 'labels', labels);
end
 
function res = makeMontage(nifti_path, ...
    out_folder, i, contrast, labels)
    nifti_path = strrep(nifti_path, 'preprocessed', 'nifti');
            
    %nifti_header = niftiinfo(nifti_path);
    nifti_img = niftiread(nifti_path);
    nifti_img = imrotate3(nifti_img, 270, [0, 0, 1]);
    
    montage_name = ['test_montage_' num2str(i) '.png'];
    image_out = fullfile(out_folder, montage_name);
    
    montage_handle = montage(nifti_img, 'DisplayRange', contrast);
    set(gcf, 'NumberTItle', 'off', 'Name', montage_name);
    movegui(gcf, 'center');
    
    if labels(i,1) == -1
        labels(i, :) = [0 0 0];
        assignin('base', 'labels', labels);
    end
    
    res = {montage_handle, image_out};
end
 
function index = getKeyboardInput(i, res, score_list, ...
    num_rows, labels, label_file)
    montage_handle = res(1);
    montage_handle = montage_handle{1};
    image_out = res(2);
    image_out = image_out{1};
    
    current_label = labels(i, :);
    
    index = i;
    while true
        c = waitforbuttonpress;
        if c == 1 % keyboard pressed
        key = get(gcf, 'currentCharacter');
            switch key
                case 97 %'a' -> previous image
                    writeButtonPushed(i, current_label, label_file);
                    index = index - 1;
                    % keep skipping bad images
                    while index >= 1 && score_list(index) == 9
                        index = index - 1;
                    end
                    if index < 1
                        index = i;
                    end
                    break
                case 99 %'c'
                    contrastButtonPushed(montage_handle, image_out);
                case 100 %'d' -> next image
                    writeButtonPushed(i, current_label, label_file);
                    index = index + 1;
                    % keep skipping bad images
                    while index <= num_rows && score_list(index) == 9
                        index = index + 1;
                    end
                    if index > num_rows
                        index = i;
                    end
                    break
                case 115 %'s' -> save image
                    saveImageButtonPushed(image_out);
                case 116 %'t' -> label: skull taken out
                    current_label = labelButtonPushed(1, current_label);
                case 103 %'g' -> label: grainy (low dose)
                    current_label = labelButtonPushed(2, current_label);
                case 98  %'b' -> label: skull broken
                    current_label = labelButtonPushed(3, current_label);
                case 119 %'w' -> write label
                    writeButtonPushed(i, current_label, label_file);
            end
        end
    end
end
