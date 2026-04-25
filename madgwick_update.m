function q = madgwick_update(q, gx, gy, gz, ax, ay, az, beta, dt)
n = sqrt(ax^2+ay^2+az^2);
if n == 0, return; end
ax=ax/n; ay=ay/n; az=az/n;

q1=q(1); q2=q(2); q3=q(3); q4=q(4);

f1 = 2*(q2*q4 - q1*q3) - ax;
f2 = 2*(q1*q2 + q3*q4) - ay;
f3 = 2*(0.5 - q2^2 - q3^2) - az;

J = [-2*q3,  2*q4, -2*q1,  2*q2;
    2*q2,  2*q1,  2*q4,  2*q3;
    0,    -4*q2, -4*q3,  0   ];

step = J' * [f1; f2; f3];
ns = sqrt(sum(step.^2));
if ns > 0, step = step / ns; end

qdot = 0.5 * [ -q2*gx - q3*gy - q4*gz;
    q1*gx + q3*gz - q4*gy;
    q1*gy - q2*gz + q4*gx;
    q1*gz + q2*gy - q3*gx ];

q = q + (qdot - beta*step)' * dt;
q = q / sqrt(sum(q.^2));
end