%% Simple script that opens a nifti & views a slice
masimatlab_path = '/nfs/share5/clineci/software/masimatlab-utils/'; % replace this with your path
img_path = '/nfs/masi/clineci/CQS_TBI/DICOMS/SESSION20070506CQS_TBI10671/SCANS/2/nifti/DICOM_NEURO_T-GRAM_Head_20070623170028_2_Tilt_1.nii.gz';
csv_path = '/nfs/masi/clineci/CQS_TBI/dataList/preprocessList.csv';

% path where the montage is saved
out_folder = 'montage';
%montage_name_beg = 'test_montage';

image_path_list = readtable(csv_path, 'HeaderLines', 1);
num_rows = height(image_path_list);
score_list = image_path_list.(2);
image_path_list = image_path_list.(1);

contrast = [1005, 1115];
i = 1;
prev_i = 0;

addpath(masimatlab_path);

while score_list(i) == 9
    i = i + 1;
end

while i <= num_rows
    if prev_i ~= i
        path_cell = image_path_list(i);
        nifti_path = path_cell{1};
        res = makeMontage(nifti_path, out_folder, i, contrast);
    end
    
    prev_i = i;
    i = getKeyboardInput(i, res, score_list, num_rows);
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

 function res = makeMontage(nifti_path, ...
     out_folder, i, contrast)
    nifti_path = strrep(nifti_path, 'preprocessed', 'nifti');
            
    nifti_header = niftiinfo(nifti_path);
    nifti_img = niftiread(nifti_header);
    nifti_img = imrotate3(nifti_img, 270, [0, 0, 1]);
    % may or may not be necessary to flip the image
    nifti_img = imrotate3(nifti_img, 180, [0, 1, 0]);
    
    montage_name = ['test_montage_' num2str(i) '.png'];
    image_out = fullfile(out_folder, montage_name);
    
    montage_handle = montage(nifti_img, 'DisplayRange', contrast);
    set(gcf, 'NumberTItle', 'off', 'Name', montage_name);
    movegui(gcf, 'center');
    res = {montage_handle, image_out};
 end
 
 function index = getKeyboardInput(i, res, score_list, num_rows)
    montage_handle = res(1);
    montage_handle = montage_handle{1};
    image_out = res(2);
    image_out = image_out{1};
    
    index = i;
    while true
        c = waitforbuttonpress;
        if c == 1 % keyboard pressed
        key = get(gcf, 'currentCharacter');
            switch key
                case 97 %'a' -> last image
                    saveImageButtonPushed(image_out);
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
                    saveImageButtonPushed(image_out);
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
            end
        end
    end
 end

