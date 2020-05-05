img_ori = imread('lanedetect.bmp');
img_gray = rgb2gray(img_ori);
[x,map] = imread('son1.gif');
img_gray = ind2gray(x,map);
%img_gray = img_gray(length(img_gray(:,1))/2:end,1:end);
img_edge = edge(img_gray,'canny',[0.03 0.2], 0.1);
figure(); imshow(img_edge);