#!/bin/sh

for model in sedan_4m.tar aircraft_wing_14.tar f1_racecar_140m.tar; do
	wget 'http://ninalogs.blob.core.windows.net/application/${model}?sv=2017-04-17&ss=bfqt&srt=sco&sp=rw&se=2027-09-27T10:07:48Z&st=2017-09-27T02:07:48Z&spr=https&sig=IXNV8%2B2mGTuWoRvn5ZcHpdzY9MtEeqN8ootSz%2BLez2w%3D' -O - | tar x
done

