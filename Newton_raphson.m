%% Initialisation
tic
mpc = case14;

nbus = length(mpc.bus(:,1));

mpc.bus(mpc.bus(:,2) == 1,8) = 1;
mpc.bus(mpc.bus(:,2) == 1 | 2,9) = 0; 

Pg = zeros(nbus, 1);
Qg = zeros(nbus, 1);
Pd = zeros(nbus, 1);
Qd = zeros(nbus, 1);

Pg(mpc.gen(:,1)) = mpc.gen(:, 2);
Qg(mpc.gen(:,1)) = mpc.gen(:, 3);
Pd(mpc.bus(:,1)) = mpc.bus(:, 3);
Qd(mpc.bus(:,1)) = mpc.bus(:, 4);

pv = mpc.bus(mpc.bus(:,2)==2,1);
pq = mpc.bus(mpc.bus(:,2)==1,1);

n_pv = length(pv);
n_pq = length(pq);

Yb = makeYbus(mpc);

mpc.Pbus = (Pg - Pd)/mpc.baseMVA;
mpc.Qbus = (Qg - Qd)/mpc.baseMVA;

tolerance = 99999;
iteration = 0;

while tolerance > 10^(-3)
    Pcalc = zeros(nbus, 1);
    Qcalc = zeros(nbus, 1);
    sum = zeros(1, 1);
    for i = 1:nbus
        for j = 1:nbus
            sum(j) = mpc.bus(i,8) * mpc.bus(j,8) * abs(Yb(i,j)) * cos(angle(Yb(i,j)) - ((mpc.bus(i,9) - mpc.bus(j,9))*(pi/180)));
            Pcalc(i) = Pcalc(i) +  sum(j);
            Qcalc(i) = Qcalc(i) - (mpc.bus(i,8). * mpc.bus(j,8) * abs(Yb(i,j)) * sin(angle(Yb(i,j)) - ((mpc.bus(i,9) - mpc.bus(j,9))*(pi/180))));
        end
    end
    
     delta_P = Pcalc - mpc.Pbus;
     delta_Q = Qcalc - mpc.Qbus; 
     
     k = [delta_P(pv); delta_P(pq); delta_Q(pq)];
     
     J = makeJac(mpc);
     
     N = inv(J)*k;
     
     tolerance = max(abs(k));
     
     mpc.bus(pv, 9) = mpc.bus(pv, 9) - (N(1:n_pv)*(180/pi)); 
     mpc.bus(pq, 9) = mpc.bus(pq, 9) - (N(n_pv + 1:n_pv+n_pq)*(180/pi));
     mpc.bus(pq, 8) = mpc.bus(pq, 8) - N(n_pv + n_pq + 1:end);
     V = mpc.bus(:,8);
     d = mpc.bus(:,9);
     
     iteration = iteration + 1
     
end
toc
V
d
            