%% Simple script that opens a nifti & views a slice
masimatlab_path = '/nfs/share5/clineci/software/masimatlab-utils/'; % replace this with your path
img_path = '/nfs/masi/clineci/CQS_TBI/DICOMS/SESSION20070506CQS_TBI10671/SCANS/2/nifti/DICOM_NEURO_T-GRAM_Head_20070623170028_2_Tilt_1.nii.gz'; 
% pretty much all of our nifti images are compressed to save space, which
% is why the .nii suffix is followed by .gz in the img name

% path where the montage is saved
out_folder = pwd;
montage_name = 'test_montage.png';
image_out = fullfile(out_folder, montage_name);

addpath(masimatlab_path); 

help load_untouch_nii_gz % prints out information about the function

my_nifti = load_untouch_nii_gz(img_path); % load the nifti
% the "untouch" in the function name here means 

fprintf('Nifti dimensions: %d x %d x %d\n', my_nifti.hdr.dime.dim(2:4)); % look at the volume dimensions (my_nifti.hdr is the header)

my_img_data = my_nifti.img; % gets the raw image data

%figure(1); imagesc(my_img_data(:,:,15)); colormap(gray); % Display an axial slice of the CT

% make a montage using matlab's montage function
m_handle = montage(my_img_data, 'DisplayRange',[]);
% save the montage to disk
current_frame = getframe(gca);
montage_uint16 = im2uint16(current_frame.cdata);
imwrite(montage_uint16, image_out);