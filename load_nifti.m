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

%my_nifti = load_untouch_nii_gz(img_path); % load the nifti
% the "untouch" in the function name here mean
header = niftiinfo(img_path);
my_nifti = niftiread(header);
my_nifti = imrotate3(my_nifti, 90, [0, 0, 1]);
% may or may not be necessary to flip the image
my_nifti = imrotate3(my_nifti, 180, [0, 1, 0]);

fprintf('Nifti dimensions: %d x %d x %d\n', header.PixelDimensions); % look at the volume dimensions (my_nifti.hdr is the header)

% figure(1); imagesc(my_nifti(:,:,15)); colormap(gray); % Display an axial slice of the CT

% make a montage using matlab's montage function
m_handle = montage(my_nifti, 'DisplayRange',[920, 1110]);
% save the montage to disk
current_frame = getframe(gca);
montage_uint16 = im2uint16(current_frame.cdata);
imwrite(montage_uint16, image_out);