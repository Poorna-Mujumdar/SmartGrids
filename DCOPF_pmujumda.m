clc; 
clear all;

addpath('C:\matpower');

addpath('C:\matpower/t');

addpath('C:\matpower/most');

addpath('C:\matpower/most/t');

addpath('C:\matpower/extras');

addpath('C:\matpower/extras/misc');

addpath('C:\matpower/extras/sdp_pf');


%to define constants
mpc = caseBus;

rundcopf(mpc)

branch_x = mpc.branch(:,4);  

branch = mpc.branch(:,1:2);  

bus_n = length(mpc.bus(:,1)); 

slackbus = find(mpc.bus(:,2)==3);

gencost = mpc.gencost(:,5);

gen_n=length(mpc.gen(:,1));

o_costf = max(mpc.gencost(:,4));


% to create y (admittance matrix)
Y = full(makeYbus(mpc));

y = zeros(bus_n);

y_indx = branch(:,1) + ((branch(:,2)-1)*size(y,1));


y(y_indx) = 1./branch_x;

y = y + y';

B = -y;

D = diag(sum(y));

B_x = B + D;
B_x = B_x * mpc.baseMVA;
 

% quadprogramming


fN = [mpc.gencost(:,6); 
zeros(bus_n,1)];


Hessian_matrix = diag([2*gencost]);

Hessian_matrix = [Hessian_matrix zeros(gen_n,bus_n)];

Hessian_matrix = [Hessian_matrix ;zeros(bus_n,gen_n+bus_n)];


gen_arr = eye(gen_n);

gen_arr(gen_n+1:bus_n,1:gen_n) = zeros(gen_n,bus_n-gen_n);


% to get get Aeq and Beq matrices
Aeq1 = [gen_arr, B_x]; 

Aeq2 = zeros(1,gen_n+bus_n);
Aeq2(gen_n+slackbus) = 1; 

AeqN = [Aeq1; Aeq2];
BeqN = [mpc.bus(:,3); 0]; 


% to get AN and BN matrices
linec_indx = find(mpc.branch(:,6)~=0);

linec_data = [mpc.branch(linec_indx,1), mpc.branch(linec_indx,2), mpc.branch(linec_indx,6)]';

AN = zeros(1,gen_n+bus_n);

flowc_indx_temp = linec_data(1,:) + (((linec_data(2,:))-1)*size(B_x));

flowc_indx = flowc_indx_temp(1);

AN([gen_n+linec_data(1,:), gen_n+linec_data(2,:)]) = [B_x(flowc_indx), -B_x(flowc_indx)];

BN = linec_data(end,:)';


% upper and lower bounds

lower_boundN = [mpc.gen(:,10); -1*ones(bus_n,1)];

upper_boundN = [mpc.gen(:,9); ones(bus_n,1)];
 

[x,fval,exitflag,output,lambda] = quadprog(Hessian_matrix,fN,AN,BN,AeqN,BeqN,lower_boundN,upper_boundN)

