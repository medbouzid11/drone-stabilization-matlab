% Lance ce fichier — madgwick_update.m doit être dans le même dossier
url  = 'http://192.168.1.118:8080/get?accX&accY&accZ&gyrX&gyrY&gyrZ';
opts = weboptions('Timeout',5,'ContentType','json');
beta = 0.04;  dt = 0.02;  DEAD = 0.8;  N_calib = 40;
q = [1 0 0 0];
roll_offset = 0;  pitch_offset = 0;

figure; axis equal; axis([-1 1 -1 1]);
set(gca,'Color','black'); hold on;
sky    = rectangle('Position',[-2 0 4 2],'FaceColor',[.4 .7 1],'EdgeColor','none');
ground = rectangle('Position',[-2 -2 4 2],'FaceColor',[.5 .3 .1],'EdgeColor','none');
horizon = line([-2 2],[0 0],'Color','white','LineWidth',3);
txt = text(-0.9,0.85,'Calibration...','Color','yellow','FontSize',12);
hold off;

disp('>>> Téléphone PLAT et immobile...');
rs = 0; ps = 0;
for k = 1:N_calib
    try
        d=webread(url,opts);
        ax=d.buffer.accX.buffer(end); ay=d.buffer.accY.buffer(end); az=d.buffer.accZ.buffer(end);
        rs=rs+atan2(ay,az)*180/pi;
        ps=ps+atan2(-ax,sqrt(ay^2+az^2))*180/pi;
    catch; end
    pause(0.04);
end
roll_offset=rs/N_calib; pitch_offset=ps/N_calib;
disp('>>> Calibration OK — Madgwick actif');

while true
    t0=tic;
    try
        d=webread(url,opts);
        ax=d.buffer.accX.buffer(end); ay=d.buffer.accY.buffer(end); az=d.buffer.accZ.buffer(end);
        gx=d.buffer.gyrX.buffer(end); gy=d.buffer.gyrY.buffer(end); gz=d.buffer.gyrZ.buffer(end);

        q=madgwick_update(q,gx,gy,gz,ax,ay,az,beta,dt);

        roll  = atan2(2*(q(1)*q(2)+q(3)*q(4)),1-2*(q(2)^2+q(3)^2))*180/pi;
        pitch = asin(max(-1,min(1, 2*(q(1)*q(3)-q(4)*q(2)))))*180/pi;

        rd=roll-roll_offset;   if abs(rd) <0.8, rd=0; end
        pd=pitch-pitch_offset; if abs(pd)<0.8, pd=0; end

        x=[-2 2]; y=tand(rd)*x+pd/30;
        set(horizon,'XData',x,'YData',y);
        set(sky,   'Position',[-2  pd/30   4 2]);
        set(ground,'Position',[-2 -2+pd/30 4 2]);
        set(txt,'String',sprintf('Roll: %.1f°  Pitch: %.1f°',rd,pd),'Color','white');
        drawnow limitrate;
    catch e
        disp(e.message);
    end
    elapsed=toc(t0); if elapsed<dt, pause(dt-elapsed); end
end
