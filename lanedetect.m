%% image read and grayscale, crop (이미지 불러오기, 흑백화, 자르기)
clear; clf; close all;
img_ori = imread('out.jpg');

img_gray = rgb2gray(img_ori);
img_gray = double(img_gray);
img_gray = imresize(img_gray,0.3);
col = length(img_gray(:,1));
row = length(img_gray(1,:));

img_gray = img_gray(col/2:col, 1:row); 
figure();
imshow(uint8(img_gray));
%% gaussian filter
g1 = fspecial('gaussian',[5,5],5);
g2 = fspecial('gaussian',[5,5],10);
g3 = fspecial('gaussian',[21,21],10);

img1 = filter2(g3,img_gray);
img2 = filter2(g2,img_gray);
img3 = filter2(g3,img_gray);

figure();
subplot(2,2,1);
imshow(img_gray/256)
title('Original Image', 'FontSize', 10);
subplot(2,2,2); 
imshow(img1/256)
title('Gaussian filtered image, size = 5x5, \sigma = 5', 'FontSize', 10);
subplot(2,2,3);
imshow(img2/256)
title('Gaussian filtered image, size = 5x5, \sigma = 10', 'FontSize', 10);

subplot(2,2,4);
imshow(img3/256)
title('Gaussian filtered image, size = 11x11, \sigma = 5', 'FontSize',10);
%% Calculating gradient with sobel mask
sobelMaskX = [-1,0,1;-2,0,2;-1,0,1];
sobelMaskY = [1,2,1;0,0,0;-1,-2,-1];
%Convolution by image by horizontal and vertical filter
G_X = conv2(img1,sobelMaskX,'same');
G_Y = conv2(img1,sobelMaskY,'same');
%Calcultae magnitude of edge
magnitude = (G_X.^2) + (G_Y.^2);
magnitude = sqrt(magnitude);
%Calculate directions/orientations
theta = atan2 (G_Y,G_X);
theta = theta*180/pi;
%Adjustment for negative directions, making all directions positive
col = length(img_gray(:,1)); 
row = length(img_gray(1,:));
for i = 1:col
    for j = 1:row
        if (theta(i,j)<0)
            theta(i,j) = 360*theta(i,j);
        end
    end
end
%% quantization theta
qtheta = zeros(col,row);
%Adjusting directions to nearest 0, 45, 90, or 135 degree
for i = 1 : col
    for j = 1 : row
        if((theta(i,j) >= 0) && theta(i,j) < 22.5) || (theta(i,j) >= 157.5) && (theta(i,j) <202.5) || (theta(i,j) >= 337.5) && (theta(i,j) <= 360)
            qtheta(i,j) = 0; %degree 0
        elseif ((theta(i,j) >= 22.5) && (theta(i,j) < 67.5) || (theta(i,j) >= 202.5) && (theta(i,j) < 247.5))
            qtheta(i,j) = 1; %degree 1
        elseif ((theta(i,j) >= 67.5 && theta(i,j) < 112.5) || (theta(i,j) >= 247.5 && theta(i,j) < 292.5))
            qtheta(i,j) = 2; %degree 2
        elseif ((theta(i,j) >= 112.5 && theta(i,j) < 157.5) || (theta(i,j) >= 292.5 && theta(i,j) < 337.5))
            qtheta(i,j) = 3; %degree 3
        end
    end
end 
%% Non-Maximum Supression
BW = zeros(col,row);
for i = 2:col-1
  for j = 2:row-2
      if (qtheta(i,j)==0)
          BW(i,j) = (magnitude(i,j) == max([magnitude(i,j),magnitude(i,j+1),magnitude(i,j-1)]));
      elseif(qtheta(i,j) == 1)
          BW(i,j) = (magnitude(i,j) == max([magnitude(i,j),magnitude(i+1,j+1),magnitude(i-1,j-1)]));
      elseif(qtheta(i,j) == 2)
          BW(i,j) = (magnitude(i,j) == max([magnitude(i,j),magnitude(i+1,j),magnitude(i-1,j)]));
      elseif(qtheta(i,j) == 3)
          BW(i,j) = (magnitude(i,j) == max([magnitude(i,j),magnitude(i+1,j+1),magnitude(i-1,j-1)]));
      end
  end
end
BW = BW.*magnitude;
figure,imshow(BW);
%% Hysteresis Thresholding

T_min = 0.1;
T_max = 0.15;

%Hysteresis Thresholding
T_min = T_min * max(max(BW)); %이미지 안의 최대,최솟값을 구하여 min과 max 재설정
T_max = T_max * max(max(BW));

edge_final = zeros(col,row);

for i = 1 : col
    for j = 1 : row
        %no edge
        if (BW(i,j) < T_min)
            edge_final(i,j) = 0;
            %strong edge
        elseif ( BW(i,j) > T_max)
            edge_final(i,j) = 1;
            %weak edge - Using 8-conneccted components
        elseif ( BW(i+1,j)>T_max || BW(i-1,j)>T_max || BW(i,j+1)>T_max || BW(i,j-1)>T_max || BW(i-1,j-1)>T_max || BW(i-1,j+1)>T_max || BW(i+1,j+1)>T_max || BW(i+1,j-1)>T_max)
            edge_final(i,j) = 1;
        end
    end
end
img_canny = uint8(edge_final.*255);
%show final edge detection result
figure,imshow(img_canny);
% BW1 = edge(image,'Canny') -> gray image만 가능

%집 주변의 도로사진 두개를 찍어서 edge를 detect 하기
%필터 사이즈 ,sigma값 변화에 따라 output이 어떻게 변하는지?

%% hough transform
[H,T,R] = hough(img_canny);
P = houghpeaks(H,15,'threshold',ceil(0.15*max(H(:))));
lines = houghlines(img_canny,T,R,P,'FillGap',30,'MinLength',5);


%% lane selection
c1 = [];
c2 = [];
l = [];
for k = 1:length(lines)
    if (lines(k).theta < 75 && lines(k).theta > -75)
        c1 = [c1; [lines(k).point1 3]]; %start point
        c2 = [c2; [lines(k).point2 3]]; %desert point
        l = [l;lines(k).point1 lines(k).point2];
    end
end

%% display lane

img_gray = img_gray ./ 255;
img_gray = insertShape(img_gray, 'line',l,'color','green','LineWidth',5);
img_gray = insertShape(img_gray, 'Circle', c1, 'Color','red');
img_gray = insertShape(img_gray, 'Circle', c2, 'Color','yellow');
figure, imshow(img_gray);