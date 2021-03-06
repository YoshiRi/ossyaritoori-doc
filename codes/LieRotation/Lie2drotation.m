
clear 

%% SO2
theta = 0.5;
G=[0 -1;1 0];
R =expm(theta*G)
det(R)

%% get random x pose
datanum = 5;
%data
x=10*rand(2,datanum);
%noise
w=0.01*randn(2,datanum);

% obserbation
y=R*x+w

%% 0. Kanata's method

%% 1.Linear Estimaion

Coef = [x' zeros(size(x'));zeros(size(x')) x'];
Ys = [y(1,:) y(2,:)]';

Rcoef=Coef\Ys;

Rhat = reshape(Rcoef,2,2)'

theta_hat = atan(Rhat(2)/Rhat(1))
theta_hat2 = atan(-Rhat(3)/Rhat(1))
Rhat2 = expm(theta_hat*G)
Rhat2_ = toRotation(Rhat)

%% 2. Lie group
% init estimation
iteration = 10;
alpha = zeros(iteration,1);
% init value
alpha(1) = 0;

for i = 2:iteration
% jacobian
Rliehat = expm(alpha(i-1)*G);
J = zeros(2,1);
r = zeros(2,1);
for j = 1:datanum
J = J+G*Rliehat*x(:,j);
r = r+Rliehat*x(:,j)-y(:,j);
end
da = -(J'*J)\J'*r;
alpha(i) = alpha(i-1)+da;
end

theta_liehat = alpha(end)

figure(1)
plot(alpha)
grid on
title('Optimization for theta with Lie expression')

%% 3d version
theta_rpy = [0.1 0.2 0.3];
G1 = [0 0 0;0 0 -1;0 1 0];
G2 = [0 0 1;0 0 0; -1 0 0];
G3 = [0 -1 0;1 0 0; 0 0 0];

R3d = expm(theta_rpy(1)*G1+theta_rpy(2)*G2+theta_rpy(3)*G3)
det(R3d)
R3d*R3d'

%% obs

%data
x3d=10*rand(3,datanum);
%noise
w3d=0.01*randn(3,datanum);

% obserbation
y3d=R3d*x3d+w3d

%% 1.Linear Estimaion
z3d = zeros(size(x3d'));
Coef3d = [x3d' z3d z3d ;z3d x3d' z3d; z3d z3d x3d'];
Ys3d = [y3d(1,:) y3d(2,:) y3d(3,:)]';

Rcoef3d=Coef3d\Ys3d;

Rhat3d = reshape(Rcoef3d,3,3)'

Rhat3d_ = toRotation(Rhat3d)




%% 2. Lie group Newton

% init estimation
iteration = 10;
lambdalm=0.0001;
alpha3d = zeros(iteration,3);
% init value
alpha3d(1,:) = [0.1 0.21 0.31];

for i = 2:iteration
% jacobian
Rliehat3d = expm(alpha3d(i-1,1)*G1+alpha3d(i-1,2)*G2+alpha3d(i-1,3)*G3);
J = zeros(3,3);
r = zeros(3,1);
for j = 1:datanum
GR=[G1*Rliehat3d*x3d(:,j) G2*Rliehat3d*x3d(:,j) G3*Rliehat3d*x3d(:,j)]';
J = J +GR;
r = r+Rliehat3d*x3d(:,j)-y3d(:,j);
end
da = -(J'*J+eye(3)*lambdalm)\J'*r;
alpha3d(i,:) = alpha3d(i-1,:)+da';
end

theta_liehat3d = alpha3d(end,:)

%% 2. Lie group: Gauss-Newton(LM)

% init estimation
iteration = 10;
lambdalm=0.0;
alpha3d = zeros(iteration,3);
% init value
alpha3d(1,:) = [0.2 0.3 0.1];

lieA = @(v) v(1)*G1+v(2)*G2+v(3)*G3;
Rinit = expm(lieA(alpha3d(1,:)));

% init
Rgn = Rinit;
for i = 2:iteration

H = zeros(3,3);
g = zeros(3,1);
for j = 1:datanum
    Wa = eye(3);
    g1 = - cross(Rgn*x3d(:,j), Wa*(y3d(:,j)-Rgn*x3d(:,j)));
    g2 = - cross(Wa*(y3d(:,j)-Rgn*x3d(:,j)),Rgn*Rgn'*Wa*(y3d(:,j)-Rgn*x3d(:,j)));
    g = g + g1 + g2;
    hh = lieA(Rgn*x3d(:,j))*Wa*lieA(Rgn*x3d(:,j))';
    H = H + hh;
end
dw = -inv(H+lambdalm*eye(3))*g;
alpha3d(i,:) = alpha3d(i-1,:)+dw';
Rgn = expm(lieA(dw))*Rgn;
end

theta_liehat3d = alpha3d(end,:)


%% function

% Rを回転行列に丸める
function Rn = toRotation(R_)
    [U S V] = svd(R_);
    Sig = eye(size(R_,1));
    Sig(end) = det(U*V);
    Rn = U * Sig * V'
end
