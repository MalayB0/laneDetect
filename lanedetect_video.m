% Input video file which needs to be stabilized.
clear;
filename = 'challenge.mp4';
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
    % put your code here
    
    BW1 = Canny_acl(img_gray, 3, 10, 0.2, 0.05);
    
    [H,T,R] = hough(BW1);
    P  = houghpeaks(H, 35,'threshold',ceil(0.1*max(H(:))));
    [lines] = houghlines(BW1,T,R,P,'FillGap',10,'MinLength', 8);
    max_len = 0;
    
    c1 = [];
    c2 = [];
    l = [];
    for k = 1:length(lines)
        if(lines(k).theta < 75 && lines(k).theta > -75)
            c1 = [c1; [lines(k).point1 2]];
            c2 = [c2; [lines(k).point2 2]];
            l = [l;lines(k).point1 lines(k).point2];
        end
    end
    img_ori = insertShape(img_ori, 'Line', l);
    img_ori = insertShape(img_ori, 'Circle', c1);
    img_ori = insertShape(img_ori, 'Circle', c2);

    step(VideoOut2, BW1);
    step(VideoOut, img_ori);
end


release(videoSource);
release(videoOut);