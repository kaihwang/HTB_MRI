

# for 32 trials
# 220TRs

for i in $(seq 1 1 72); do

	optseq2 --ntp 220 --tr 1 --psdwin 0 18 1 --ev evt1 2 32 --nkeep 1 --nsearch 10000 --o search --tnullmin 2 --tnullmax 10
	cat search-001.par | grep NULL | awk '{print $3}' > ITIs/ITI${i}.txt

done



for i in $(seq 1 1 72); do

	optseq2 --ntp 330 --tr 1 --psdwin 0 18 1 --ev evt1 2 48 --nkeep 1 --nsearch 10000 --o search --tnullmin 2 --tnullmax 10
	cat search-001.par | grep NULL | awk '{print $3}' > 48ITIs/ITI${i}.txt

done