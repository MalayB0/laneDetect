% Input video file which needs to be stabilized.
clear;
filename = 'solidYellowLeft.mp4';
%filename = 'solidWhiteRight.mp4';
%filename = 'challenge.mp4';
VideoSource = vision.VideoFileReader(filename, 'VideoOutputDataType', 'double');
VideoOut = vision.VideoPlayer('Name', 'Output');

VideoOut2 = vision.VideoPlayer('Name', 'Canny');

while ~isDone(VideoSource)
    
    img = step(VideoSource);
    img_ori = imresize(img, 0.5);
    col = length(img_ori(:,1));
    row = length(img_ori(1,:));
    img_ori = imcrop(img_ori,[1 col/2 row col/2]);
    img_gray = rgb2gray(img_ori); 
    img_gray = double(img_gray);
    
    
    %imshow(BW);
    %%
    
    
    img_gray = imadjust(img_gray);
    %img_gray = histeq(img_gray);
    %T = adaptthresh(img_gray,0.2);
    %img_gray = imbinarize(img_gray,T);
    
    img_output = myCanny_acl(img_gray,5,10,0.1,0.03);
    
    % hough transform
    [H, T, R] = hough(img_output); %t = theta, r = row(수선의 발) ,H = 직선 위에 존재하는 점의 갯수
    
    P = houghpeaks(H, 35,'threshold', ceil(0.1*max(H(:))));
    [lines] = houghlines(img_output, T, R, P, 'FillGap',10,'MinLength',5);
    % lane selection
    c1 = [];
    c2 = [];
    l = [];
    for k = 1:length(lines)
        if(lines(k).theta < 65 && lines(k).theta > -65)
            c1 = [c1; [lines(k).point1 3]];
            c2 = [c2; [lines(k).point2 3]];
            l = [l; lines(k).point1 lines(k).point2];
        end
    end
    % display lane
    img_ori = insertShape(img_ori, 'Line',l,'Color','green','LineWidth',3);
    img_ori = insertShape(img_ori, 'Circle',c1,'Color','red');
    img_ori = insertShape(img_ori, 'Circle',c2,'Color','yellow');
    
    step(VideoOut2, img_output);
    step(VideoOut, img_ori);
end
release(VideoOut);