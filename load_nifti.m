%% Simple script that opens a nifti & views a slice
masimatlab_path = '/nfs/share5/clineci/software/masimatlab-utils/'; % replace this with your path
img_path = '/nfs/masi/clineci/CQS_TBI/DICOMS/SESSION20070506CQS_TBI10671/SCANS/2/nifti/DICOM_NEURO_T-GRAM_Head_20070623170028_2_Tilt_1.nii.gz';
csv_path = '/nfs/masi/clineci/CQS_TBI/dataList/preprocessList.csv';

% path where the montage is saved
out_folder = pwd;
montage_name_beg = 'test_montage';

image_path_list = readtable(csv_path, 'HeaderLine', 1);
num_rows = height(image_path_list);
score_list = image_path_list.(2);
image_path_list = image_path_list.(1);

contrast = [0, 40];

addpath(masimatlab_path);

for i = 1:num_rows
    path_cell = image_path_list(i);
    nifti_path = path_cell{1};
    nifti_header = niftiinfo(nifti_path);
    nifti_img = niftiread(nifti_header);
    nifti_img = imrotate3(nifti_img, 270, [0, 0, 1]);
    % may or may not be necessary to flip the image
    nifti_img = imrotate3(nifti_img, 180, [0, 1, 0]);
    
    montage_name = [montage_name_beg '_' num2str(i) '.png'];
    image_out = fullfile(out_folder, montage_name);
    
    montage_handle = montage(nifti_img, 'DisplayRange', contrast);
    
    while true
        c = waitforbuttonpress;
        if c == 1
            key = get(gcf, 'currentCharacter');
            switch key
                case 99 %'c'
                    contrastButtonPushed(montage_handle, image_out);
                case 100 %'d' -> next image
                    saveImageButtonPushed(image_out);
                    break
                case 115 %'s' -> save image
                    saveImageButtonPushed(image_out);
            end
        end
    end
    %set(gcf, 'KeyPressFcn', ...
        %@(s, e) contrastButtonPushed(montage_handle, image_out, e));
    %figure(1); montage_img = (get(montage_handle, 'CData'));
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

%header = niftiinfo(img_path);
%my_nifti = niftiread(header);

%fprintf('Nifti dimensions: %d x %d x %d\n', header.PixelDimensions); % look at the volume dimensions (my_nifti.hdr is the header)


